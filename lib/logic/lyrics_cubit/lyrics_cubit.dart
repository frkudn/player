import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:open_player/base/db/hive_service.dart';

part 'lyrics_state.dart';

/// Manages lyrics display preferences.
/// Lives in blocProviders so state survives show/hide of the lyrics widget.
class LyricsCubit extends Cubit<LyricsState> {
  LyricsCubit() : super(_loadFromHive());

  /// Load saved preferences from Hive on startup
  static LyricsState _loadFromHive() {
    final p = MyHiveBoxes.lyricsPrefs;
    return LyricsState(
      fontSize: (p.get(MyHiveKeys.lyricsFontSize) as num?)?.toDouble() ?? 18.0,
      isSynced: p.get(MyHiveKeys.lyricsIsSynced) as bool? ?? true,
      themeIndex: p.get(MyHiveKeys.lyricsThemeIndex) as int? ?? 0,
      styleIndex: p.get(MyHiveKeys.lyricsStyleIndex) as int? ?? 0,
    );
  }

  /// Change color theme and persist
  void setTheme(int i) {
    emit(state.copyWith(themeIndex: i));
    MyHiveBoxes.lyricsPrefs.put(MyHiveKeys.lyricsThemeIndex, i);
  }

  /// Change display style and persist
  void setStyle(int i) {
    emit(state.copyWith(styleIndex: i));
    MyHiveBoxes.lyricsPrefs.put(MyHiveKeys.lyricsStyleIndex, i);
  }

  /// Change font size and persist
  void setFontSize(double v) {
    final clamped = v.clamp(10.0, 36.0);
    emit(state.copyWith(fontSize: clamped));
    MyHiveBoxes.lyricsPrefs.put(MyHiveKeys.lyricsFontSize, clamped);
  }

  /// Toggle synced/plain mode and persist
  void toggleSynced() {
    final v = !state.isSynced;
    emit(state.copyWith(isSynced: v));
    MyHiveBoxes.lyricsPrefs.put(MyHiveKeys.lyricsIsSynced, v);
  }
}
