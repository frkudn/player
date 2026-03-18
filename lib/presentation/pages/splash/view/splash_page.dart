import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:open_player/base/db/hive_service.dart';
import 'package:open_player/logic/audio_bloc/audios_bloc.dart';
import 'package:open_player/logic/audio_playlist_bloc/audio_playlist_bloc.dart';
import 'package:open_player/base/router/router.dart';
import 'package:open_player/presentation/pages/splash/widgets/on_boarding_view_widget.dart';
import 'package:open_player/presentation/pages/splash/widgets/splash_view_widget.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  bool isLoggedIn =
      MyHiveBoxes.user.get(MyHiveKeys.userIsLoggedIn, defaultValue: false);
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    fetchMedia(isLoggedIn);
    navigateToNextPage(isLoggedIn);
  }

  void _setupAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOutBack,
    );

    _logoController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: // Main content
          isLoggedIn
              ? SplashViewWidget(logoAnimation: _logoAnimation)
              : OnBoardingViewWidget(logoAnimation: _logoAnimation),
    );
  }

  void navigateToNextPage(bool isLogin) {
    if (isLogin) {
      Future.delayed(const Duration(seconds: 4)).whenComplete(() {
        context.pushReplacement(AppRoutes.mainRoute);
      });
    } else {
      Future.delayed(const Duration(seconds: 8)).whenComplete(() {
        context.pushReplacement(AppRoutes.languageRoute);
      });
    }
  }

  void fetchMedia(bool isLoggedIn) {
    if (isLoggedIn) {
      context.read<AudiosBloc>().add(AudiosLoadAllEvent());
      context.read<AudioPlaylistBloc>().add(LoadPlaylistsEvent());
    }
  }
}
