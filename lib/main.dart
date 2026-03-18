import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:open_player/base/db/hive_service.dart';
import 'package:open_player/base/services/system/system_service.dart';
import 'package:open_player/base/theme/themes_data.dart';
import 'package:open_player/base/di/dependency_injection.dart';
import 'package:open_player/base/router/router.dart';
import 'package:open_player/bloc_providers.dart';
import 'package:open_player/presentation/shared/cubit/theme_cubit/theme_cubit.dart';
import 'package:open_player/presentation/shared/cubit/theme_cubit/theme_state.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'base/services/notification/notification_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable WebView debugging in debug mode
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(!kReleaseMode);
  }

  // Initialize Get It Dependencies
  await initializeLocator();

  // Initialize Hive database
  await MyHiveDatabase.initializeHive();

  // Set up notification services
  await NotificationServices().initializeAll();

  // Set Orientation To Portrait
  await SystemService.setOrientationPortraitOnly();

  // Set UIMode To EdgeToEdge
  await SystemService.setUIModeEdgeToEdge();

  // Enable wakelock
  WakelockPlus.enable();

  runApp(DevicePreview(
      enabled: !kReleaseMode, builder: (context) => const MyApp()));
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
            theme: getIt<AppThemes>().themes(themeState),
            title: "Player",
          );
        },
      ),
    );
  }
}
