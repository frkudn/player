import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_player/presentation/shared/cubit/theme_cubit/theme_cubit.dart';
import 'package:open_player/presentation/features/local_audio_player/cubit/volume/volume_cubit.dart';

import '../presentation/features/main/cubit/bottom_nav_bar_cubit.dart';
import '../presentation/features/settings/language/cubit/language_cubit/language_cubit.dart';

extension LanguageCubitExtension on BuildContext {
  LanguageCubit get languageCubit => watch<LanguageCubit>();
}

extension BottomNavigationCubitExtension on BuildContext {
  BottomNavBarCubit get bottomNavBarCubit => watch<BottomNavBarCubit>();
}

extension ThemeCubitExtension on BuildContext {
  ThemeCubit get themeCubit => watch<ThemeCubit>();
}

extension VolumeCubitExtension on BuildContext {
  VolumeCubit get volumeCubit => watch<VolumeCubit>();
}

extension HelloExt on String {
  String get a => "a";
}
