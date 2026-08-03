import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../providers/app_state.dart';

class NeedAHugScreen extends StatefulWidget {
  const NeedAHugScreen({super.key});

  @override
  State<NeedAHugScreen> createState() => _NeedAHugScreenState();
}

class _NeedAHugScreenState extends State<NeedAHugScreen>
    with TickerProviderStateMixin {
  late final AnimationController _breathingController;
  late final AnimationController _hugController;
  bool _hugged = false;
  int _messageIndex = 0;
  int _burstKey = 0;

  static const _messages = [
    "I'm here.",
    "We'll get through today.",
    "You don't have to carry everything alone.",
    "Sent. They'll feel this one.",
    "Held, even from far away.",
  ];

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    // Drives the two pandas sliding together + the glow ring pulse.
    _hugController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _hugController.dispose();
    super.dispose();
  }

  Future<void> _triggerHug() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _hugged = true;
      _messageIndex = (_messageIndex + 1) % _messages.length;
      _burstKey++;
    });

    await _hugController.forward(from: 0);

    // Actually notify the partner — this is the part that was missing.
    // ignore: use_build_context_synchronously
    context.read<AppState>().sendHug();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = _messages[_messageIndex];

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _triggerHug,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFD7C4), Color(0xFFFFF4EA), Color(0xFFFFC6B6)],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                const Positioned.fill(child: _DriftingOrbsBackground()),
                Center(
                  child: AnimatedBuilder(
                    animation: _breathingController,
                    builder: (context, child) {
                      final scale = 0.96 + (_breathingController.value * 0.06);
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Need a Hug',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.0,
                            color: const Color(0xFF3D2424),
                          ),
                        ),
                        const SizedBox(height: 28),
                        RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: _hugController,
                            builder: (context, _) => _HugScene(
                              hugProgress: _hugController.value,
                              hugged: _hugged,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: Text(
                            message,
                            key: ValueKey(message),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: const Color(0xFF533232),
                              height: 1.35,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tap anywhere to send one.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF5F3E3E).withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_hugged)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _HeartsBurst(key: ValueKey(_burstKey)),
                    ),
                  ),
                if (_hugged)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _GlowRing(key: ValueKey('ring$_burstKey')),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Two illustrated pandas that slide toward each other and overlap
/// when a hug is sent, with a small heart pulsing between them.
class _HugScene extends StatelessWidget {
  const _HugScene({required this.hugProgress, required this.hugged});

  final double hugProgress; // 0 -> 1 over the hug animation
  final bool hugged;

  @override
  Widget build(BuildContext context) {
    // Pandas start apart, slide together, and settle slightly overlapped.
    final separation = 34 * (1 - hugProgress);

    return SizedBox(
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: Offset(-separation, 0),
            child: const _Panda(label: 'Shimi', flip: false),
          ),
          Transform.translate(
            offset: Offset(separation, 0),
            child: const _Panda(label: 'Rik', flip: true),
          ),
          Transform.scale(
            scale: 0.9 + (hugProgress * 0.5),
            child: Opacity(
              opacity: hugged ? 1 : 0.7,
              child: const Icon(
                Icons.favorite_rounded,
                size: 26,
                color: Color(0xFFFF7C8A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panda extends StatelessWidget {
  const _Panda({required this.label, required this.flip});

  final String label;
  final bool flip;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.flip(
          flipX: flip,
          child: SizedBox(
            width: 108,
            height: 100,
            child: CustomPaint(painter: _PandaFacePainter()),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: const Color(0xFF5B3737),
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

/// Simple, soft, hand-drawn-style panda face — ears, eye patches, blush.
class _PandaFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 6);
    final faceRadius = size.width * 0.34;

    final shadow = Paint()..color = const Color(0x22B86A6A);
    canvas.drawCircle(center.translate(0, 6), faceRadius + 4, shadow);

    final white = Paint()..color = Colors.white;
    final black = Paint()..color = const Color(0xFF3A2E2E);
    final blush = Paint()..color = const Color(0xFFFFB3AE).withOpacity(0.55);

    // Ears
    canvas.drawCircle(center.translate(-faceRadius * 0.85, -faceRadius * 0.85), faceRadius * 0.42, black);
    canvas.drawCircle(center.translate(faceRadius * 0.85, -faceRadius * 0.85), faceRadius * 0.42, black);

    // Face
    canvas.drawCircle(center, faceRadius, white);

    // Eye patches
    canvas.save();
    canvas.translate(center.dx - faceRadius * 0.4, center.dy - faceRadius * 0.12);
    canvas.rotate(-0.35);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: faceRadius * 0.62, height: faceRadius * 0.82), black);
    canvas.restore();

    canvas.save();
    canvas.translate(center.dx + faceRadius * 0.4, center.dy - faceRadius * 0.12);
    canvas.rotate(0.35);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: faceRadius * 0.62, height: faceRadius * 0.82), black);
    canvas.restore();

    // Eyes (small white glint + black pupil)
    final eyeOffsetX = faceRadius * 0.4;
    final eyeY = center.dy - faceRadius * 0.1;
    canvas.drawCircle(Offset(center.dx - eyeOffsetX, eyeY), faceRadius * 0.1, white);
    canvas.drawCircle(Offset(center.dx + eyeOffsetX, eyeY), faceRadius * 0.1, white);
    canvas.drawCircle(Offset(center.dx - eyeOffsetX, eyeY + 1), faceRadius * 0.06, black);
    canvas.drawCircle(Offset(center.dx + eyeOffsetX, eyeY + 1), faceRadius * 0.06, black);

    // Blush
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - faceRadius * 0.55, center.dy + faceRadius * 0.35),
        width: faceRadius * 0.38,
        height: faceRadius * 0.22,
      ),
      blush,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + faceRadius * 0.55, center.dy + faceRadius * 0.35),
        width: faceRadius * 0.38,
        height: faceRadius * 0.22,
      ),
      blush,
    );

    // Nose + smile
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy + faceRadius * 0.28), width: faceRadius * 0.16, height: faceRadius * 0.1),
      black,
    );
    final smile = Paint()
      ..color = const Color(0xFF3A2E2E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(center.dx, center.dy + faceRadius * 0.35)
      ..quadraticBezierTo(
        center.dx - faceRadius * 0.22,
        center.dy + faceRadius * 0.55,
        center.dx - faceRadius * 0.4,
        center.dy + faceRadius * 0.42,
      );
    final path2 = Path()
      ..moveTo(center.dx, center.dy + faceRadius * 0.35)
      ..quadraticBezierTo(
        center.dx + faceRadius * 0.22,
        center.dy + faceRadius * 0.55,
        center.dx + faceRadius * 0.4,
        center.dy + faceRadius * 0.42,
      );
    canvas.drawPath(path, smile);
    canvas.drawPath(path2, smile);
  }

  @override
  bool shouldRepaint(covariant _PandaFacePainter oldDelegate) => false;
}

