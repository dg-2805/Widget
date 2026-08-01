import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/cute_widgets.dart';
import '../../../providers/app_state.dart';
import '../../eyes/presentation/eyes_screen.dart';
import '../../hug/presentation/need_a_hug_screen.dart';
import '../../open_when/presentation/open_when_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final twilight = state.twilight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [twilight.backgroundTop, twilight.backgroundBottom],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            children: [
              _Header(twilight: twilight),
              const SizedBox(height: 14),
              RepaintBoundary(
                child: _TwilightCalendarCard(
                  twilight: twilight,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NeedAHugScreen()),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _PandaCompanionCard(twilight: twilight),
              const SizedBox(height: 14),
              _TinySurpriseCard(twilight: twilight),
              const SizedBox(height: 18),
              _RouteGrid(
                onEyesTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EyesScreen()),
                ),
                onOpenWhenTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OpenWhenScreen()),
                ),
                onHugTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NeedAHugScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.twilight});

  final dynamic twilight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Twilights Together',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedOpacity(
          opacity: 1,
          duration: const Duration(milliseconds: 450),
          child: Text(
            twilight.comfortMessage,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.72),
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _TwilightCalendarCard extends StatelessWidget {
  const _TwilightCalendarCard({required this.twilight, required this.onTap});

  final dynamic twilight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CuteCard(
      onTap: onTap,
      padding: const EdgeInsets.all(0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface.withOpacity(0.98),
              twilight.surfaceColor.withOpacity(0.94),
            ],
          ),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 4,
              top: 2,
              child: TweenAnimationBuilder<double>(
                key: ValueKey(twilight.twilightsTogether),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Opacity(
                  opacity: 1 - value,
                  child: Transform.translate(
                    offset: Offset(-22 * value, 26 * value),
                    child: child,
                  ),
                ),
                child: Icon(Icons.auto_awesome, color: twilight.glowColor, size: 20),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Twilight Calendar',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.68),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 14),
                TweenAnimationBuilder<double>(
                  key: ValueKey(twilight.twilightsTogether),
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 680),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    final flip = (1 - value) * pi / 12;
                    return Opacity(
                      opacity: 0.4 + (value * 0.6),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateX(flip),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    twilight.twilightsTogether.toString(),
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -4,
                      height: 0.95,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedOpacity(
                  opacity: 1,
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    twilight.subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.65),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _PhaseTag(twilight: twilight),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PhaseTag extends StatelessWidget {
  const _PhaseTag({required this.twilight});

  final dynamic twilight;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: twilight.accentColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          twilight.phaseName,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: twilight.accentColor,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _PandaCompanionCard extends StatelessWidget {
  const _PandaCompanionCard({required this.twilight});

  final dynamic twilight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = switch (twilight.pandaMood.toString().split('.').last) {
      'stretching' => Icons.self_improvement,
      'reading' => Icons.menu_book,
      'sunset' => Icons.wb_sunny_outlined,
      'sleeping' => Icons.bedtime_outlined,
      _ => Icons.star_rounded,
    };

    return CuteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current panda',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      twilight.pandaLabel,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      twilight.isCharging
                          ? 'Battery only changes the panda, never the theme.'
                          : 'The theme stays rooted in the time of day.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _PandaOrb(icon: icon, color: twilight.accentColor),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 450),
            child: Text(
              twilight.isCharging
                  ? 'Charging with ${twilight.batteryLevel}% battery'
                  : '${twilight.batteryLevel}% battery',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.58),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PandaOrb extends StatelessWidget {
  const _PandaOrb({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.30), color.withOpacity(0.05)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: 44, color: color.withOpacity(0.92)),
          // Pinterest Asset Needed
          // Purpose: Panda companion illustration for the home screen
          // Suggested Search: "soft watercolor panda companion"
          // Asset Path: assets/images/panda/home_panda.png
          // Aspect Ratio: 1:1
        ],
      ),
    );
  }
}

class _TinySurpriseCard extends StatelessWidget {
  const _TinySurpriseCard({required this.twilight});

  final dynamic twilight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surpriseIndex = twilight.twilightsTogether % 3;
    final surpriseIcon = switch (surpriseIndex) {
      0 => Icons.auto_awesome,
      1 => Icons.waving_hand_outlined,
      _ => Icons.local_florist_outlined,
    };
    final surpriseText = switch (surpriseIndex) {
      0 => 'A shooting star drifts through the sky.',
      1 => 'The panda gives a tiny wave.',
      _ => 'A flower quietly blooms nearby.',
    };

    return CuteCard(
      child: Row(
        children: [
          Icon(surpriseIcon, color: twilight.accentColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              surpriseText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.75),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteGrid extends StatelessWidget {
  const _RouteGrid({
    required this.onHugTap,
    required this.onEyesTap,
    required this.onOpenWhenTap,
  });

  final VoidCallback onHugTap;
  final VoidCallback onEyesTap;
  final VoidCallback onOpenWhenTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Open one small doorway',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.65),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _RouteTile(
                title: 'Need a Hug',
                subtitle: 'Tap for the full-screen comfort moment.',
                icon: Icons.favorite_border,
                onTap: onHugTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RouteTile(
                title: 'Can I Borrow\nYour Eyes?',
                subtitle: 'A place for your affirmations.',
                icon: Icons.visibility_outlined,
                onTap: onEyesTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _RouteTile(
          title: 'Open When...',
          subtitle: 'Simple letters for harder moments.',
          icon: Icons.mail_outline,
          onTap: onOpenWhenTap,
        ),
      ],
    );
  }
}

class _RouteTile extends StatelessWidget {
  const _RouteTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CuteCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(height: 14),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.65),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
