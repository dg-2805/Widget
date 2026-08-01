import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NeedAHugScreen extends StatefulWidget {
  const NeedAHugScreen({super.key});

  @override
  State<NeedAHugScreen> createState() => _NeedAHugScreenState();
}

class _NeedAHugScreenState extends State<NeedAHugScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathingController;
  bool _hugged = false;
  int _messageIndex = 0;

  static const _messages = [
    "I'm here.",
    "We'll get through today.",
    "You don't have to carry everything alone.",
  ];

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  void _triggerHug() {
    HapticFeedback.mediumImpact();
    setState(() {
      _hugged = true;
      _messageIndex = (_messageIndex + 1) % _messages.length;
    });
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
                const Positioned.fill(
                  child: _HugOrbsBackground(),
                ),
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
                          child: _HugScene(hugged: _hugged),
                        ),
                        const SizedBox(height: 22),
                        AnimatedOpacity(
                          opacity: 1,
                          duration: const Duration(milliseconds: 450),
                          child: Text(
                            message,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: const Color(0xFF533232),
                              height: 1.35,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tap anywhere to hold the hug a little longer.',
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
                      child: AnimatedOpacity(
                        opacity: _hugged ? 1 : 0,
                        duration: const Duration(milliseconds: 350),
                        child: _HeartsBurst(),
                      ),
                    ),
                  ),
                // Pinterest Asset Needed
                // Purpose: Full-screen hugging panda illustration
                // Suggested Search: "soft watercolor panda hug warm glow"
                // Asset Path: assets/images/hugs/hug_scene.png
                // Aspect Ratio: 9:16
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HugScene extends StatelessWidget {
  const _HugScene({required this.hugged});

  final bool hugged;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: hugged ? 1.0 : 0.96,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PandaChip(label: 'Panda'),
          const SizedBox(width: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: hugged ? 26 : 20,
            height: hugged ? 26 : 20,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFF7C8A),
            ),
            child: const Icon(Icons.favorite_rounded, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 10),
          _PandaChip(label: 'Panda'),
        ],
      ),
    );
  }
}

class _PandaChip extends StatelessWidget {
  const _PandaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFFFFFFFF).withOpacity(0.95),
            const Color(0xFFF4D2C1).withOpacity(0.45),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB86A6A).withOpacity(0.18),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pets_outlined, size: 42, color: Color(0xFF4F3232)),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF5B3737),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeartsBurst extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(top: 120, left: 40, child: _FloatingHeart(delay: 0, offset: const Offset(-10, -120))),
        Positioned(top: 180, right: 56, child: _FloatingHeart(delay: 120, offset: const Offset(16, -140))),
        Positioned(bottom: 150, left: 88, child: _FloatingHeart(delay: 240, offset: const Offset(-6, -100))),
      ],
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
      child: const Icon(Icons.favorite_rounded, color: Color(0xFFFF5F88), size: 24),
    );
  }
}

class _HugOrbsBackground extends StatelessWidget {
  const _HugOrbsBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 30,
          left: -20,
          child: _SoftOrb(color: Color(0xFFFFC4B2), size: 130),
        ),
        Positioned(
          top: 120,
          right: -30,
          child: _SoftOrb(color: Color(0xFFFFE1CA), size: 170),
        ),
        Positioned(
          bottom: 90,
          left: 8,
          child: _SoftOrb(color: Color(0xFFFFD1CF), size: 110),
        ),
      ],
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