/// Expanding, fading ring from the center — the "pulse" of a sent hug.
class _GlowRing extends StatelessWidget {
  const _GlowRing({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Center(
          child: Container(
            width: 60 + (value * 320),
            height: 60 + (value * 320),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFF7C8A).withOpacity((1 - value) * 0.6),
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeartsBurst extends StatelessWidget {
  const _HeartsBurst({super.key});

  @override
  Widget build(BuildContext context) {
    final rand = Random(DateTime.now().millisecondsSinceEpoch);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: List.generate(7, (i) {
            final dx = (rand.nextDouble() - 0.5) * constraints.maxWidth * 0.6;
            final startY = constraints.maxHeight * (0.45 + rand.nextDouble() * 0.15);
            return Positioned(
              left: constraints.maxWidth / 2 + dx,
              top: startY,
              child: _FloatingHeart(
                delay: i * 70,
                offset: Offset((rand.nextDouble() - 0.5) * 40, -100 - rand.nextDouble() * 60),
              ),
            );
          }),
        );
      },
    );
  }
}

class _FloatingHeart extends StatelessWidget {
  const _FloatingHeart({required this.delay, required this.offset});

  final int delay;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 1200 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: (1 - value).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(offset.dx * value, offset.dy * value),
          child: Transform.scale(scale: 0.8 + (value * 0.35), child: child),
        ),
      ),
      child: const Icon(Icons.favorite_rounded, color: Color(0xFFFF5F88), size: 22),
    );
  }
}

/// Same soft orbs as before, but now gently drifting instead of static.
class _DriftingOrbsBackground extends StatefulWidget {
  const _DriftingOrbsBackground();

  @override
  State<_DriftingOrbsBackground> createState() => _DriftingOrbsBackgroundState();
}

class _DriftingOrbsBackgroundState extends State<_DriftingOrbsBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * 2 * pi;
        return Stack(
          children: [
            Positioned(
              top: 30 + sin(t) * 12,
              left: -20 + cos(t) * 10,
              child: const _SoftOrb(color: Color(0xFFFFC4B2), size: 130),
            ),
            Positioned(
              top: 120 + cos(t * 0.8) * 14,
              right: -30 + sin(t * 0.8) * 10,
              child: const _SoftOrb(color: Color(0xFFFFE1CA), size: 170),
            ),
            Positioned(
              bottom: 90 + sin(t * 1.2) * 10,
              left: 8 + cos(t * 1.2) * 8,
              child: const _SoftOrb(color: Color(0xFFFFD1CF), size: 110),
            ),
          ],
        );
      },
    );
  }
}

class _SoftOrb extends StatelessWidget {
  const _SoftOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.45),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.18),
            blurRadius: 50,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }
}