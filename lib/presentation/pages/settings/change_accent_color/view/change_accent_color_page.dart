import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:open_player/presentation/pages/audio/main/view/audio_page.dart';
import 'package:open_player/presentation/common/widgets/custom_theme_mode_button_widget.dart';
import 'package:open_player/presentation/pages/online_music/view/online_music_main_page.dart';
import 'package:open_player/presentation/pages/settings/change_accent_color/widgets/change_primary_page_color_selector_widget.dart';
import 'package:open_player/presentation/pages/settings/setting/view/setting_page.dart';
import '../../../../../logic/theme_cubit/theme_cubit.dart';
import '../../../../../logic/theme_cubit/theme_state.dart';

class ChangeAccentColorPage extends HookWidget {
  ChangeAccentColorPage({super.key});

  // List of pages to be displayed in the PageView
  final _pages = [
    AudioPage(),
    const OnlineMusicMainPage(),
    const SettingPage(),
  ];

  @override
  Widget build(BuildContext context) {
    // Page controller to manage the PageView
    final pageController = usePageController(initialPage: 0);
    // State to keep track of the current page index
    final currentPage = useState(0.0);

    // Effect to listen to page changes
    useEffect(() {
      void listener() => currentPage.value = pageController.page ?? 0;
      // Add listener to update current page state
      pageController.addListener(listener);
      // Clean up listener on widget unmount
      return () => pageController.removeListener(listener);
    }, []);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () => context.pop(), icon: Icon(CupertinoIcons.back)),
        title: const Text("Accent Color"),
        centerTitle: true,
        actions: const [
          CustomThemeModeButtonWidget()
        ], // Button for theme mode toggle
      ),
      body: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          // Build UI based on the current theme state
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(state.primaryColor).withValues(alpha: 0.8),
                  Color(state.primaryColor).withValues(alpha: 0.2),
                ],
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Preview Container for the pages
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  height: MediaQuery.of(context).size.height * 0.65,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Color(state.primaryColor).withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: PageView.builder(
                    controller: pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) => currentPage.value =
                        index.toDouble(), // Update current page index
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return AnimatedScale(
                        duration: const Duration(milliseconds: 200),
                        scale: index == currentPage.value.round()
                            ? 1
                            : 0.9, // Scale effect for current page
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Card(
                              elevation: 0,
                              margin: EdgeInsets.zero,
                              child: _pages[index], // Display the current page
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Spacer(),

                //------------------- Page Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: currentPage.value.round() == index
                          ? 24
                          : 8, // Indicate current page
                      decoration: BoxDecoration(
                        color: currentPage.value.round() == index
                            ? Color(state.primaryColor)
                            : Color(state.primaryColor).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                //--------------------- Color Selector
                ChangePrimaryPageColorSelectorWidget(),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
