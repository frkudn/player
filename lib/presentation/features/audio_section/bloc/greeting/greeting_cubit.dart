import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:open_player/base/db/hive_service.dart';
import '../../../../../base/strings/app_greeting_strings.dart';
import '../../../settings/language/cubit/language_cubit/language_cubit.dart';
part 'greeting_state.dart';

/// A [Cubit] that manages the application's greeting state.
///
/// This cubit updates the greeting based on the current time of day
/// and adapts the greeting based on the selected language from
/// [LanguageCubit].
class GreetingCubit extends Cubit<GreetingState> {
  late LanguageCubit languageCubit; // Holds a reference to LanguageCubit

  /// Creates a [GreetingCubit] with the specified [languageCubit].
  GreetingCubit({required this.languageCubit})
      : super(GreetingState.initial()) {
    updateGreeting(
        languageCode: MyHiveBoxes.language.get(MyHiveKeys.defaultLanguage) ??
            "en"); // Initialize the greeting when the cubit is created
  }

  /// Updates the greeting based on the current time of day.
  void updateGreeting({required String languageCode}) {
    final hour = DateTime.now().hour; // Get the current hour
    String greeting;

    // Determine the appropriate greeting based on the current hour
    if (hour < 12) {
      greeting = _getLocalizedGreeting(languageCode, "morning");
    } else if (hour < 17) {
      greeting = _getLocalizedGreeting(languageCode, "afternoon");
    } else if (hour < 21) {
      greeting = _getLocalizedGreeting(languageCode, "evening");
    } else {
      greeting = _getLocalizedGreeting(languageCode, "night");
    }

    emit(state.copyWith(greeting: greeting)); // Emit the new greeting state
  }

  /// Returns a localized greeting based on the provided time of day.
  String _getLocalizedGreeting(String languageCode, String time) {
    // Find the greeting for the specified time
    final greetingMap = AppGreetingString.greetings
        .firstWhere((greeting) => greeting['time'] == time)['greeting'];

    // Return the greeting based on the language code
    return greetingMap[languageCode] ??
        greetingMap['en']; // Fallback to English if the language is not found
  }
}
