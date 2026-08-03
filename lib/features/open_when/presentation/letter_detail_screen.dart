import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/widgets/cute_widgets.dart';
import '../data/open_when_letters.dart';

class LetterDetailScreen extends StatelessWidget {
  final OpenWhenLetter letter;
  const LetterDetailScreen({super.key, required this.letter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(letter.title),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
          child: CuteCard(
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Icon(
                    Icons.favorite,
                    size: 22,
                    color: theme.colorScheme.primary.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  letter.body,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 420.ms).scale(
                begin: const Offset(0.96, 0.96),
                end: const Offset(1, 1),
                duration: 420.ms,
                curve: Curves.easeOutCubic,
              ),
        ),
      ),
    );
  }
}