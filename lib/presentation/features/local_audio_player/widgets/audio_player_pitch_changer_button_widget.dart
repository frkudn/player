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

class AudioPlayerPitchChangerButtonWidget extends StatelessWidget {
  const AudioPlayerPitchChangerButtonWidget({super.key});

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
            stream: state.audioPlayer.pitchStream,
            initialData: 1.0,
            builder: (context, snapshot) {
              final pitch = snapshot.data ?? 1.0;
              final isModified = (pitch - 1.0).abs() > 0.01;
          
              return GestureDetector(
                onTap: () {
                  context.pop();
                  _showPitchDialog(context);
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
                        color: isModified
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
                          pitch.toStringAsFixed(pitch == pitch.roundToDouble() ? 1 : 2),
                          style: TextStyle(
                            // color: isModified ? primary : onSurface,
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),
                    const Gap(4),
                    Text(
                      'Pitch',
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

  void _showPitchDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: BlocProvider.value(
          value: context.read<AudioPlayerBloc>(),
          child: const _PitchDialog(),
        ),
      ),
    );
  }
}

// ─── Main dialog ──────────────────────────────────────────────────────────────

class _PitchDialog extends StatelessWidget {
  const _PitchDialog();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AudioPlayerBloc, AudioPlayerState,
        AudioPlayerSuccessState?>(
      selector: (s) => s is AudioPlayerSuccessState ? s : null,
      builder: (context, state) {
        if (state == null) return nothing;
        return StreamBuilder<double>(
          stream: state.audioPlayer.pitchStream,
          initialData: 1.0,
          builder: (context, snapshot) {
            return _PitchDialogContent(pitch: snapshot.data ?? 1.0);
          },
        );
      },
    );
  }
}

// ─── Dialog content ───────────────────────────────────────────────────────────

class _PitchDialogContent extends StatefulWidget {
  final double pitch;
  const _PitchDialogContent({required this.pitch});

  @override
  State<_PitchDialogContent> createState() => _PitchDialogContentState();
}

