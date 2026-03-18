part of 'lyrics_cubit.dart';

class LyricsState extends Equatable {
  final double fontSize;
  final bool isSynced;
  final int themeIndex;
  final int styleIndex;

  const LyricsState({
    required this.fontSize,
    required this.isSynced,
    required this.themeIndex,
    required this.styleIndex,
  });

  LyricsState copyWith({
    double? fontSize,
    bool? isSynced,
    int? themeIndex,
    int? styleIndex,
  }) =>
      LyricsState(
        fontSize: fontSize ?? this.fontSize,
        isSynced: isSynced ?? this.isSynced,
        themeIndex: themeIndex ?? this.themeIndex,
        styleIndex: styleIndex ?? this.styleIndex,
      );

  @override
  List<Object> get props => [fontSize, isSynced, themeIndex, styleIndex];
}
