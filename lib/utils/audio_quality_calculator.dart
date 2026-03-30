// ignore_for_file: constant_identifier_names

/// Perceptual audio quality tier calculator.
///
/// Tier order (best → worst): DSD → MQ → HR → HQ → SQ → LQ
///
/// ## Android-specific design notes
/// On Android, MediaStore / MediaMetadataRetriever supply metadata with
/// varying reliability:
///   - Codec/MIME  → reliable (from file extension or container header)
///   - Sample rate → available via MediaMetadataRetriever on API 28+
///   - Bitrate     → present in MediaStore, but for lossless it is the
///                   *compressed* output bitrate, NOT raw PCM bitrate
///   - Bit depth   → NOT in MediaStore at all; requires parsing the file's
///                   own format header (e.g. via just_audio_media_kit or a
///                   native plugin like flutter_media_metadata)
///
/// Because bit depth is the most important signal and the least reliably
/// available, this calculator uses a multi-path inference strategy that
/// avoids the #1 historical bug: applying the PCM formula to compressed
/// lossless bitrate, which would infer 8–13 bits for a real 24-bit file.
class AudioQualityCalculator {
  // ── DSD sample rates ───────────────────────────────────────────────────────
  static const int _dsd64 = 2822400;
  static const int _dsd128 = 5644800;
  static const int _dsd256 = 11289600;
  static const int _dsd512 = 22579200;

  // Uncompressed lossless — bitrate is raw PCM; formula is mathematically exact
  static const List<String> _pcmCodecs = ['wav', 'aiff', 'aif', 'pcm'];

  // Compressed lossless — bitrate is post-compression; PCM formula does NOT apply
  static const List<String> _compressedLosslessCodecs = [
    'flac',
    'alac',
    'ape',
    'wv',
    'wavpack',
    'tta',
  ];

  // Lossy — quality is purely bitrate-dependent, bit depth is irrelevant
  static const List<String> _lossyCodecs = [
    'mp3',
    'aac',
    'aac-lc',
    'he-aac',
    'ogg',
    'vorbis',
    'opus',
    'wma',
    'ac3',
    'eac3',
    'ac-3',
    'e-ac-3',
  ];

  // ── Public API ─────────────────────────────────────────────────────────────

