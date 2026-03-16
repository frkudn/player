class LrcLine {
  final Duration timestamp;
  final String text;
  const LrcLine({required this.timestamp, required this.text});
}

class LrcMetadata {
  final String? title;
  final String? artist;
  final String? album;
  final String? by; // lyrics author
  LrcMetadata({this.title, this.artist, this.album, this.by});
}

class LrcParser {
  static List<LrcLine>? parse(String lyrics) {
    if (lyrics.isEmpty) return null;
    final lineRegex = RegExp(r'\[(\d{1,2}):(\d{2})\.(\d{2,3})\](.*)');
    final result = <LrcLine>[];

    for (final line in lyrics.split('\n')) {
      final match = lineRegex.firstMatch(line.trim());
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final centis  = match.group(3)!;
        final millis  = centis.length == 2
            ? int.parse(centis) * 10
            : int.parse(centis);
        final text = match.group(4)!.trim();
        result.add(LrcLine(
          timestamp: Duration(
              minutes: minutes, seconds: seconds, milliseconds: millis),
          text: text,
        ));
      }
    }

    if (result.length >= 2) {
      result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return result;
    }
    return null;
  }

  static bool isLrc(String lyrics) =>
      RegExp(r'\[\d{1,2}:\d{2}\.\d{2,3}\]').hasMatch(lyrics);

  /// Convert LRC lines back to LRC string for saving
  static String toLrc(List<LrcLine> lines) {
    return lines.map((l) {
      final m  = l.timestamp.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s  = l.timestamp.inSeconds.remainder(60).toString().padLeft(2, '0');
      final ms = (l.timestamp.inMilliseconds.remainder(1000) ~/ 10)
          .toString()
          .padLeft(2, '0');
      return '[$m:$s.$ms]${l.text}';
    }).join('\n');
  }
}