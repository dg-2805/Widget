import 'package:flutter/material.dart';

import '../../../core/widgets/cute_widgets.dart';

class OpenWhenScreen extends StatelessWidget {
  const OpenWhenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const items = [
      'Open when anxious',
      'Open when you miss me',
      "Open when you can't sleep",
      "Open when you're doubting yourself",
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Open When...')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          Text(
            'A simple stack of letters for later.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.68),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CuteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Text(
                      'Write the letter content here later.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.62),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