  static String calculateQuality({
    required int? bitrate,
    required int? sampleRate,
    String? codec,
    int? bitDepth,
  }) {
    final codecLow = codec?.toLowerCase().trim();
    final isPCM = _isPCMCodec(codecLow);
    final isCompressedLossless = _isCompressedLosslessCodec(codecLow);
    final isLossless = isPCM || isCompressedLossless;
    final isLossy = _isLossyCodec(codecLow);

    // ── DSD — evaluated before everything else ───────────────────────────────
    if (_isDSD(codecLow, sampleRate ?? 0)) return 'DSD';

    // ── Normalise numeric inputs ─────────────────────────────────────────────
    final double khz = sampleRate != null ? _normalizeKhz(sampleRate) : 0;
    final int kbps = bitrate != null ? _normalizeKbps(bitrate) : 0;

    // ── Resolve bit depth ────────────────────────────────────────────────────
    // Priority:
    //   1. Explicit metadata — always trust it if present and valid
    //   2. PCM exact formula — mathematically precise for WAV/AIFF
    //   3. Compressed-lossless heuristic — sample-rate-aware threshold
    //   4. null for lossy — bit depth is irrelevant for lossy formats
    final int? depth;
    if (bitDepth != null && bitDepth > 0) {
      depth = bitDepth;
    } else if (isPCM && khz > 0 && kbps > 0) {
      depth = _inferDepthPCM(kbps, khz);
    } else if (isCompressedLossless && khz > 0) {
      depth = _inferDepthCompressedLossless(kbps, khz);
    } else {
      depth = null;
    }

    // ── Graceful degradation when sample rate is unavailable ─────────────────
    // We still have meaningful information from codec + bitrate alone.
    if (khz == 0) {
      if (isLossless) {
        if ((depth ?? 0) >= 24) return 'HR';
        return 'HQ'; // any lossless beats any standard lossy
      }
      if (kbps >= 256) return 'HQ';
      if (kbps >= 128) return 'SQ';
      return 'LQ';
    }

    // ── MQ — studio master quality ───────────────────────────────────────────
    // 24-bit lossless at high sample rates (88.2 kHz+).
    // Covers: Tidal HiFi Plus, Qobuz Studio, HDtracks, Bandcamp FLAC hi-res.
    if (isLossless && (depth ?? 0) >= 24 && khz >= 88.2) return 'MQ';

    // Uncompressed 24-bit at 48 kHz+ covers professional studio/broadcast spec:
    // Blu-ray Disc audio, HDCD source masters, professional DAW exports.
    // PCM only — a 24/48 FLAC could just be an upsampled 16-bit recording,
    // but a true WAV/AIFF at 24/48 comes from a professional chain.
    if (isPCM && (depth ?? 0) >= 24 && khz >= 48.0) return 'MQ';

    // ── HR — hi-res audio ────────────────────────────────────────────────────
    // JEITA / CEA definition: "exceeds CD quality" = 24-bit at ≥ 44.1 kHz.
    // Applies to both compressed (FLAC/ALAC) and uncompressed (WAV/AIFF).
    if (isLossless && (depth ?? 0) >= 24 && khz >= 44.1) return 'HR';

    // 16-bit at high sample rates (88.2+ kHz) also qualifies as hi-res:
    // wider frequency response than 44.1 kHz CD even at the same bit depth.
    // Common in some remaster editions and archival Blu-ray rips.
    if (isLossless && (depth ?? 16) >= 16 && khz >= 88.2) return 'HR';

    // ── HQ — high quality ────────────────────────────────────────────────────
    // CD-quality lossless (16-bit / 44.1 or 48 kHz) and transparent-ish lossy.
    if (isLossless && khz >= 44.1)
      return 'HQ'; // covers all 16-bit CD-rate lossless
    if (isLossless && khz >= 32.0) return 'HQ'; // lossless at any reasonable SR

    // PCM exact reference: uncompressed CD and Blu-ray audio tracks
    if (isPCM && kbps >= 1411 && khz >= 44.1) return 'HQ';
    if (isPCM && kbps >= 1536 && khz >= 48.0) return 'HQ';

    // Transparent lossy: 256 kbps+ AAC/MP3/Opus at CD sample rate.
    // Perceptually indistinguishable from lossless for most listeners.
    if (isLossy && kbps >= 256 && khz >= 44.1) return 'HQ';
    // 320 kbps MP3 is the accepted gold standard for lossy HQ
    if (kbps >= 320 && khz >= 44.1) return 'HQ';

    // ── SQ — standard quality ────────────────────────────────────────────────
    // Typical streaming mid-tier (128–256 kbps lossy). Audible compression
    // artifacts possible on critical listening but acceptable for casual use.
    if (kbps >= 128 && khz >= 44.1) return 'SQ';
    if (kbps >= 192 && khz >= 32.0) return 'SQ';
    if (kbps >= 128 && khz >= 22.05) return 'SQ';

    // ── LQ — low quality ─────────────────────────────────────────────────────
    return 'LQ';
  }

  // ── Codec detection ────────────────────────────────────────────────────────

  static bool _isPCMCodec(String? c) {
    if (c == null) return false;
    return _pcmCodecs.any(c.contains);
  }

  static bool _isCompressedLosslessCodec(String? c) {
    if (c == null) return false;
    return _compressedLosslessCodecs.any(c.contains);
  }

  static bool _isLossyCodec(String? c) {
    if (c == null) return false;
    return _lossyCodecs.any(c.contains);
  }

  static bool _isDSD(String? codec, int sampleRate) {
    if (codec != null &&
        (codec.contains('dsd') ||
            codec.contains('dsf') ||
            codec.contains('dff') ||
            codec.contains('sacd'))) return true;
    return sampleRate == _dsd64 ||
        sampleRate == _dsd128 ||
        sampleRate == _dsd256 ||
        sampleRate == _dsd512;
  }

