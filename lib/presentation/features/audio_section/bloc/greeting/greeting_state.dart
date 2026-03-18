part of 'greeting_cubit.dart';

class GreetingState extends Equatable {
  final String greeting;

  const GreetingState({required this.greeting});
  GreetingState copyWith({greeting}) {
    return GreetingState(greeting: greeting ?? this.greeting);
  }

  factory GreetingState.initial() => GreetingState(
      greeting:
          MyHiveBoxes.language.get(MyHiveKeys.defaultLanguage) ?? "Hello!");
  @override
  List<Object?> get props => [greeting];
}
