import 'dart:math' as math;
import 'package:flutter/material.dart';

class OnlineSectionPage extends StatefulWidget {
  const OnlineSectionPage({super.key});

  @override
  State<OnlineSectionPage> createState() => _OnlineSectionPageState();
}

class _OnlineSectionPageState extends State<OnlineSectionPage>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _orbitCtrl;
  late final AnimationController _fadeCtrl;

  late final Animation<double> _pulse;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _pulse = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _orbitCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFF080B14),
      body: Stack(
        children: [
          // ── Ambient background orbs ────────────────────────────────────
          AnimatedBuilder(
            animation: _orbitCtrl,
            builder: (_, __) {
              final t = _orbitCtrl.value * 2 * math.pi;
              return Stack(
                children: [
                  // Deep blue orb — slow drift top-left
                  Positioned(
                    left: size.width * 0.1 + math.sin(t * 0.7) * 30,
                    top: size.height * 0.12 + math.cos(t * 0.5) * 20,
                    child: _Orb(
                      radius: 160,
                      color: const Color(0xFF1A3A6B).withOpacity(0.55),
                    ),
                  ),
                  // Teal orb — counter-drift bottom-right
                  Positioned(
                    right: size.width * 0.05 + math.cos(t * 0.6) * 25,
                    bottom: size.height * 0.18 + math.sin(t * 0.4) * 30,
                    child: _Orb(
                      radius: 200,
                      color: const Color(0xFF0D3D4A).withOpacity(0.50),
                    ),
                  ),
                  // Accent cyan — small, fast pulse center-right
                  Positioned(
                    right: size.width * 0.15 + math.sin(t * 1.1) * 15,
                    top: size.height * 0.38 + math.cos(t * 0.9) * 18,
                    child: _Orb(
                      radius: 80,
                      color: const Color(0xFF00C4CC).withOpacity(0.18),
                    ),
                  ),
                ],
              );
            },
          ),

          // ── Subtle grid lines ──────────────────────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),

          // ── Main content ───────────────────────────────────────────────
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated signal icon
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) {
                      return SizedBox(
                        width: 120,
                        height: 120,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer ring pulse
                            _PulseRing(
                              scale: 1.0 + _pulse.value * 0.35,
                              opacity: (1.0 - _pulse.value) * 0.35,
                              size: 110,
                              color: const Color(0xFF00C4CC),
                            ),
                            // Middle ring
                            _PulseRing(
                              scale: 1.0 + _pulse.value * 0.18,
                              opacity: (1.0 - _pulse.value * 0.5) * 0.5,
                              size: 88,
                              color: const Color(0xFF00C4CC),
                            ),
                            // Core icon container
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF1B4FD8),
                                    Color(0xFF00C4CC),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00C4CC)
                                        .withOpacity(0.35),
                                    blurRadius: 28,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.wifi_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // "ONLINE MUSIC" label
                  const Text(
                    'ONLINE  MUSIC',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF00C4CC),
                      letterSpacing: 6,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Headline
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFE8F0FF), Color(0xFF8AB4F8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: const Text(
                      'Coming\nSoon',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 52,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Sub-message
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 44),
                    child: Text(
                      "We're building your online music experience.\nStreaming, discovery & more — in a future update.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.65,
                        color: Colors.white.withOpacity(0.45),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 44),

                  // Feature chips
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: const [
                      _FeatureChip(
                          icon: Icons.stream_rounded, label: 'Streaming'),
                      _FeatureChip(
                          icon: Icons.explore_rounded, label: 'Discovery'),
                      _FeatureChip(
                          icon: Icons.playlist_play, label: 'Playlists'),
                      _FeatureChip(
                          icon: Icons.download_rounded, label: 'Downloads'),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // Divider line
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 1,
                        color: Colors.white.withOpacity(0.12),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'Stay tuned for updates',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.28),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 1,
                        color: Colors.white.withOpacity(0.12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Supporting Widgets ────────────────────────────────────────────────────

class _Orb extends StatelessWidget {
  const _Orb({required this.radius, required this.color});
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  const _PulseRing({
    required this.scale,
    required this.opacity,
    required this.size,
    required this.color,
  });
  final double scale;
  final double opacity;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withOpacity(opacity),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF00C4CC)),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.white.withOpacity(0.55),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Grid background painter ───────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.028)
      ..strokeWidth = 0.8;

    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}