  // ── Bit depth inference ────────────────────────────────────────────────────

  /// Exact formula for **uncompressed PCM** (WAV / AIFF only).
  /// bitrate = sampleRate × bitDepth × channels
  /// → bitDepth = bitrate / (sampleRate × channels)
  /// Assumes stereo (2 ch). A mono file will over-estimate by 2×, but mono
  /// lossless is rare in music libraries and will still clamp to 24.
  static int _inferDepthPCM(int kbps, double khz) {
    if (kbps <= 0 || khz <= 0) return 16;
    final raw = (kbps * 1000) / (khz * 1000 * 2);
    if (raw >= 23) return 24; // allow small rounding (e.g. 23.9 at 48 kHz)
    if (raw >= 15) return 16;
    if (raw >= 7) return 8;
    return 16;
  }

  /// Heuristic for **compressed lossless** (FLAC, ALAC, APE, WavPack, TTA).
  ///
  /// These codecs report the *compressed* bitrate in ID3/Vorbis tags,
  /// which is NOT the raw PCM bitrate. Applying the PCM formula directly
  /// produces a wrong result (infers 8–13 bits for a real 24-bit file).
  ///
  /// Real-world compressed bitrate ranges (stereo music, typical FLAC):
  ///   16-bit / 44.1 kHz → 600–1100 kbps
  ///   24-bit / 44.1 kHz → 1100–1900 kbps
  ///   16-bit / 48.0 kHz → 700–1200 kbps
  ///   24-bit / 48.0 kHz → 1200–2100 kbps
  ///   24-bit / 88.2 kHz → 2200–3800 kbps   ← we short-circuit here
  ///   24-bit / 96.0 kHz → 2400–4200 kbps   ← and here
  ///   24-bit / 192.0 kHz→ 4800–8500 kbps   ← and here
  ///
  /// Threshold formula: `khz × 25 kbps`
  ///   44.1 kHz → 1102 kbps  (just above typical 16-bit upper bound)
  ///   48.0 kHz → 1200 kbps  (same rationale)
  /// Files above the threshold are classified as 24-bit; below as 16-bit.
  static int _inferDepthCompressedLossless(int kbps, double khz) {
    // At these sample rates, virtually all commercially available recordings
    // are 24-bit. No major label or audiophile source ships 16-bit 88.2+ kHz.
    if (khz >= 88.2) return 24;

    if (kbps <= 0) return 16; // no bitrate → conservative fallback

    // Sample-rate-proportional threshold between 16-bit and 24-bit FLAC ranges
    final threshold = khz * 25.0; // kbps
    return kbps >= threshold ? 24 : 16;
  }

  // ── Normalisation ──────────────────────────────────────────────────────────

  /// Some taggers write bitrate in bps instead of kbps (e.g. 1411200 vs 1411).
  static int _normalizeKbps(int bitrate) =>
      bitrate > 10000 ? bitrate ~/ 1000 : bitrate;

  /// Some taggers write sample rate pre-divided (e.g. 44 instead of 44100).
  static double _normalizeKhz(int sampleRate) =>
      sampleRate >= 1000 ? sampleRate / 1000.0 : sampleRate.toDouble();

  // ── Technical specs string ─────────────────────────────────────────────────

  static String getTechnicalSpecs({
    required int? bitrate,
    required int? sampleRate,
    String? codec,
    int? bitDepth,
  }) {
    if (sampleRate == null && bitrate == null) return 'Unknown Format';
    final parts = <String>[];
    if (sampleRate != null) {
      parts.add('${_normalizeKhz(sampleRate).toStringAsFixed(1)} kHz');
    }
    if (bitDepth != null) parts.add('$bitDepth-bit');
    if (bitrate != null) parts.add('${_normalizeKbps(bitrate)} kbps');
    if (codec != null && codec.isNotEmpty) parts.add(codec.toUpperCase());
    return parts.join(' · ');
  }
}
