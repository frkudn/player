import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_player/utils/extensions.dart';

import '../../../logic/theme_cubit/theme_cubit.dart';

class CustomThemeModeButtonWidget extends StatelessWidget {
  const CustomThemeModeButtonWidget({super.key});

  // Cached gradients and decorations to avoid recreating them
  static final _darkGradient = LinearGradient(
    colors: [Colors.grey[850]!, Colors.grey[900]!],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final _lightGradient = LinearGradient(
    colors: [
      Colors.blue[300]!,
      Colors.purple[200]!,
      Colors.pink[200]!,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final _darkToggleGradient = LinearGradient(
    colors: [Colors.grey[900]!, Colors.grey[800]!],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final _lightToggleGradient = LinearGradient(
    colors: [Colors.orange[300]!, Colors.yellow[400]!],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Cached decorations
  BoxDecoration _getContainerDecoration(bool isDark, BuildContext context) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      gradient: isDark ? _darkGradient : _lightGradient,
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.3)
              : Colors.blue[300]!.withValues(alpha: 0.5),
          blurRadius: 8,
          spreadRadius: 1,
        ),
        if (!isDark)
          BoxShadow(
            color: Colors.pink[200]!.withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(4, 4),
          ),
      ],
    );
  }

  BoxDecoration _getToggleDecoration(bool isDark) {
    return BoxDecoration(
      shape: BoxShape.circle,
      gradient: isDark ? _darkToggleGradient : _lightToggleGradient,
      boxShadow: [
        BoxShadow(
          color: isDark ? Colors.black38 : Colors.orange.withValues(alpha: 0.3),
          blurRadius: 4,
          spreadRadius: 1,
        ),
        if (!isDark)
          BoxShadow(
            color: Colors.yellow[200]!.withValues(alpha: 0.5),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(2, 2),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);
    final toggleSize = mq.height * 0.035;
    final isDark = context.themeCubit.state.isDarkMode;

    return SizedBox(
      width: mq.width * 0.18,
      height: mq.height * 0.045,
      child: GestureDetector(
        onTap: () => context.read<ThemeCubit>().toggleThemeMode(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(3),
          decoration: _getContainerDecoration(isDark, context),
          child: Stack(
            children: [
              // Optimized background elements using const where possible
              if (isDark) const _DarkModeStars(),
              if (!isDark) const _LightModeClouds(),

              // Sliding toggle
              AnimatedAlign(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                alignment:
                    isDark ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: toggleSize,
                  height: toggleSize,
                  decoration: _getToggleDecoration(isDark),
                  child: AnimatedRotation(
                    duration: const Duration(milliseconds: 500),
                    turns: isDark ? 0.5 : 0,
                    child: Icon(
                      isDark ? Icons.dark_mode : Icons.wb_sunny_rounded,
                      color: isDark ? Colors.grey[300] : Colors.orange[800],
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DarkModeStars extends StatelessWidget {
  const _DarkModeStars();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(
        5,
        (index) => Positioned(
          left: index * 10.0 + 5,
          top: index * 5.0 + 2,
          child: Icon(
            Icons.star,
            size: 8,
            color: Colors.yellow[100],
          ),
        ),
      ),
    );
  }
}

class _LightModeClouds extends StatelessWidget {
  const _LightModeClouds();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Clouds
        ...List.generate(
          3,
          (index) => Positioned(
            left: index * 15.0 + 5,
            top: index * 7.0 + 2,
            child: Icon(
              Icons.cloud,
              size: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ),
        // Sparkles
        ...List.generate(
          4,
          (index) => Positioned(
            left: index * 12.0,
            top: (index % 2) * 15.0,
            child: TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (context, double value, child) {
                return Transform.rotate(
                  angle: value * 2 * 3.14,
                  child: Icon(
                    Icons.auto_awesome,
                    size: 10,
                    color: Colors.yellow[100],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
