import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/cute_widgets.dart';
import '../../../models/note.dart';
import '../../../providers/app_state.dart';
import '../../eyes/presentation/eyes_screen.dart';
import '../../hug/presentation/need_a_hug_screen.dart';
import '../../notes/presentation/notes_screen.dart';
import '../../open_when/presentation/open_when_screen.dart';
import '../../peace/presentation/peace_screen.dart';
import 'notification_debug_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Timer? _burstTimer;
  bool _showMonthlyBurst = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showMonthlyBurstIfNeeded());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _showMonthlyBurstIfNeeded();
  }

  void _showMonthlyBurstIfNeeded() {
    if (DateTime.now().day != 4 || !mounted) return;
    _burstTimer?.cancel();
    setState(() => _showMonthlyBurst = true);
    _burstTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _showMonthlyBurst = false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _burstTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final twilight = state.twilight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            color: Colors.transparent,
            child: SafeArea(
              child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 28),
            children: [
              RepaintBoundary(
                child: _TwilightCalendarCard(
                  twilight: twilight,
                  daysTogether: state.daysTogether,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NeedAHugScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              _LatestNote(note: state.notes.isNotEmpty ? state.notes.first : null),
              const SizedBox(height: 14),
              _PandaCompanionCard(twilight: twilight),
              const SizedBox(height: 18),
              _RouteGrid(
                onEyesTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EyesScreen()),
                ),
                onOpenWhenTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OpenWhenScreen()),
                ),
                onHugTap: () async {
                  if (context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PeaceScreen()),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationDebugScreen()),
                ),
                icon: const Icon(Icons.bug_report_outlined),
                label: const Text('Notification diagnostics (temporary)'),
              ),
            ],
          ),
        ),
      ),
      if (_showMonthlyBurst) const Positioned.fill(child: _MonthlyEmojiBurst()),
    ],
  ),
);
  }
}

class _TwilightCalendarCard extends StatelessWidget {
  const _TwilightCalendarCard({
    required this.twilight,
    required this.daysTogether,
    required this.onTap,
  });

  final dynamic twilight;
  final int daysTogether;
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'SimiRik',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.favorite, color: Color(0xFFE53935), size: 22),
                  ],
                ),
                const SizedBox(height: 14),
                TweenAnimationBuilder<double>(
                  key: ValueKey(daysTogether),
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
                    daysTogether.toString(),
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -4,
                      height: 0.95,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedOpacity(
                  opacity: 1,
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    'twilights together',
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
    return CuteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              twilight.backgroundAsset,
              height: 165,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            twilight.pandaLabel,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 450),
            child: Text(
              twilight.isCharging
                  ? 'Charging with ${twilight.batteryLevel}% battery'
                  : '${twilight.batteryLevel}% battery',
              textAlign: TextAlign.center,
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

class _LatestNote extends StatelessWidget {
  const _LatestNote({required this.note});

  final Note? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final noteText = note?.text ?? 'Tap to write a note for each other.';
    return CuteCard(
      onTap: () => NotesScreen.openNoteEditor(context, existing: note),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        children: [
          Text(
            'shared space...',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.62),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            noteText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.25,
              fontSize: 20,
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

  final Future<void> Function() onHugTap;
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
        _MissYouButton(onTap: onHugTap),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _RouteTile(
                title: 'cute reminders :)',
                subtitle: 'A place for your affirmations.',
                icon: Icons.visibility_outlined,
                onTap: onEyesTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RouteTile(
                title: 'Open When...',
                subtitle: 'Simple letters for harder moments.',
                icon: Icons.mail_outline,
                onTap: onOpenWhenTap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MissYouButton extends StatelessWidget {
  const _MissYouButton({required this.onTap});

  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 112,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Ink.image(
          image: const AssetImage('assets/images/background.jpeg'),
          fit: BoxFit.cover,
          child: InkWell(
            onTap: () async {
              await onTap();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.12),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.favorite_rounded, color: theme.colorScheme.onPrimary),
                  const SizedBox(width: 12),
                  Text(
                    'I miss you',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: theme.colorScheme.onPrimary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthlyEmojiBurst extends StatelessWidget {
  const _MonthlyEmojiBurst();

  @override
  Widget build(BuildContext context) {
    const emojis = [
      '\u{1F496}',
      '\u{2728}',
      '\u{1F389}',
      '\u{1F495}',
      '\u{1F31F}',
      '\u{1F338}',
      '\u{1F497}',
    ];
    final random = Random(4);
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1400),
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) => Opacity(
          opacity: (1 - progress).clamp(0.0, 1.0),
          child: Stack(
            children: [
              for (var index = 0; index < emojis.length; index++)
                Align(
                  alignment: Alignment(
                    -0.65 + (random.nextDouble() * 1.3),
                    -0.1 + (random.nextDouble() * 0.5),
                  ),
                  child: Transform.translate(
                    offset: Offset(
                      (random.nextDouble() - 0.5) * 260 * progress,
                      -80 * progress - (random.nextDouble() * 180 * progress),
                    ),
                    child: Transform.rotate(
                      angle: (random.nextDouble() - 0.5) * progress,
                      child: Text(
                        emojis[index],
                        style: const TextStyle(fontSize: 34),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
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
