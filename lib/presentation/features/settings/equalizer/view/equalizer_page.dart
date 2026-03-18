import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:open_player/presentation/features/local_audio_player/bloc/audio_player_bloc.dart';
import 'package:open_player/presentation/shared/widgets/custom_back_button.dart';

import '../../../../../data/services/equalizer/equalizer_services.dart';

class EqualizerPage extends StatefulWidget {
  const EqualizerPage({super.key});

  @override
  State<EqualizerPage> createState() => _EqualizerPageState();
}

class _EqualizerPageState extends State<EqualizerPage>
    with TickerProviderStateMixin {
  final _eq = EqualizerService();

  bool _initialized = false;
  bool _enabled = true;
  bool _loading = true;
  String? _error;

  int _numBands = 0;
  List<int> _bandLevels = [];
  List<String> _bandLabels = [];
  List<int> _levelRange = [-1500, 1500];

  int _numPresets = 0;
  List<String> _presetNames = [];
  int _selectedPreset = -1;

  int _bassBoost = 0;
  int _virtualizer = 0;

  late AnimationController _glowCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _dolbyCtrl;
  late Animation<double> _glowAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _dolbyAnim;

  static const Map<String, List<double>> _soundProfiles = {
    'Flat': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    'Movie': [2.0, 1.5, 0.0, -1.0, 1.5, 2.5],
    'Music': [1.5, 3.0, 1.0, 0.0, 2.0, 3.0],
    'Game': [3.0, 2.0, 0.5, 0.5, 2.0, 3.5],
    'Voice': [-1.0, 0.5, 3.0, 3.5, 2.0, 0.0],
    'Custom': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
  };
  String _activeProfile = 'Custom';

  @override
  void initState() {
    super.initState();

    _glowCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _dolbyCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);

    _glowAnim = Tween<double>(begin: 0.3, end: 0.8)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _dolbyAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _dolbyCtrl, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) => _initEqualizer());
  }

  Future<void> _initEqualizer() async {
    try {
      int sessionId = 0;

      // ── Get session ID from the singleton AudioPlayer ─────────────────
      // AudioPlayer is registered as a singleton in your locator (injection.dart)
      // so we can access it directly without needing the bloc state
      try {
        final blocState = context.read<AudioPlayerBloc>().state;
        if (blocState is AudioPlayerSuccessState) {
          sessionId = blocState.audioPlayer.androidAudioSessionId ?? 0;
        }
      } catch (_) {
        // No active player session — equalizer will still init with session 0
        // (affects all audio output, works as a global EQ)
        sessionId = 0;
      }

      final ok = await _eq.init(sessionId);
      if (!ok) {
        setState(() {
          _error = 'Equalizer not supported on this device.\n'
              'Some manufacturers disable audio effects.';
          _loading = false;
        });
        return;
      }

      final numBands = await _eq.getNumberOfBands();
      final levelRange = await _eq.getBandLevelRange();
      final numPresets = await _eq.getNumberOfPresets();

      final levels = <int>[];
      final labels = <String>[];
      final presets = <String>[];

      for (int i = 0; i < numBands; i++) {
        levels.add(await _eq.getBandLevel(i));
        final range = await _eq.getBandFreqRange(i);
        final centerHz = ((range[0] + range[1]) / 2).round();
        labels.add(_formatFreq(centerHz));
      }
      for (int i = 0; i < numPresets; i++) {
        presets.add(await _eq.getPresetName(i));
      }

      setState(() {
        _initialized = true;
        _loading = false;
        _numBands = numBands;
        _bandLevels = levels;
        _bandLabels = labels;
        _levelRange = levelRange;
        _numPresets = numPresets;
        _presetNames = presets;
      });
    } catch (e) {
      setState(() {
        _error = 'Equalizer not supported on this device.';
        _loading = false;
      });
    }
  }

  String _formatFreq(int hz) {
    if (hz >= 1000) {
      return '${(hz / 1000).toStringAsFixed(hz % 1000 == 0 ? 0 : 1)}k';
    }
    return '$hz';
  }

  Future<void> _setBandLevel(int band, int level) async {
    setState(() {
      _bandLevels[band] = level;
      _selectedPreset = -1;
      _activeProfile = 'Custom';
    });
    await _eq.setBandLevel(band, level);
    HapticFeedback.selectionClick();
  }

  Future<void> _applyPreset(int index) async {
    setState(() => _selectedPreset = index);
    await _eq.usePreset(index);
    for (int i = 0; i < _numBands; i++) {
      final lvl = await _eq.getBandLevel(i);
      setState(() => _bandLevels[i] = lvl);
    }
    HapticFeedback.mediumImpact();
  }

  Future<void> _applyProfile(String profile) async {
    setState(() {
      _activeProfile = profile;
      _selectedPreset = -1;
    });
    if (profile == 'Custom') return;

    final gains = _soundProfiles[profile]!;
    final range = _levelRange[1] - _levelRange[0];
    for (int i = 0; i < _numBands && i < gains.length; i++) {
      final level = (_levelRange[0] + ((gains[i] + 4) / 8) * range).round();
      await _eq.setBandLevel(i, level);
      setState(() => _bandLevels[i] = level);
    }
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _pulseCtrl.dispose();
    _dolbyCtrl.dispose();
    _eq.release();
    super.dispose();
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = cs.primary;
    final onSurface = cs.onSurface;
    final scaffold = Theme.of(context).scaffoldBackgroundColor;
    final bg = scaffold == Colors.black ? Colors.black : cs.surface;

    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(cs, primary, onSurface),
      body: _loading
          ? _buildLoading(primary, onSurface)
          : _error != null
              ? _buildError(onSurface, primary)
              : _buildBody(cs, primary, onSurface, bg),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(
      ColorScheme cs, Color primary, Color onSurface) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: const CustomBackButton(),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Equalizer',
            style: TextStyle(
              color: onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 20,
              letterSpacing: -0.5,
            ),
          ),
          const Gap(8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: LinearGradient(
                colors: [primary, primary.withValues(alpha: 0.7)],
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Text(
              'EQ',
              style: TextStyle(
                color: cs.onPrimary,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: _enabled ? primary : onSurface.withValues(alpha: 0.35),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
                child: Text(_enabled ? 'ON' : 'OFF'),
              ),
              const Gap(8),
              GestureDetector(
                onTap: () async {
                  HapticFeedback.selectionClick();
                  setState(() => _enabled = !_enabled);
                  await _eq.setEnabled(_enabled);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  width: 46,
                  height: 26,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    color:
                        _enabled ? primary : onSurface.withValues(alpha: 0.15),
                    boxShadow: _enabled
                        ? [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: -2,
                            )
                          ]
                        : null,
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    alignment:
                        _enabled ? Alignment.centerRight : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Loading ────────────────────────────────────────────────────────────────

  Widget _buildLoading(Color primary, Color onSurface) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: primary,
              strokeWidth: 2.5,
            ),
          ),
          const Gap(20),
          Text(
            'Initializing Equalizer...',
            style: TextStyle(
              color: onSurface.withValues(alpha: 0.5),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Error ──────────────────────────────────────────────────────────────────

  Widget _buildError(Color onSurface, Color primary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.equalizer_outlined,
                color: onSurface.withValues(alpha: 0.15), size: 72),
            const Gap(20),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.45),
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────

  Widget _buildBody(ColorScheme cs, Color primary, Color onSurface, Color bg) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Dolby Atmos — Coming Soon ─────────────────────────────
          _buildDolbyAtmosCard(cs, primary, onSurface),

          const Gap(28),

          // ── 2. Sound profiles ─────────────────────────────────────────
          _buildSectionLabel('Sound Profile', primary),
          const Gap(12),
          _buildProfiles(cs, primary, onSurface),

          const Gap(28),

          // ── 3. EQ bands ───────────────────────────────────────────────
          if (_numBands > 0) ...[
            _buildSectionLabel('Equalizer Bands', primary),
            const Gap(14),
            _buildEQCard(cs, primary, onSurface),
            const Gap(4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  for (int i = 0; i < _numBands; i++) {
                    await _eq.setBandLevel(i, 0);
                    setState(() => _bandLevels[i] = 0);
                  }
                  setState(() {
                    _activeProfile = 'Custom';
                    _selectedPreset = -1;
                  });
                  HapticFeedback.mediumImpact();
                },
                icon: Icon(Icons.refresh_rounded,
                    color: primary.withValues(alpha: 0.6), size: 15),
                label: Text(
                  'Reset all',
                  style: TextStyle(
                    color: primary.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const Gap(20),
          ],

          // ── 4. Bass Boost ─────────────────────────────────────────────
          _buildSectionLabel('Effects', primary),
          const Gap(14),
          _buildEffectTile(
            label: 'Bass Boost',
            sublabel: 'Enhance low frequencies',
            icon: Icons.graphic_eq_rounded,
            value: _bassBoost.toDouble(),
            max: 1000,
            primary: primary,
            onSurface: onSurface,
            cs: cs,
            displayValue: '${(_bassBoost / 10).round()}%',
            onChanged: (v) async {
              setState(() => _bassBoost = v.round());
              await _eq.setBassBoost(v.round());
            },
          ),

          const Gap(12),

          _buildEffectTile(
            label: 'Surround Sound',
            sublabel: 'Spatial audio experience',
            icon: Icons.surround_sound_rounded,
            value: _virtualizer.toDouble(),
            max: 1000,
            primary: primary,
            onSurface: onSurface,
            cs: cs,
            displayValue: '${(_virtualizer / 10).round()}%',
            onChanged: (v) async {
              setState(() => _virtualizer = v.round());
              await _eq.setVirtualizer(v.round());
            },
          ),

          // ── 5. Device presets ─────────────────────────────────────────
          if (_numPresets > 0) ...[
            const Gap(28),
            _buildSectionLabel('Device Presets', primary),
            const Gap(12),
            _buildDevicePresets(cs, primary, onSurface),
          ],
        ],
      ),
    );
  }

  // ── Dolby Atmos Card ───────────────────────────────────────────────────────

  Widget _buildDolbyAtmosCard(ColorScheme cs, Color primary, Color onSurface) {
    return AnimatedBuilder(
      animation: Listenable.merge([_dolbyAnim, _pulseAnim]),
      builder: (_, __) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0A0A0A),
                const Color(0xFF1A1A2E),
                Color.lerp(
                  const Color(0xFF1A1A2E),
                  primary.withValues(alpha: 0.3),
                  _dolbyAnim.value * 0.4,
                )!,
              ],
            ),
            border: Border.all(
              color: Color.lerp(
                Colors.white.withValues(alpha: 0.08),
                primary.withValues(alpha: 0.35),
                _dolbyAnim.value,
              )!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.15 + _dolbyAnim.value * 0.1),
                blurRadius: 32,
                spreadRadius: -6,
              ),
              BoxShadow(
                color: const Color(0xFF0A0A0A).withValues(alpha: 0.5),
                blurRadius: 16,
                spreadRadius: -4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Background sound wave pattern
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DolbyBgPainter(
                      progress: _dolbyAnim.value,
                      color: primary,
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Dolby logo-style badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  spreadRadius: -2,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Dolby-style "D" logo
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black,
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'D',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                                const Gap(6),
                                const Text(
                                  'DOLBY ATMOS',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // Coming soon pill
                          Transform.scale(
                            scale: _pulseAnim.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: primary.withValues(alpha: 0.2),
                                border: Border.all(
                                  color: primary.withValues(alpha: 0.5),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: primary,
                                      boxShadow: [
                                        BoxShadow(
                                          color: primary,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Gap(6),
                                  Text(
                                    'COMING SOON',
                                    style: TextStyle(
                                      color: primary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Gap(18),

                      const Text(
                        'Immersive 3D Sound',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      const Gap(6),
                      Text(
                        'Experience audio that moves around and above you\nwith true spatial sound technology.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),

                      const Gap(20),

                      // Feature chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          '🎬 Cinema Mode',
                          '🎵 Music Mode',
                          '🎮 Game Mode',
                          '🔊 3D Surround',
                        ]
                            .map((f) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white.withValues(alpha: 0.07),
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    f,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),

                      const Gap(18),

                      // Notify me button
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.notifications_active_rounded,
                                      color: primary, size: 18),
                                  const Gap(10),
                                  const Text(
                                    "You'll be notified when Dolby Atmos arrives!",
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              colors: [
                                primary,
                                primary.withValues(alpha: 0.75),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.4),
                                blurRadius: 16,
                                spreadRadius: -4,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.notifications_none_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              const Gap(8),
                              const Text(
                                'Notify me when available',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Sound profiles ─────────────────────────────────────────────────────────

  Widget _buildProfiles(ColorScheme cs, Color primary, Color onSurface) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _soundProfiles.keys.map((profile) {
          final isActive = _activeProfile == profile;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => _applyProfile(profile),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: isActive
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [primary, primary.withValues(alpha: 0.7)],
                        )
                      : null,
                  color: isActive ? null : cs.surfaceContainerHighest,
                  border: Border.all(
                    color: isActive
                        ? Colors.transparent
                        : onSurface.withValues(alpha: 0.07),
                    width: 1,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.38),
                            blurRadius: 16,
                            spreadRadius: -4,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Icon(
                      _profileIcon(profile),
                      color: isActive
                          ? cs.onPrimary
                          : onSurface.withValues(alpha: 0.45),
                      size: 22,
                    ),
                    const Gap(5),
                    Text(
                      profile,
                      style: TextStyle(
                        color: isActive
                            ? cs.onPrimary
                            : onSurface.withValues(alpha: 0.65),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _profileIcon(String p) {
    switch (p) {
      case 'Flat':
        return Icons.horizontal_rule_rounded;
      case 'Movie':
        return Icons.movie_outlined;
      case 'Music':
        return Icons.music_note_rounded;
      case 'Game':
        return Icons.sports_esports_outlined;
      case 'Voice':
        return Icons.mic_outlined;
      default:
        return Icons.tune_rounded;
    }
  }

  // ── EQ card ────────────────────────────────────────────────────────────────

  Widget _buildEQCard(ColorScheme cs, Color primary, Color onSurface) {
    final minLevel = _levelRange[0].toDouble();
    final maxLevel = _levelRange[1].toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: cs.surfaceContainerHighest,
        border: Border.all(color: onSurface.withValues(alpha: 0.06), width: 1),
      ),
      child: Column(
        children: [
          // Curve visualizer
          SizedBox(
            height: 64,
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, __) => CustomPaint(
                size: const Size(double.infinity, 64),
                painter: _EQCurvePainter(
                  levels: _bandLevels,
                  minLevel: minLevel,
                  maxLevel: maxLevel,
                  color: primary,
                  glow: _glowAnim.value,
                ),
              ),
            ),
          ),

          const Gap(20),

          // Vertical band sliders
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(_numBands, (i) {
                return _BandSlider(
                  label: _bandLabels.length > i ? _bandLabels[i] : '$i',
                  value:
                      _bandLevels.length > i ? _bandLevels[i].toDouble() : 0.0,
                  min: minLevel,
                  max: maxLevel,
                  primary: primary,
                  onSurface: onSurface,
                  onChanged: (v) => _setBandLevel(i, v.round()),
                );
              }),
            ),
          ),

          const Gap(12),

          // Scale
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(minLevel / 100).round()} dB',
                  style: TextStyle(
                      color: onSurface.withValues(alpha: 0.25), fontSize: 10)),
              Text('0 dB',
                  style: TextStyle(
                      color: onSurface.withValues(alpha: 0.25), fontSize: 10)),
              Text('+${(maxLevel / 100).round()} dB',
                  style: TextStyle(
                      color: onSurface.withValues(alpha: 0.25), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Effect tile ────────────────────────────────────────────────────────────

  Widget _buildEffectTile({
    required String label,
    required String sublabel,
    required IconData icon,
    required double value,
    required double max,
    required Color primary,
    required Color onSurface,
    required ColorScheme cs,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: cs.surfaceContainerHighest,
        border: Border.all(color: onSurface.withValues(alpha: 0.06), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: 0.12),
                ),
                child: Icon(icon, color: primary, size: 18),
              ),
              const Gap(12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.38),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: primary.withValues(alpha: 0.1),
                  border: Border.all(
                      color: primary.withValues(alpha: 0.2), width: 1),
                ),
                child: Text(
                  displayValue,
                  style: TextStyle(
                    color: primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: primary,
              inactiveTrackColor: onSurface.withValues(alpha: 0.1),
              thumbColor: Colors.white,
              overlayColor: primary.withValues(alpha: 0.12),
            ),
            child: Slider(
              value: value.clamp(0, max),
              min: 0,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  // ── Device presets ─────────────────────────────────────────────────────────

  Widget _buildDevicePresets(ColorScheme cs, Color primary, Color onSurface) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_numPresets, (i) {
        final isActive = _selectedPreset == i;
        return GestureDetector(
          onTap: () => _applyPreset(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isActive ? primary : cs.surfaceContainerHighest,
              border: Border.all(
                color: isActive
                    ? Colors.transparent
                    : onSurface.withValues(alpha: 0.08),
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: -3,
                      )
                    ]
                  : null,
            ),
            child: Text(
              _presetNames[i],
              style: TextStyle(
                color:
                    isActive ? cs.onPrimary : onSurface.withValues(alpha: 0.65),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Section label ──────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label, Color primary) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Gap(8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: primary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

// ── Band slider ────────────────────────────────────────────────────────────────

class _BandSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final Color primary;
  final Color onSurface;
  final ValueChanged<double> onChanged;

  const _BandSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.primary,
    required this.onSurface,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final db = (value / 100).round();
    final dbStr = db >= 0 ? '+$db' : '$db';

    return Expanded(
      child: Column(
        children: [
          Text(
            dbStr,
            style: TextStyle(
              color: value.abs() > (max.abs() * 0.08)
                  ? primary
                  : onSurface.withValues(alpha: 0.3),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(4),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: primary,
                inactiveTrackColor: onSurface.withValues(alpha: 0.1),
                thumbColor: Colors.white,
                overlayColor: primary.withValues(alpha: 0.12),
              ),
              child: RotatedBox(
                quarterTurns: -1,
                child: Slider(
                  value: value.clamp(min, max),
                  min: min,
                  max: max,
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
          const Gap(4),
          Text(
            label,
            style: TextStyle(
              color: onSurface.withValues(alpha: 0.4),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── EQ curve painter ───────────────────────────────────────────────────────────

class _EQCurvePainter extends CustomPainter {
  final List<int> levels;
  final double minLevel;
  final double maxLevel;
  final Color color;
  final double glow;

  const _EQCurvePainter({
    required this.levels,
    required this.minLevel,
    required this.maxLevel,
    required this.color,
    required this.glow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.isEmpty) return;
    final range = maxLevel - minLevel;
    final points = <Offset>[];

    for (int i = 0; i < levels.length; i++) {
      final x = i == 0
          ? 0.0
          : i == levels.length - 1
              ? size.width
              : size.width * i / (levels.length - 1);
      final normalized = (levels[i] - minLevel) / range;
      final y = size.height - (normalized * size.height);
      points.add(Offset(x, y));
    }

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final cp1 = Offset((points[i].dx + points[i + 1].dx) / 2, points[i].dy);
      final cp2 =
          Offset((points[i].dx + points[i + 1].dx) / 2, points[i + 1].dy);
      path.cubicTo(
          cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i + 1].dx, points[i + 1].dy);
    }

    // Glow
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: glow * 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Line
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Fill
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Zero line
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_EQCurvePainter old) =>
      old.levels != levels || old.glow != glow;
}

// ── Dolby background painter ───────────────────────────────────────────────────

class _DolbyBgPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _DolbyBgPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Concentric arc rings like Dolby Atmos branding
    final center = Offset(size.width * 0.85, size.height * 0.5);
    for (int i = 1; i <= 5; i++) {
      final radius = i * 28.0 + progress * 8;
      final alpha = (0.04 + (5 - i) * 0.015) * (0.5 + progress * 0.5);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi * 0.6,
        math.pi * 1.2,
        false,
        Paint()
          ..color = color.withValues(alpha: alpha.clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_DolbyBgPainter old) => old.progress != progress;
}
