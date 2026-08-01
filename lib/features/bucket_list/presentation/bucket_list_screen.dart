import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/cute_widgets.dart';
import '../../../models/bucket_item.dart';
import '../../../providers/app_state.dart';

class BucketListScreen extends StatelessWidget {
  const BucketListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pending = state.bucketItems.where((item) => !item.completed).toList();
    final done = state.bucketItems.where((item) => item.completed).toList();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Together')),
      body: state.bucketItems.isEmpty
          ? const Center(child: Text('Add something you would like to do together.'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                if (pending.isNotEmpty) ...[
                  const SectionHeader(title: 'Next up'),
                  const SizedBox(height: 8),
                  ...pending.map((item) => _BucketTile(item: item)),
                ],
                if (done.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const SectionHeader(title: 'Completed'),
                  const SizedBox(height: 8),
                  ...done.map((item) => _BucketTile(item: item)),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAdder(context),
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
      ),
    );
  }

  static void _openAdder(BuildContext context, {BucketItem? existing}) {
    final controller = TextEditingController(text: existing?.title ?? '');
    final state = context.read<AppState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: CuteCard(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(existing == null ? 'Add an idea' : 'Edit item', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            TextField(controller: controller, decoration: const InputDecoration(hintText: 'e.g. Watch the sunrise together')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                if (existing == null) {
                  await state.addBucketItem(text);
                } else {
                  await state.updateBucketItem(existing.id, text);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ]),
        ),
      ),
    );
  }
}

class _BucketTile extends StatelessWidget {
  final BucketItem item;
  const _BucketTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CuteCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Checkbox(value: item.completed, shape: const CircleBorder(), onChanged: (value) => state.toggleBucketItem(item.id, value ?? false)),
          const SizedBox(width: 4),
          Expanded(child: Text(item.title, style: TextStyle(decoration: item.completed ? TextDecoration.lineThrough : null))),
          IconButton(icon: const Icon(Icons.edit_outlined, size: 19), onPressed: () => BucketListScreen._openAdder(context, existing: item)),
          IconButton(icon: const Icon(Icons.delete_outline, size: 19), onPressed: () => state.deleteBucketItem(item.id)),
        ]),
      ),
    );
  }
}
