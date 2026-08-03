import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/widgets/cute_widgets.dart';
import './data/affirmations.dart';

class EyesScreen extends StatefulWidget {
  const EyesScreen({super.key});

  @override
  State<EyesScreen> createState() => _EyesScreenState();
}

class _EyesScreenState extends State<EyesScreen> {
  final _rand = Random();
  int? _currentIndex;
  int _revealKey = 0; // bumps to re-trigger the entrance animation each tap

  void _revealRandom() {
    if (affirmations.length <= 1) {
      setState(() {
        _currentIndex = 0;
        _revealKey++;
      });
      return;
    }
    int next;
    do {
      next = _rand.nextInt(affirmations.length);
    } while (next == _currentIndex);

    setState(() {
      _currentIndex = next;
      _revealKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRevealed = _currentIndex != null;

    // Transparent scaffold — this screen sits directly on top of
    // whichever background wrapper (FlowerBackground / ConstellationBackground
    // / DreamyBackground) the app is already using, same pattern as
    // home_screen.dart, notes_screen.dart, etc.
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('cute reminders :) '),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: hasRevealed
                      ? _AffirmationCard(
                          key: ValueKey(_revealKey),
                          text: affirmations[_currentIndex!],
                        )
                      : Text(
                          'Tap the heart whenever\nyou need reminding.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              _HeartButton(onTap: _revealRandom),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _AffirmationCard extends StatelessWidget {
  final String text;
  const _AffirmationCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = text.split('\n');

    return CuteCard(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite,
            size: 22,
            color: theme.colorScheme.primary.withOpacity(0.8),
          ),
          const SizedBox(height: 16),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                line,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 380.ms, curve: Curves.easeOut)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          duration: 380.ms,
          curve: Curves.easeOutBack,
        );
  }
}

class _HeartButton extends StatefulWidget {
  final VoidCallback onTap;
  const _HeartButton({required this.onTap});

  @override
  State<_HeartButton> createState() => _HeartButtonState();
}

class _HeartButtonState extends State<_HeartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      lowerBound: 0.0,
      upperBound: 0.15,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _controller.forward();
    await _controller.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1 - _controller.value;
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.75),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.favorite, color: Colors.white, size: 34)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                duration: 1400.ms,
                begin: const Offset(1, 1),
                end: const Offset(1.1, 1.1),
              ),
        ),
      ),
    );
  }
}