class AudioQualityCalculator {
  // DSD sample rates
  static const int _dsd64SampleRate = 2822400;
  static const int _dsd128SampleRate = 5644800;
  static const int _dsd256SampleRate = 11289600;

  // Lossless codecs — bit depth metadata is reliable, bitrate alone is not
  static const List<String> _losslessCodecs = [
    'flac',
    'alac',
    'wav',
    'aiff',
    'ape',
    'wv',
    'wavpack',
    'tta'
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
    'eac3'
  ];

  /// Quality tier order (best → worst):
  /// DSD → MQ → HR → HQ → SQ → LQ
  static String calculateQuality({
    required int? bitrate,
    required int? sampleRate,
    String? codec,
    int? bitDepth,
  }) {
    if (sampleRate == null) return "LQ";

    final khz = _normalizeKhz(sampleRate);
    final kbps = bitrate != null ? _normalizeKbps(bitrate) : 0;
    final codecLow = codec?.toLowerCase();
    final isLossless = _isLosslessCodec(codecLow);
    final isLossy = _isLossyCodec(codecLow);
    final depth = bitDepth ?? _inferBitDepth(kbps, khz);

    // ── DSD ──────────────────────────────────────────────────────────────────
    if (_isDSDQuality(codecLow, sampleRate)) return "DSD";

    // ── Master Quality (MQ) ───────────────────────────────────────────────────
    // Lossless 24-bit at high sample rates (88.2 kHz and above)
    if (isLossless && depth >= 24 && khz >= 88.2) return "MQ";

    // Lossy at extreme sample rate + very high bitrate
    if (khz >= 176.4 && kbps >= 5600) return "MQ";
    if (khz >= 192.0 && kbps >= 6000) return "MQ";
    if (khz >= 96.0 && kbps >= 3000) return "MQ";
    if (khz >= 88.2 && kbps >= 2800) return "MQ";

    // ── Hi-Res (HR) ───────────────────────────────────────────────────────────
    // JEITA Hi-Res Audio definition:
    // better-than-CD quality (24-bit) but not full high-sample-rate master
    if (isLossless && depth >= 24 && khz >= 44.1) return "HR";
    if (isLossless && depth >= 24 && khz >= 48.0) return "HR";

    // Lossy at high sample rate with substantial bitrate
    if (khz >= 88.2 && kbps >= 500) return "HR";
    if (khz >= 96.0 && kbps >= 400) return "HR";

    // ── High Quality (HQ) ─────────────────────────────────────────────────────
    if (isLossless) {
      if (depth >= 16 && khz >= 44.1) return "HQ";
      if (khz >= 44.1 && kbps >= 700) return "HQ";
    }

    // CD lossless bitrate territory
    if (kbps >= 1411 && khz >= 44.1) return "HQ";
    if (kbps >= 1536 && khz >= 48.0) return "HQ";

    // Transparent lossy (256 kbps+ AAC/MP3 widely accepted as transparent)
    if (kbps >= 256 && khz >= 44.1 && (isLossy || kbps < 1000)) return "HQ";
    if (kbps >= 320 && khz >= 44.1) return "HQ";

    // ── Standard Quality (SQ) ─────────────────────────────────────────────────
    if (kbps >= 128 && khz >= 44.1) return "SQ";
    if (kbps >= 192 && khz >= 32.0) return "SQ";
    if (kbps >= 128 && khz >= 32.0) return "SQ";

    // ── Low Quality (LQ) ──────────────────────────────────────────────────────
    return "LQ";
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
  // Estimates bit depth from: bitrate ≈ sampleRate × bitDepth × channels
  // Assumes stereo (2 channels). Used only when bitDepth metadata is missing.
  static int _inferBitDepth(int kbps, double khz) {
    if (kbps <= 0 || khz <= 0) return 16;
    final bps = kbps * 1000;
    final inferredDepth = bps / (khz * 1000 * 2); // 2 = stereo
    if (inferredDepth >= 23) return 24; // allow small rounding errors
    if (inferredDepth >= 15) return 16;
    return 8;
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
