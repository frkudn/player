/// Represents a single timestamped line in an LRC lyrics file
class LrcLine {
  final Duration timestamp;
  final String text;
  const LrcLine({required this.timestamp, required this.text});
}

/// Parses LRC-format lyrics strings into structured [LrcLine] objects
class LrcParser {
  /// Parses a raw lyrics string into a list of [LrcLine].
  /// Returns null if the string is not LRC format (no timestamps found).
  static List<LrcLine>? parse(String lyrics) {
    if (lyrics.isEmpty) return null;

    final lineRegex = RegExp(r'\[(\d{1,2}):(\d{2})\.(\d{2,3})\](.*)');
    final result = <LrcLine>[];

    for (final line in lyrics.split('\n')) {
      final match = lineRegex.firstMatch(line.trim());
      if (match == null) continue;

      final minutes = int.parse(match.group(1)!);
      final seconds = int.parse(match.group(2)!);
      final centis = match.group(3)!;
      final millis =
          centis.length == 2 ? int.parse(centis) * 10 : int.parse(centis);

      result.add(LrcLine(
        timestamp:
            Duration(minutes: minutes, seconds: seconds, milliseconds: millis),
        text: match.group(4)!.trim(),
      ));
    }

    if (result.length < 2) return null;

    result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return result;
  }

  /// Quick check: does this string contain LRC timestamps?
  static bool isLrc(String lyrics) =>
      RegExp(r'\[\d{1,2}:\d{2}\.\d{2,3}\]').hasMatch(lyrics);

  /// Converts [LrcLine] list back to a valid LRC string (for saving edits)
  static String toLrc(List<LrcLine> lines) {
    return lines.map((l) {
      final m = l.timestamp.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = l.timestamp.inSeconds.remainder(60).toString().padLeft(2, '0');
      final ms = (l.timestamp.inMilliseconds.remainder(1000) ~/ 10)
          .toString()
          .padLeft(2, '0');
      return '[$m:$s.$ms]${l.text}';
    }).join('\n');
  }
}
