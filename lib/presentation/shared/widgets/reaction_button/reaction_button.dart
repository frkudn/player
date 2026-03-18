import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ReactionButton extends StatefulWidget {
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap; // The callback to be triggered on tap
  final bool liked; // Initial state for liking
  final List<Color> bubbleColors;

  const ReactionButton({
    super.key,
    this.size = 30,
    required this.onTap, // The callback on tap
    required this.liked, // Initial liked state
    this.activeColor = const Color(0xFFFF5252),
    this.inactiveColor = Colors.grey,
    this.bubbleColors = const [
      Color(0xFFFF5252),
      Color(0xFFFF7B7B),
      Color(0xFFFF9D9D),
      Color(0xFFFFB8B8),
    ],
  });

  @override
  _ReactionButtonState createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<ReactionButton>
    with TickerProviderStateMixin {
  late AnimationController _bubblesController;
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();

    _bubblesController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _bubblesController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  // Generate bubbles when the heart is liked
  List<_BubbleData> _generateInitialBubbles() {
    final random = math.Random();
    return List.generate(10, (index) {
      final speed = 0.3 + random.nextDouble() * 0.3; // Smaller speed
      final angle = index * (math.pi * 2 / 10) + random.nextDouble() * 0.4;
      return _BubbleData(
        angle: angle,
        speed: speed,
        scale: 0.8 + random.nextDouble() * 0.2, // Smaller bubbles
        opacity: 0.5 + random.nextDouble() * 0.5, // More transparent
        color: widget.bubbleColors[random.nextInt(widget.bubbleColors.length)],
      );
    });
  }

  // Handle the heart like and bubble animation
  void _onTap() {
    setState(() {});

    // Trigger external onTap callback
    widget.onTap();

    if (widget.liked) {
      // Start bubble animation when liked
      _bubblesController.forward(from: 0);
    }

    // Handle scale animation
    _scaleController.forward(from: 0).then((_) {
      _scaleController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeInOut,
      ),
    );

    final bubbles = widget.liked ? _generateInitialBubbles() : [];

    return GestureDetector(
      onTap: _onTap,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (widget.liked) // Show bubbles only when liked
              AnimatedBuilder(
                animation: _bubblesController,
                builder: (context, _) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: bubbles.map((bubble) {
                      final progress = _bubblesController.value;
                      final moveProgress =
                          Curves.easeOutExpo.transform(progress);
                      final scaleProgress = 1 - (progress * 0.5);
                      final distance =
                          widget.size * 3 * moveProgress * bubble.speed;
                      final offset = Offset(
                        math.cos(bubble.angle) * distance,
                        math.sin(bubble.angle) * distance - (distance * 0.3),
                      );

                      return Positioned(
                        left: widget.size / 2,
                        top: widget.size / 2,
                        child: Transform.translate(
                          offset: offset,
                          child: Transform.scale(
                            scale: bubble.scale * scaleProgress,
                            child: Opacity(
                              opacity: (1 - progress) * bubble.opacity,
                              child: _buildBubble(bubble.color),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            Transform.scale(
              scale: scaleAnimation.value,
              child: Stack(
                children: [
                  Icon(
                    widget.liked
                        ? CupertinoIcons.heart_fill
                        : CupertinoIcons.heart,
                    size: widget.size,
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      widget.liked
                          ? CupertinoIcons.heart_fill
                          : CupertinoIcons.heart,
                      key: ValueKey(widget.liked),
                      size: widget.size,
                      color: widget.liked
                          ? widget.activeColor
                          : widget.inactiveColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(Color color) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _BubbleData {
  final double angle;
  final double speed;
  final double scale;
  final double opacity;
  final Color color;

  const _BubbleData({
    required this.angle,
    required this.speed,
    required this.scale,
    required this.opacity,
    required this.color,
  });
}
