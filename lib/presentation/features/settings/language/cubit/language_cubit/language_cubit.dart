import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:open_player/base/db/hive_service.dart';

part 'language_state.dart';

/// A [Cubit] that manages the application's current language state.
///
/// This cubit provides functionality to change the language and
/// persists the selected language using Hive.
class LanguageCubit extends Cubit<LanguageState> {
  /// Creates a [LanguageCubit] and initializes the state with the default
  /// language from Hive, or defaults to English ("en") if not set.
  LanguageCubit() : super(LanguageState.initial());

  /// Changes the current language to the specified [languageCode].
  ///
  /// This method emits a new [LanguageState] with the updated language
  /// and persists the new language setting in Hive.
  void changeLanguage(String languageCode) {
    emit(state.copyWith(languageCode: languageCode)); // Emit new state

    // Persist the selected language in Hive
    MyHiveBoxes.language.put(MyHiveKeys.defaultLanguage, languageCode);
  }
}
