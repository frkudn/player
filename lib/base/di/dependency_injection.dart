import 'package:color_log/color_log.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart' hide AudioSource;
import 'package:open_player/data/services/audio/audio_player_services.dart';
import 'package:open_player/data/services/user/user_services.dart';
import 'package:open_player/presentation/features/audio_section/bloc/greeting/greeting_cubit.dart';
import 'package:open_player/presentation/features/settings/language/cubit/language_cubit/language_cubit.dart';
import '../../data/sources/audio/audio_source.dart';
import '../../data/repositories/audio/audio_repository.dart';
import '../theme/themes_data.dart';

GetIt getIt = GetIt.instance;

Future<void> initializeLocator() async {
  await getIt.reset();

  try {
    getIt.registerSingleton<AppThemes>(AppThemes());
    clog.checkSuccess(true, "AppThemes registered");

    getIt.registerLazySingleton<AudioSource>(() => AudioSource());
    clog.checkSuccess(true, "AudioProvider registered");

    getIt.registerLazySingleton<AudioRepository>(
        () => AudioRepository(getIt<AudioSource>()));
    clog.checkSuccess(true, "AudioRepository registered");

    getIt.registerLazySingleton<UserService>(() => UserService());
    clog.checkSuccess(true, "UserService registered");

    getIt.registerLazySingleton<AudioPlayer>(() => AudioPlayer());
    clog.checkSuccess(true, "JustAudio Player registered");

    getIt.registerLazySingleton<AudioPlayerService>(
        () => AudioPlayerService(audioPlayer: getIt<AudioPlayer>()));
    clog.checkSuccess(true, "AudioPlayer Services registered");

    getIt.registerLazySingleton<LanguageCubit>(() => LanguageCubit());
    clog.checkSuccess(true, "LanguageCubit registered");

    getIt.registerLazySingleton<GreetingCubit>(
        () => GreetingCubit(languageCubit: getIt<LanguageCubit>()));
    clog.checkSuccess(true, "GreetingCubit registered");

    getIt.registerLazySingleton<ScrollController>(() => ScrollController(),
        instanceName: "audios");
    clog.checkSuccess(true, "Audios Page Scroll Controller registered");

    clog.checkSuccess(true, "All dependencies registered successfully");
  } catch (e) {
    clog.checkSuccess(false, 'Initialization error: $e');
  }
}
