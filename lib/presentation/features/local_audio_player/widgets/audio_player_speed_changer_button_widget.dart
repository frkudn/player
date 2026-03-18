import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:open_player/presentation/features/local_audio_player/bloc/audio_player_bloc.dart';
import 'package:open_player/presentation/shared/widgets/nothing_widget.dart';
import 'package:color_log/color_log.dart';
import 'dart:math' as math;

// ─── Entry point widget (bottom bar button) ───────────────────────────────────

class AudioPlayerSpeedChangerButtonWidget extends StatelessWidget {
  const AudioPlayerSpeedChangerButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return BlocSelector<AudioPlayerBloc, AudioPlayerState,
        AudioPlayerSuccessState?>(
      selector: (s) => s is AudioPlayerSuccessState ? s : null,
      builder: (context, state) {
        if (state == null) return nothing;

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: StreamBuilder<double>(
            stream: state.audioPlayer.speedStream,
            initialData: 1.0,
            builder: (context, snapshot) {
              final speed = snapshot.data ?? 1.0;
              final isModified = (speed - 1.0).abs() > 0.01;
          
              return GestureDetector(
                onTap: () {
                  context.pop();
                  _showSpeedDialog(context);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                         isModified
                            ? primary.withValues(alpha: 0.15)
                            : onSurface.withValues(alpha: 0.08),
                        border: Border.all(
                          // color: isModified
                          //     ? primary.withValues(alpha: 0.7)
                          //     : onSurface.withValues(alpha: 0.25),
                          color: Colors.white60,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${speed.toStringAsFixed(speed == speed.roundToDouble() ? 1 : 2)}×',
                          style: TextStyle(
                            // color: isModified ? primary : onSurface,
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),
                    const Gap(4),
                    Text(
                      'Speed',
                      style: TextStyle(
                        // color: onSurface.withValues(alpha: 0.6),
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showSpeedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: BlocProvider.value(
          value: context.read<AudioPlayerBloc>(),
          child: const _SpeedDialog(),
        ),
      ),
    );
  }
}

// ─── Main dialog ──────────────────────────────────────────────────────────────

class _SpeedDialog extends StatelessWidget {
  const _SpeedDialog();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AudioPlayerBloc, AudioPlayerState,
        AudioPlayerSuccessState?>(
      selector: (s) => s is AudioPlayerSuccessState ? s : null,
      builder: (context, state) {
        if (state == null) return nothing;
        return StreamBuilder<double>(
          stream: state.audioPlayer.speedStream,
          initialData: 1.0,
          builder: (context, snapshot) {
            return _SpeedDialogContent(speed: snapshot.data ?? 1.0);
          },
        );
      },
    );
  }
}

// ─── Dialog content ───────────────────────────────────────────────────────────

class _SpeedDialogContent extends StatefulWidget {
  final double speed;
  const _SpeedDialogContent({required this.speed});

  @override
  State<_SpeedDialogContent> createState() => _SpeedDialogContentState();
}

class _SpeedDialogContentState extends State<_SpeedDialogContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const List<_SpeedPreset> _presets = [
    _SpeedPreset(0.5,  '0.5×',  'Half'),
    _SpeedPreset(0.75, '0.75×', 'Slow'),
    _SpeedPreset(1.0,  '1×',    'Normal'),
    _SpeedPreset(1.25, '1.25×', 'Fast'),
    _SpeedPreset(1.5,  '1.5×',  'Faster'),
    _SpeedPreset(1.75, '1.75×', 'Quick'),
    _SpeedPreset(2.0,  '2×',    'Max'),
  ];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  void _setSpeed(double v) {
    HapticFeedback.selectionClick();
    context.read<AudioPlayerBloc>().add(AudioPlayerChangeSpeedEvent(value: v));
    clog.debug('Speed → $v');
  }

  // ── Theme helpers ──────────────────────────────────────────────────────────

  /// Background color for the dialog card.
  /// Black mode → pure black, dark → dark surface, light → white-ish surface.
  Color _cardBg(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final scaffold = Theme.of(context).scaffoldBackgroundColor;
    // If scaffold is black (black mode), keep the card black too
    if (scaffold == Colors.black) return const Color(0xFF0A0A0A);
    return cs.surface;
  }

  /// Subtle surface tint (used for chip backgrounds, fine-tune tiles).
  Color _surfaceTint(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return cs.surfaceContainerHighest;
  }

  /// Text / icon color on top of the card.
  Color _onCard(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  /// App primary accent color.
  Color _primary(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  @override
  Widget build(BuildContext context) {
    final cardBg  = _cardBg(context);
    final primary = _primary(context);
    final onCard  = _onCard(context);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: cardBg,
            border: Border.all(
              color: onCard.withValues(alpha: 0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.18),
                blurRadius: 40,
                spreadRadius: -8,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(context),
                  const Gap(22),
                  _buildArcIndicator(context, widget.speed),
                  const Gap(20),
                  _buildSlider(context, widget.speed),
                  const Gap(18),
                  _buildPresetChips(context, widget.speed),
                  const Gap(18),
                  _buildFineTune(context, widget.speed),
                  const Gap(6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final primary = _primary(context);
    final onCard  = _onCard(context);
    final isDefault = (widget.speed - 1.0).abs() < 0.01;

    return Row(
      children: [
        // Icon badge
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary.withValues(alpha: 0.12),
          ),
          child: Icon(Icons.speed_rounded, color: primary, size: 19),
        ),
        const Gap(12),
        // Title + subtitle
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Playback Speed',
              style: TextStyle(
                color: onCard,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              _speedLabel(widget.speed),
              style: TextStyle(
                color: onCard.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Reset pill
        GestureDetector(
          onTap: () => _setSpeed(1.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isDefault
                  ? primary.withValues(alpha: 0.18)
                  : onCard.withValues(alpha: 0.07),
              border: Border.all(
                color: isDefault
                    ? primary.withValues(alpha: 0.45)
                    : onCard.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Text(
              'Reset',
              style: TextStyle(
                color: isDefault ? primary : onCard.withValues(alpha: 0.45),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Arc indicator ──────────────────────────────────────────────────────────

  Widget _buildArcIndicator(BuildContext context, double speed) {
    final primary = _primary(context);
    final onCard  = _onCard(context);

    return SizedBox(
      height: 92,
      child: CustomPaint(
        painter: _ArcPainter(
          speed: speed,
          trackColor: onCard.withValues(alpha: 0.08),
          primaryColor: primary,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                speed.toStringAsFixed(
                    speed == speed.roundToDouble() ? 1 : 2),
                style: TextStyle(
                  color: onCard,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2,
                  height: 1,
                ),
              ),
              Text(
                '×  speed',
                style: TextStyle(
                  color: onCard.withValues(alpha: 0.3),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Slider ─────────────────────────────────────────────────────────────────

  Widget _buildSlider(BuildContext context, double speed) {
    final primary = _primary(context);
    final onCard  = _onCard(context);

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape:
                const RoundSliderOverlayShape(overlayRadius: 18),
            activeTrackColor: primary,
            inactiveTrackColor: onCard.withValues(alpha: 0.1),
            thumbColor: Theme.of(context).colorScheme.onPrimary == Colors.white
                ? Colors.white
                : primary,
            overlayColor: primary.withValues(alpha: 0.15),
            valueIndicatorColor: primary,
            valueIndicatorTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            showValueIndicator: ShowValueIndicator.onDrag,
          ),
          child: Slider(
            min: 0.25,
            max: 2.5,
            divisions: 45,
            value: speed.clamp(0.25, 2.5),
            label: '${speed.toStringAsFixed(2)}×',
            onChanged: (v) {
              final rounded = (v * 20).round() / 20.0;
              _setSpeed(rounded);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0.25×',
                  style: TextStyle(
                      color: onCard.withValues(alpha: 0.28),
                      fontSize: 11)),
              Text('2.5×',
                  style: TextStyle(
                      color: onCard.withValues(alpha: 0.28),
                      fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Preset chips ───────────────────────────────────────────────────────────

  Widget _buildPresetChips(BuildContext context, double speed) {
    final primary      = _primary(context);
    final onCard       = _onCard(context);
    final surfaceTint  = _surfaceTint(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRESETS',
          style: TextStyle(
            color: onCard.withValues(alpha: 0.3),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const Gap(10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presets.map((preset) {
            final isActive = (speed - preset.value).abs() < 0.01;
            return GestureDetector(
              onTap: () => _setSpeed(preset.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isActive ? primary : surfaceTint,
                  border: Border.all(
                    color: isActive
                        ? Colors.transparent
                        : onCard.withValues(alpha: 0.08),
                    width: 1,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            spreadRadius: -2,
                          )
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      preset.label,
                      style: TextStyle(
                        color: isActive
                            ? Theme.of(context).colorScheme.onPrimary
                            : onCard.withValues(alpha: 0.75),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      preset.description,
                      style: TextStyle(
                        color: isActive
                            ? Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withValues(alpha: 0.7)
                            : onCard.withValues(alpha: 0.3),
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Fine-tune buttons ──────────────────────────────────────────────────────

  Widget _buildFineTune(BuildContext context, double speed) {
    final onCard      = _onCard(context);
    final surfaceTint = _surfaceTint(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FINE TUNE',
          style: TextStyle(
            color: onCard.withValues(alpha: 0.3),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const Gap(10),
        Row(
          children: [
            Expanded(
              child: _FineTuneButton(
                label: '−0.05',
                sublabel: 'Slower',
                icon: Icons.remove_rounded,
                bgColor: surfaceTint,
                iconColor: onCard,
                onTap: speed > 0.26
                    ? () => _setSpeed(
                        ((speed - 0.05) * 20).round() / 20.0)
                    : null,
              ),
            ),
            const Gap(8),
            Expanded(
              child: _FineTuneButton(
                label: '−0.1',
                sublabel: 'Step back',
                icon: Icons.fast_rewind_rounded,
                bgColor: surfaceTint,
                iconColor: onCard,
                onTap: speed > 0.35
                    ? () => _setSpeed(
                        ((speed - 0.1) * 10).round() / 10.0)
                    : null,
              ),
            ),
            const Gap(8),
            Expanded(
              child: _FineTuneButton(
                label: '+0.1',
                sublabel: 'Step fwd',
                icon: Icons.fast_forward_rounded,
                bgColor: surfaceTint,
                iconColor: onCard,
                onTap: speed < 2.4
                    ? () => _setSpeed(
                        ((speed + 0.1) * 10).round() / 10.0)
                    : null,
              ),
            ),
            const Gap(8),
            Expanded(
              child: _FineTuneButton(
                label: '+0.05',
                sublabel: 'Faster',
                icon: Icons.add_rounded,
                bgColor: surfaceTint,
                iconColor: onCard,
                onTap: speed < 2.49
                    ? () => _setSpeed(
                        ((speed + 0.05) * 20).round() / 20.0)
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Speed context label ────────────────────────────────────────────────────

  String _speedLabel(double speed) {
    if (speed < 0.6)  return 'Very slow · careful listening';
    if (speed < 0.9)  return 'Slow · relaxed pace';
    if (speed < 1.1)  return 'Normal playback speed';
    if (speed < 1.4)  return 'Slightly faster';
    if (speed < 1.7)  return 'Fast · efficient listening';
    if (speed < 2.0)  return 'Very fast · power listening';
    return 'Maximum speed';
  }
}

// ─── Fine-tune button ─────────────────────────────────────────────────────────

class _FineTuneButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback? onTap;

  const _FineTuneButton({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.28,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: bgColor,
            border: Border.all(
              color: iconColor.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: iconColor.withValues(alpha: 0.65), size: 16),
              const Gap(2),
              Text(
                label,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                sublabel,
                style: TextStyle(
                  color: iconColor.withValues(alpha: 0.35),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Arc painter ──────────────────────────────────────────────────────────────

class _ArcPainter extends CustomPainter {
  final double speed;
  final Color trackColor;
  final Color primaryColor;

  const _ArcPainter({
    required this.speed,
    required this.trackColor,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.87);
    const radius     = 68.0;
    const startAngle = math.pi;
    const sweepTotal = math.pi;

    // Background track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc (speed 0.25 → 2.5 maps to 0 → 180°)
    final progress =
        ((speed - 0.25) / (2.5 - 0.25)).clamp(0.0, 1.0);
    final sweepAngle = sweepTotal * progress;

    if (sweepAngle > 0.01) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..shader = LinearGradient(
            colors: [
              primaryColor.withValues(alpha: 0.6),
              primaryColor,
            ],
          ).createShader(
              Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Thumb dot at arc tip
    final thumbAngle = startAngle + sweepAngle;
    final thumbPos = Offset(
      center.dx + radius * math.cos(thumbAngle),
      center.dy + radius * math.sin(thumbAngle),
    );

    // Glow ring
    canvas.drawCircle(
      thumbPos,
      9,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill,
    );
    // Solid dot
    canvas.drawCircle(
      thumbPos,
      5,
      Paint()..color = primaryColor,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.speed != speed || old.primaryColor != primaryColor;
}

// ─── Data class ───────────────────────────────────────────────────────────────

class _SpeedPreset {
  final double value;
  final String label;
  final String description;
  const _SpeedPreset(this.value, this.label, this.description);
}