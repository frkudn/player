import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_player/base/db/hive_service.dart';
import 'package:open_player/base/services/system/system_service.dart';
import 'package:open_player/base/theme/themes_data.dart';
import 'package:open_player/base/di/injection.dart';
import 'package:open_player/base/router/router.dart';
import 'package:open_player/bloc_providers.dart';
import 'package:open_player/logic/theme_cubit/theme_cubit.dart';
import 'package:open_player/logic/theme_cubit/theme_state.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'base/services/notification/notification_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //--- Initialize Get It Dependencies
  await initializeLocator();

  // Initialize Hive database and register custom adapters
  await MyHiveDatabase.initializeHive();

  // Set up notification services
  await NotificationServices().initializeAll();

  // Set Orientation To Portrait
  await SystemService.setOrientationPortraitOnly();

  // Set UIMode To EdgeToEdge
  await SystemService.setUIModeEdgeToEdge();

  // The following line will enable the Android and iOS wakelock.
  WakelockPlus.enable();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: blocProviders(),
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp.router(
            routerConfig: router,
            themeAnimationCurve: Easing.standardAccelerate,
            themeAnimationDuration: const Duration(milliseconds: 1000),
            debugShowCheckedModeBanner: false,
            theme: locator<AppThemes>().themes(themeState),
            title: "Player",
          );
        },
      ),
    );
  }
}
