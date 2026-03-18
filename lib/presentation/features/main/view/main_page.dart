import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_player/presentation/features/main/widgets/bottom-navbar/custom_bottom_nav_bar_widget.dart';
import 'package:open_player/presentation/features/online_music/view/online_music_main_page.dart';
import '../../audio_section/views/main/view/audio_page.dart';
import '../../settings/setting/view/setting_page.dart';
import '../cubit/bottom_nav_bar_cubit.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  // Pages are created once and kept alive via IndexedStack.
  // This is critical for the WebView — without it, the web page
  // reloads every time the user switches tabs.
  static final List<Widget> _pages = [
    AudioPage(),
    const OnlineMusicMainPage(),
    const SettingPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<BottomNavBarCubit, BottomNavBarState>(
        builder: (context, state) {
          return Stack(
            children: [
              IndexedStack(
                index: state.index,
                children: _pages,
              ),
              const CustomBottomNavBarWidget(),
            ],
          );
        },
      ),
    );
  }
}
