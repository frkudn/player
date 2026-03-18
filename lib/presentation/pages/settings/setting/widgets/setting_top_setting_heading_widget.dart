import 'package:flutter/material.dart';
import 'package:open_player/base/assets/fonts/styles.dart';
import 'package:open_player/base/strings/app_strings.dart';
import 'package:open_player/utils/extensions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SETTING TOP HEADING WIDGET
//
// NOTE: This widget is no longer used directly — the header is now inlined
// inside SettingPage for tighter control over status bar padding and
// gradient treatment. However the widget is kept here in case other parts
// of the codebase import it.
//
// Improvements vs old version:
//  • MediaQuery.paddingOf(context).top for true status bar awareness
//  • Responsive font size (tablet vs phone)
//  • Version badge + tagline row
//  • Poppins font for stronger typographic identity
// ─────────────────────────────────────────────────────────────────────────────

class SettingTopSettingHeadingWidget extends StatelessWidget {
  const SettingTopSettingHeadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final String lc = context.languageCubit.state.languageCode;
    final mq = MediaQuery.sizeOf(context);
    final double topPad = MediaQuery.paddingOf(context).top + 12;
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPad, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.08),
            cs.primary.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: cs.primary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Large title — strong visual anchor
          Text(
            AppStrings.settings[lc]!,
            style: TextStyle(
              fontSize: mq.width >= 600 ? 48 : 36,
              fontFamily: AppFonts.poppins,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: cs.onSurface,
            ),
          ),

          const SizedBox(height: 6),

          // Version badge + tagline
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: cs.primary.withValues(alpha: 0.12),
                  border: Border.all(
                      color: cs.primary.withValues(alpha: 0.2), width: 1),
                ),
                child: Text(
                  AppStrings.appVersion,
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.appTagline,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.4),
                  fontSize: 11,
                  fontFamily: AppFonts.poppins,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
