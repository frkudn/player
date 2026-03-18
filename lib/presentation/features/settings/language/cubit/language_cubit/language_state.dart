part of 'language_cubit.dart';

class LanguageState extends Equatable {
  const LanguageState({required this.languageCode});

  final String languageCode;

  factory LanguageState.initial() => LanguageState(
      languageCode:
          MyHiveBoxes.language.get(MyHiveKeys.defaultLanguage) ?? "en");

  LanguageState copyWith({languageCode}) {
    return LanguageState(languageCode: languageCode ?? this.languageCode);
  }

  @override
  List<Object> get props => [languageCode];
}
