// ignore_for_file: constant_identifier_names

/// Calculates a perceptual quality tier from audio metadata.
///
/// Tier order (best → worst): DSD → MQ → HR → HQ → SQ → LQ
///
/// ## Key design decisions
/// - Lossless codecs store **compressed** bitrate in tags; raw PCM is never
///   stored. Inferring bit depth from compressed bitrate produces wrong results
///   (~50–60 % of PCM size). A separate lossless inference path applies a
///   compression expansion factor.
/// - When `bitDepth` metadata IS present it always takes priority — both
///   inference paths are only fallbacks.
/// - DSD is identified by codec name OR by its well-known sample rates before
///   any other tier check.
class AudioQualityCalculator {
  // ── DSD sample rates ───────────────────────────────────────────────────────
  static const int _dsd64SampleRate = 2822400;
  static const int _dsd128SampleRate = 5644800;
  static const int _dsd256SampleRate = 11289600;

  // Lossless codecs — bit depth metadata is reliable; bitrate is compressed
  static const List<String> _losslessCodecs = [
    'flac',
    'alac',
    'wav',
    'aiff',
    'ape',
    'wv',
    'wavpack',
    'tta',
  ];

  // Lossy codecs — quality is purely bitrate-dependent
  static const List<String> _lossyCodecs = [
    'mp3',
    'aac',
    'ogg',
    'vorbis',
    'opus',
    'wma',
    'ac3',
    'eac3',
  ];

  static String calculateQuality({
    required int? bitrate,
    required int? sampleRate,
    String? codec,
    int? bitDepth,
  }) {
    if (sampleRate == null) return 'LQ';

    final khz = _normalizeKhz(sampleRate);
    final kbps = bitrate != null ? _normalizeKbps(bitrate) : 0;
    final codecLow = codec?.toLowerCase();
    final isLossless = _isLosslessCodec(codecLow);
    final isLossy = _isLossyCodec(codecLow);

    // FIX: use codec-aware depth inference.
    // Lossless tags report compressed bitrate, not raw PCM — infer separately.
    final depth = bitDepth ??
        (isLossless
            ? _inferBitDepthLossless(kbps, khz)
            : _inferBitDepth(kbps, khz));

    // ── DSD ──────────────────────────────────────────────────────────────────
    if (_isDSDQuality(codecLow, sampleRate)) return 'DSD';

    // ── Master Quality (MQ) ───────────────────────────────────────────────────
    // Lossless 24-bit at high sample rates (88.2 kHz and above)
    if (isLossless && depth >= 24 && khz >= 88.2) return 'MQ';

    // Lossy at extreme sample rate + very high bitrate (rare but valid)
    if (isLossy && khz >= 176.4 && kbps >= 5600) return 'MQ';
    if (isLossy && khz >= 192.0 && kbps >= 6000) return 'MQ';
    if (isLossy && khz >= 96.0 && kbps >= 3000) return 'MQ';
    if (isLossy && khz >= 88.2 && kbps >= 2800) return 'MQ';

    // ── Hi-Res (HR) ───────────────────────────────────────────────────────────
    // JEITA definition: better-than-CD quality.
    // 24-bit at any standard sample rate ≥ 44.1 kHz qualifies.
    if (isLossless && depth >= 24 && khz >= 44.1) return 'HR';

    // FIX: 16-bit at high sample rates (88.2+ kHz) is also Hi-Res by JEITA —
    // wider frequency response than CD even at standard bit depth.
    // Previously this had no explicit lossless path and fell through to
    // the lossy bitrate check below, which could miss files with no bitrate tag.
    if (isLossless && depth >= 16 && khz >= 88.2) return 'HR';

    // Lossy at high sample rate with substantial bitrate
    if (isLossy && khz >= 88.2 && kbps >= 500) return 'HR';
    if (isLossy && khz >= 96.0 && kbps >= 400) return 'HR';

    // ── High Quality (HQ) ─────────────────────────────────────────────────────
    if (isLossless) {
      if (depth >= 16 && khz >= 44.1) return 'HQ';
      if (khz >= 44.1 && kbps >= 700) return 'HQ';
    }

    // CD lossless bitrate territory (uncompressed PCM reference)
    if (kbps >= 1411 && khz >= 44.1) return 'HQ';
    if (kbps >= 1536 && khz >= 48.0) return 'HQ';

    // Transparent lossy (256 kbps+ AAC/MP3 widely accepted as transparent)
    if (kbps >= 256 && khz >= 44.1 && (isLossy || kbps < 1000)) return 'HQ';
    if (kbps >= 320 && khz >= 44.1) return 'HQ';

    // ── Standard Quality (SQ) ─────────────────────────────────────────────────
    if (kbps >= 128 && khz >= 44.1) return 'SQ';
    if (kbps >= 192 && khz >= 32.0) return 'SQ';
    if (kbps >= 128 && khz >= 32.0) return 'SQ';

    // ── Low Quality (LQ) ──────────────────────────────────────────────────────
    return 'LQ';
  }

