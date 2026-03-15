import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/utils/extensions.dart';
import 'package:velocity_x/velocity_x.dart';

class CustomBrightnessBoxWidget extends StatelessWidget {
  const CustomBrightnessBoxWidget({super.key, this.boxHeight, this.boxWidth});

  final double? boxWidth;
  final double? boxHeight;

  @override
  Widget build(BuildContext context) {
    final bState = context.brightnessCubit.state;
    final double brightnessValue = bState.videoPlayerBrightness;
    String brightnessLabel = "";

    // Use if-else conditions for the brightness range
    if (brightnessValue == 1.0) {
      brightnessLabel = "none";
    } else if (brightnessValue == 0.0) {
      brightnessLabel = "max";
    } else if (brightnessValue >= 0.9) {
      brightnessLabel = "10";
    } else if (brightnessValue >= 0.8) {
      brightnessLabel = "20";
    } else if (brightnessValue >= 0.7) {
      brightnessLabel = "30";
    } else if (brightnessValue >= 0.6) {
      brightnessLabel = "40";
    } else if (brightnessValue >= 0.5) {
      brightnessLabel = "50";
    } else if (brightnessValue >= 0.4) {
      brightnessLabel = "60";
    } else if (brightnessValue >= 0.3) {
      brightnessLabel = "70";
    } else if (brightnessValue >= 0.2) {
      brightnessLabel = "80";
    } else if (brightnessValue >= 0.1) {
      brightnessLabel = "90";
    } else if (brightnessValue > 0.0) {
      brightnessLabel = "100";
    }

    return Align(
      alignment: Alignment.center,
      child: Card(
        elevation: 8,
        color: Colors.black.withValues(alpha: 0.6),
        child: SizedBox(
          height: boxHeight ?? 80,
          width: boxWidth ?? 80,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  brightnessLabel,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  HugeIcons.strokeRoundedBulb,
                  color: Colors.white,
                  size: 25,
                ),
              ],
            ),
          ),
        ),
      ).hide(isVisible: bState.showBrightnessBox),
    );
  }
}
