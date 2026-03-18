// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class QualityBadge extends HookWidget {
  final String quality;
  final bool isDark;
  final double size;
  final bool showAnimation;
  final VoidCallback? onTap;

  const QualityBadge({
    super.key,
    this.quality = "LQ",
    this.isDark = false,
    this.size = 12,
    this.showAnimation = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isHovered = useState(false);
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );

    final scaleAnimation = useAnimation(
      Tween<double>(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(
          parent: animationController,
          curve: Curves.easeInOut,
        ),
      ),
    );

    final glowAnimation = useAnimation(
      Tween<double>(begin: 0.3, end: 0.5).animate(
        CurvedAnimation(
          parent: animationController,
          curve: Curves.easeInOut,
        ),
      ),
    );

    useEffect(() {
      if (isHovered.value) {
        animationController.forward();
      } else {
        animationController.reverse();
      }
      return null;
    }, [isHovered.value]);

    final color = _baseColor(quality);
    final label = _displayLabel(quality);

    return MouseRegion(
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      child: GestureDetector(
        onTap: onTap,
        child: Transform.scale(
          scale: showAnimation ? scaleAnimation : 1.0,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: size * 0.5,
              vertical: size * 0.167,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.333),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withValues(alpha: 0.8),
                  color.withValues(alpha: 0.9),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(
                    alpha: showAnimation ? glowAnimation : 0.3,
                  ),
                  blurRadius: size * 0.333,
                  spreadRadius: size * 0.083,
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Special icon for DSD and HR tiers
                if (quality == "DSD" || quality == "HR") ...[
                  Icon(
                    quality == "DSD"
                        ? Icons.graphic_eq_rounded
                        : Icons.hd_rounded,
                    color: Colors.white,
                    size: size * 0.7,
                  ),
                  SizedBox(width: size * 0.2),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.6,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Display label — kept short for badge readability
  String _displayLabel(String quality) {
    switch (quality) {
      case "DSD":
        return "DSD";
      case "MQ":
        return "MQ";
      case "HR":
        return "Hi-Res";
      case "HQ":
        return "HQ";
      case "SQ":
        return "SQ";
      case "LQ":
        return "LQ";
      default:
        return quality;
    }
  }

  /// Badge background color per quality tier.
  /// Tier order (best → worst): DSD → MQ → HR → HQ → SQ → LQ
  Color _baseColor(String quality) {
    switch (quality) {
      case "DSD":
        // Vivid red-orange — exotic/premium DSD format
        return const Color(0xFFFF4500);
      case "MQ":
        // Deep purple — studio master quality
        return const Color(0xFF9C27B0);
      case "HR":
        // Teal/cyan — Hi-Res Audio standard color
        // (used by Sony, Japan Audio Society branding)
        return const Color(0xFF00897B);
      case "HQ":
        // Blue — high quality lossless/transparent lossy
        return const Color(0xFF2196F3);
      case "SQ":
        // Green — standard acceptable quality
        return const Color(0xFF4CAF50);
      case "LQ":
        // Grey — low quality
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
