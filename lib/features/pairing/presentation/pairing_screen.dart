import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/cute_widgets.dart';
import '../../../providers/app_state.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: CuteCard(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Us', textAlign: TextAlign.center, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -1.5)),
                const SizedBox(height: 14),
                Text('A private place for the two of you.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                const SizedBox(height: 28),
                const Text('Enter the same phrase on both phones to begin.'),
                const SizedBox(height: 12),
                TextField(controller: _controller, decoration: const InputDecoration(hintText: 'Your shared phrase')),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Continue'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _loading ? null : _createCode,
                  child: const Text('Create a new shared code'),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await context.read<AppState>().pair(_controller.text);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _createCode() {
    const words = ['amber', 'bloom', 'comet', 'daisy', 'ember', 'lunar', 'maple', 'panda', 'peach', 'river', 'starlight', 'velvet'];
    final random = Random.secure();
    _controller.text = '${words[random.nextInt(words.length)]}-${words[random.nextInt(words.length)]}-${100 + random.nextInt(900)}';
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