class _PitchDialogContentState extends State<_PitchDialogContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Musical pitch presets — semitone labels mapped to multiplier values.
  // Pitch ratio per semitone = 2^(n/12)
  static const List<_PitchPreset> _presets = [
    _PitchPreset(0.7937, '−4st', 'Lower'),
    _PitchPreset(0.8909, '−2st', 'Low'),
    _PitchPreset(1.0,    '0st',  'Normal'),
    _PitchPreset(1.1225, '+2st', 'High'),
    _PitchPreset(1.2599, '+4st', 'Higher'),
    _PitchPreset(1.4983, '+8st', 'Alto'),
    _PitchPreset(2.0,    '+12', 'Octave'),
  ];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fadeAnim =
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  void _setPitch(double v) {
    HapticFeedback.selectionClick();
    context
        .read<AudioPlayerBloc>()
        .add(AudioPlayerChangePitchEvent(value: v));
    clog.debug('Pitch → $v');
  }

  // ── Theme helpers ──────────────────────────────────────────────────────────

  Color _cardBg(BuildContext context) {
    final scaffold = Theme.of(context).scaffoldBackgroundColor;
    if (scaffold == Colors.black) return const Color(0xFF0A0A0A);
    return Theme.of(context).colorScheme.surface;
  }

  Color _surfaceTint(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;

  Color _onCard(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  Color _primary(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  // ── Pitch helpers ──────────────────────────────────────────────────────────

  /// Convert pitch ratio → nearest semitone offset string
  String _pitchToSemitones(double pitch) {
    if ((pitch - 1.0).abs() < 0.01) return '0 semitones';
    final semitones = (12 * math.log(pitch) / math.log(2));
    final sign = semitones >= 0 ? '+' : '';
    return '$sign${semitones.toStringAsFixed(1)} st';
  }

  String _pitchLabel(double pitch) {
    if (pitch < 0.6)  return 'Very low · deep bass';
    if (pitch < 0.85) return 'Low · bass boost';
    if (pitch < 0.97) return 'Slightly lower pitch';
    if (pitch < 1.03) return 'Original pitch';
    if (pitch < 1.2)  return 'Slightly higher pitch';
    if (pitch < 1.5)  return 'High pitch · bright tone';
    if (pitch < 1.8)  return 'Very high · chipmunk effect';
    return 'Maximum pitch';
  }

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
                  _buildPitchVisualizer(context, widget.pitch),
                  const Gap(20),
                  _buildSlider(context, widget.pitch),
                  const Gap(18),
                  _buildPresetChips(context, widget.pitch),
                  const Gap(18),
                  _buildFineTune(context, widget.pitch),
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
    final primary   = _primary(context);
    final onCard    = _onCard(context);
    final isDefault = (widget.pitch - 1.0).abs() < 0.01;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary.withValues(alpha: 0.12),
          ),
          child: Icon(Icons.music_note_rounded, color: primary, size: 19),
        ),
        const Gap(12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pitch Control',
              style: TextStyle(
                color: onCard,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              _pitchLabel(widget.pitch),
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
          onTap: () => _setPitch(1.0),
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
                color:
                    isDefault ? primary : onCard.withValues(alpha: 0.45),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Pitch visualizer (waveform bars) ──────────────────────────────────────

  Widget _buildPitchVisualizer(BuildContext context, double pitch) {
    final primary = _primary(context);
    final onCard  = _onCard(context);

    return SizedBox(
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Waveform bar painter
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width - 84, 92),
            painter: _WaveformPainter(
              pitch: pitch,
              primaryColor: primary,
              trackColor: onCard.withValues(alpha: 0.08),
            ),
          ),
          // Central value display
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.pitch.toStringAsFixed(2),
                style: TextStyle(
                  color: onCard,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2,
                  height: 1,
                ),
              ),
              Text(
                _pitchToSemitones(widget.pitch),
                style: TextStyle(
                  color: primary.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Slider ─────────────────────────────────────────────────────────────────

  Widget _buildSlider(BuildContext context, double pitch) {
    final primary = _primary(context);
    final onCard  = _onCard(context);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

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
            thumbColor: onPrimary == Colors.white ? Colors.white : primary,
            overlayColor: primary.withValues(alpha: 0.15),
            valueIndicatorColor: primary,
            valueIndicatorTextStyle: TextStyle(
              color: onPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            showValueIndicator: ShowValueIndicator.onDrag,
          ),
          child: Slider(
            min: 0.5,
            max: 2.0,
            divisions: 60, // 0.025 steps
            value: pitch.clamp(0.5, 2.0),
            label: pitch.toStringAsFixed(2),
            onChanged: (v) {
              final rounded = (v * 40).round() / 40.0;
              _setPitch(rounded);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0.5  (−12st)',
                  style: TextStyle(
                      color: onCard.withValues(alpha: 0.28),
                      fontSize: 10)),
              Text('2.0  (+12st)',
                  style: TextStyle(
                      color: onCard.withValues(alpha: 0.28),
                      fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Preset chips ───────────────────────────────────────────────────────────

  Widget _buildPresetChips(BuildContext context, double pitch) {
    final primary     = _primary(context);
    final onCard      = _onCard(context);
    final surfaceTint = _surfaceTint(context);
    final onPrimary   = Theme.of(context).colorScheme.onPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MUSICAL PRESETS',
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
            final isActive = (pitch - preset.value).abs() < 0.015;
            return GestureDetector(
              onTap: () => _setPitch(preset.value),
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
                            ? onPrimary
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
                            ? onPrimary.withValues(alpha: 0.7)
                            : onCard.withValues(alpha: 0.3),
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
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

  Widget _buildFineTune(BuildContext context, double pitch) {
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
                label: '−1st',
                sublabel: 'Semitone',
                icon: Icons.arrow_downward_rounded,
                bgColor: surfaceTint,
                iconColor: onCard,
                onTap: pitch > 0.56
                    ? () => _setPitch(
                        (pitch / _semitoneRatio).clamp(0.5, 2.0))
                    : null,
              ),
            ),
            const Gap(8),
            Expanded(
              child: _FineTuneButton(
                label: '−0.05',
                sublabel: 'Fine',
                icon: Icons.remove_rounded,
                bgColor: surfaceTint,
                iconColor: onCard,
                onTap: pitch > 0.51
                    ? () => _setPitch(
                        ((pitch - 0.05) * 40).round() / 40.0)
                    : null,
              ),
            ),
            const Gap(8),
            Expanded(
              child: _FineTuneButton(
                label: '+0.05',
                sublabel: 'Fine',
                icon: Icons.add_rounded,
                bgColor: surfaceTint,
                iconColor: onCard,
                onTap: pitch < 1.99
                    ? () => _setPitch(
                        ((pitch + 0.05) * 40).round() / 40.0)
                    : null,
              ),
            ),
            const Gap(8),
            Expanded(
              child: _FineTuneButton(
                label: '+1st',
                sublabel: 'Semitone',
                icon: Icons.arrow_upward_rounded,
                bgColor: surfaceTint,
                iconColor: onCard,
                onTap: pitch < 1.89
                    ? () => _setPitch(
                        (pitch * _semitoneRatio).clamp(0.5, 2.0))
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 1 semitone up = multiply by 2^(1/12)
  static final double _semitoneRatio = math.pow(2, 1 / 12.0).toDouble();
}

// ─── Fine-tune button (shared component) ─────────────────────────────────────

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

// ─── Waveform painter ─────────────────────────────────────────────────────────

class _WaveformPainter extends CustomPainter {
  final double pitch;
  final Color primaryColor;
  final Color trackColor;

  const _WaveformPainter({
    required this.pitch,
    required this.primaryColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const barCount  = 28;
    final barWidth  = (size.width - (barCount - 1) * 3) / barCount;
    final centerY   = size.height / 2;

    // Pitch mapped to 0→1 for visual intensity
    final intensity = ((pitch - 0.5) / (2.0 - 0.5)).clamp(0.0, 1.0);

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + 3);

      // Sine wave height profile — bars in middle are tallest
      final normalized = i / (barCount - 1);
      final sinBase    = math.sin(normalized * math.pi);

      // Modulate height by pitch intensity + sine envelope
      final heightFactor = 0.15 + sinBase * 0.7 * intensity + 0.15 * sinBase;
      final barHeight    = (size.height * heightFactor).clamp(4.0, size.height);

      final isActive = normalized <= intensity;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x,
          centerY - barHeight / 2,
          barWidth,
          barHeight,
        ),
        const Radius.circular(3),
      );

      canvas.drawRRect(
        rect,
        Paint()
          ..color = isActive
              ? primaryColor.withValues(
                  alpha: 0.4 + 0.6 * (normalized / (intensity + 0.001)).clamp(0.0, 1.0))
              : trackColor,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.pitch != pitch || old.primaryColor != primaryColor;
}

// ─── Data class ───────────────────────────────────────────────────────────────

class _PitchPreset {
  final double value;
  final String label;
  final String description;
  const _PitchPreset(this.value, this.label, this.description);
}