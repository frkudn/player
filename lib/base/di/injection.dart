import 'package:color_log/color_log.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:open_player/data/services/audio/audio_player_services.dart';
import 'package:open_player/data/services/user/user_services.dart';
import 'package:open_player/logic/greeting/greeting_cubit.dart';
import 'package:open_player/logic/language_cubit/language_cubit.dart';
import '../../data/providers/audio/audio_provider.dart';
import '../../data/repositories/audio/audio_repository.dart';
import '../theme/themes_data.dart';

GetIt locator = GetIt.instance;

Future<void> initializeLocator() async {
  await locator.reset();

  try {
    locator.registerSingleton<AppThemes>(AppThemes());
    clog.checkSuccess(true, "AppThemes registered");

    locator.registerLazySingleton<AudioProvider>(() => AudioProvider());
    clog.checkSuccess(true, "AudioProvider registered");

    locator.registerLazySingleton<AudioRepository>(
        () => AudioRepository(locator<AudioProvider>()));
    clog.checkSuccess(true, "AudioRepository registered");

    locator.registerLazySingleton<UserService>(() => UserService());
    clog.checkSuccess(true, "UserService registered");

    locator.registerLazySingleton<AudioPlayer>(() => AudioPlayer());
    clog.checkSuccess(true, "JustAudio Player registered");

    locator.registerLazySingleton<AudioPlayerService>(
        () => AudioPlayerService(audioPlayer: locator<AudioPlayer>()));
    clog.checkSuccess(true, "AudioPlayer Services registered");

    locator.registerLazySingleton<LanguageCubit>(() => LanguageCubit());
    clog.checkSuccess(true, "LanguageCubit registered");

    locator.registerLazySingleton<GreetingCubit>(
        () => GreetingCubit(languageCubit: locator<LanguageCubit>()));
    clog.checkSuccess(true, "GreetingCubit registered");

    locator.registerLazySingleton<ScrollController>(() => ScrollController(),
        instanceName: "audios");
    clog.checkSuccess(true, "Audios Page Scroll Controller registered");

    clog.checkSuccess(true, "All dependencies registered successfully");
  } catch (e) {
    clog.checkSuccess(false, 'Initialization error: $e');
  }
}
