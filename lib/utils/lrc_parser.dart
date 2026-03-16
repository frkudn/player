// lib/utils/lrc_parser.dart

class LrcLine {
  final Duration timestamp;
  final String text;
  const LrcLine({required this.timestamp, required this.text});
}

class LrcParser {
  /// Returns null if lyrics are NOT in LRC format (plain text)
  static List<LrcLine>? parse(String lyrics) {
    if (lyrics.isEmpty) return null;

    // LRC lines look like: [01:23.45] Some lyric text
    final lineRegex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');
    final lines = lyrics.split('\n');
    final result = <LrcLine>[];

    for (final line in lines) {
      final match = lineRegex.firstMatch(line.trim());
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final centis = match.group(3)!;
        final millis =
            centis.length == 2 ? int.parse(centis) * 10 : int.parse(centis);
        final text = match.group(4)!.trim();

        result.add(LrcLine(
          timestamp: Duration(
            minutes: minutes,
            seconds: seconds,
            milliseconds: millis,
          ),
          text: text,
        ));
      }
    }

    // If we found at least a few timestamped lines → it's LRC
    if (result.length >= 2) {
      result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return result;
    }
    return null;
  }

  /// Returns true if the string is LRC format
  static bool isLrc(String lyrics) {
    return RegExp(r'\[\d{2}:\d{2}\.\d{2,3}\]').hasMatch(lyrics);
  }
}