  // ── Codec helpers ──────────────────────────────────────────────────────────

  static bool _isLosslessCodec(String? codec) {
    if (codec == null) return false;
    return _losslessCodecs.any((c) => codec.contains(c));
  }

  static bool _isLossyCodec(String? codec) {
    if (codec == null) return false;
    return _lossyCodecs.any((c) => codec.contains(c));
  }

  static bool _isDSDQuality(String? codec, int sampleRate) {
    return codec?.contains('dsd') == true ||
        sampleRate == _dsd64SampleRate ||
        sampleRate == _dsd128SampleRate ||
        sampleRate == _dsd256SampleRate;
  }

  // ── Bit depth inference ───────────────────────────────────────────────────

  /// Infers bit depth for **lossy** codecs from tagged bitrate.
  /// Formula: bitrate ≈ sampleRate × bitDepth × channels (PCM assumption).
  /// Valid for lossy because the tagger stores the actual encoded bitrate.
  static int _inferBitDepth(int kbps, double khz) {
    if (kbps <= 0 || khz <= 0) return 16;
    final bps = kbps * 1000;
    final inferredDepth = bps / (khz * 1000 * 2); // stereo assumed
    if (inferredDepth >= 23) return 24;
    if (inferredDepth >= 15) return 16;
    return 8;
  }

  /// Infers bit depth for **lossless** codecs.
  ///
  /// Lossless taggers report the *compressed* output bitrate, not raw PCM.
  /// FLAC/ALAC typically achieve 40–60 % compression, so a 24-bit/96 kHz
  /// file that should read ~4608 kbps is tagged at ~2200–2800 kbps — low
  /// enough that the PCM formula wrongly infers 8–13 bits.
  ///
  /// Strategy:
  /// - Very high sample rates (≥ 88.2 kHz) are virtually always 24-bit in
  ///   real-world releases; treat them as 24-bit when metadata is absent.
  /// - For CD-range sample rates, back-calculate with a ~1.8× expansion
  ///   factor (inverse of typical lossless compression ratio).
  static int _inferBitDepthLossless(int kbps, double khz) {
    // High sample rates essentially never carry 8-bit audio commercially.
    // Almost all 88.2 / 96 / 176.4 / 192 kHz releases are 24-bit masters.
    if (khz >= 88.2) return 24;

    if (kbps <= 0 || khz <= 0) return 16;

    // Approximate raw PCM bitrate by inverting typical ~55 % compression.
    // 1 / 0.55 ≈ 1.82; we use 1.8 as a conservative midpoint.
    const compressionExpansion = 1.8;
    final estimatedRawKbps = kbps * compressionExpansion;
    final inferredDepth = (estimatedRawKbps * 1000) / (khz * 1000 * 2);

    if (inferredDepth >= 20) return 24; // allow rounding slack
    return 16; // conservative default for lossless
  }

  // ── Normalization ──────────────────────────────────────────────────────────

  static int _normalizeKbps(int bitrate) {
    // Some tags store bitrate in bps instead of kbps
    return bitrate > 10000 ? bitrate ~/ 1000 : bitrate;
  }

  static double _normalizeKhz(int sampleRate) {
    // Some tags store sample rate pre-divided (e.g. 44 instead of 44100)
    return sampleRate >= 1000 ? sampleRate / 1000.0 : sampleRate.toDouble();
  }

  // ── Technical specs string ─────────────────────────────────────────────────

  static String getTechnicalSpecs({
    required int? bitrate,
    required int? sampleRate,
    String? codec,
    int? bitDepth,
  }) {
    if (bitrate == null || sampleRate == null) return 'Unknown Format';

    final kbps = _normalizeKbps(bitrate);
    final khz = _normalizeKhz(sampleRate).toStringAsFixed(1);
    final bitDepthStr = bitDepth != null ? ' / $bitDepth-bit' : '';
    final codecStr = codec != null ? ' / $codec' : '';

    return '$khz kHz$bitDepthStr / $kbps kbps$codecStr';
  }
}
