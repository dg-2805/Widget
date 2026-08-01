import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/cute_widgets.dart';
import '../../../models/note.dart';
import '../../../providers/app_state.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Notes')),
      body: state.notes.isEmpty
          ? Center(child: Text('No notes yet. Write the first one.', style: Theme.of(context).textTheme.bodyLarge))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              itemCount: state.notes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) => _NoteCard(note: state.notes[index]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openNoteEditor(context),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('New note'),
      ),
    );
  }

  static void openNoteEditor(BuildContext context, {Note? existing}) {
    final controller = TextEditingController(text: existing?.text ?? '');
    final nameController = TextEditingController(text: existing?.authorName ?? '');
    final state = context.read<AppState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: CuteCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(existing == null ? 'Write a note' : 'Edit note', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              if (existing == null) ...[
                TextField(controller: nameController, decoration: const InputDecoration(hintText: 'Your name')),
                const SizedBox(height: 12),
              ],
              TextField(controller: controller, maxLines: 5, decoration: const InputDecoration(hintText: 'Say something thoughtful…')),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final text = controller.text.trim();
                  if (text.isEmpty) return;
                  if (existing == null) {
                    final name = nameController.text.trim().isEmpty ? 'Anonymous' : nameController.text.trim();
                    await state.addNote(text, name);
                  } else {
                    await state.updateNote(existing.id, text);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final theme = Theme.of(context);
    return CuteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(note.text, style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
          const SizedBox(height: 20),
          Divider(height: 1),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Text('${note.authorName} · ${DateFormat.yMMMd().add_jm().format(note.createdAt)}', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.58)))),
            IconButton(icon: const Icon(Icons.edit_outlined, size: 19), onPressed: () => NotesScreen.openNoteEditor(context, existing: note)),
            IconButton(icon: const Icon(Icons.delete_outline, size: 19), onPressed: () => state.deleteNote(note.id)),
          ]),
        ],
      ),
    );
  }
}
