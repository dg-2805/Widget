import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/widgets/cute_widgets.dart';
import '../data/open_when_letters.dart';
import 'letter_detail_screen.dart';

class OpenWhenScreen extends StatelessWidget {
  const OpenWhenScreen({super.key});

  static final _sixMonthUnlockDate = DateTime(2026, 8, 4);

  bool get _isSixMonthLetterUnlocked =>
      !DateTime.now().isBefore(_sixMonthUnlockDate);

  void _openLetter(BuildContext context, OpenWhenLetter letter) {
    if (letter.isFeatured && !_isSixMonthLetterUnlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This letter opens on 4 August 2026. \u{1F512}'),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, __) => FadeTransition(
          opacity: animation,
          child: LetterDetailScreen(letter: letter),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Open When...'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          Text(
            'A little stack of letters for later.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.68),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),

          // Featured box — the big "6 Months, Heart" envelope.
          _EnvelopeCard(
            title: featuredLetter.title,
            subtitle: _isSixMonthLetterUnlocked
                ? featuredLetter.subtitle
                : 'Unlocks on 4 August 2026',
            isFeatured: true,
            isLocked: !_isSixMonthLetterUnlocked,
            onTap: () => _openLetter(context, featuredLetter),
          ).animate().fadeIn(duration: 380.ms).slideY(
                begin: 0.08,
                end: 0,
                duration: 380.ms,
                curve: Curves.easeOut,
              ),

          const SizedBox(height: 20),

          // 2x2 grid of the four "open when" letters.
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: openWhenLetters.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (context, index) {
              final letter = openWhenLetters[index];
              return _EnvelopeCard(
                title: letter.title,
                subtitle: letter.subtitle,
                onTap: () => _openLetter(context, letter),
              )
                  .animate()
                  .fadeIn(
                    duration: 380.ms,
                    delay: (80 * index).ms,
                  )
                  .slideY(
                    begin: 0.08,
                    end: 0,
                    duration: 380.ms,
                    delay: (80 * index).ms,
                    curve: Curves.easeOut,
                  );
            },
          ),
        ],
      ),
    );
  }
}

class _EnvelopeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isFeatured;
  final bool isLocked;
  final VoidCallback onTap;

  const _EnvelopeCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isFeatured = false,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CuteCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(
        horizontal: 18,
        vertical: isFeatured ? 26 : 18,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLocked ? Icons.lock_outline_rounded : Icons.mail_outline_rounded,
              size: isFeatured ? 40 : 28,
              color: isLocked
                  ? theme.colorScheme.onSurface.withOpacity(0.45)
                  : theme.colorScheme.primary,
            ),
            SizedBox(height: isFeatured ? 14 : 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: (isFeatured
                      ? theme.textTheme.titleLarge
                      : theme.textTheme.titleSmall)
                  ?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isLocked
                        ? theme.colorScheme.onSurface.withOpacity(0.55)
                        : null,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: isFeatured ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
