import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../services/notification_service.dart';

/// Temporary on-device diagnostics for local-notification registration.
class NotificationDebugScreen extends StatefulWidget {
  const NotificationDebugScreen({super.key});

  @override
  State<NotificationDebugScreen> createState() => _NotificationDebugScreenState();
}

class _NotificationDebugScreenState extends State<NotificationDebugScreen> {
  late Future<NotificationDebugSnapshot> _snapshot = _load();
  String? _testResult;

  Future<NotificationDebugSnapshot> _load() => NotificationService.instance.debugSnapshot();

  void _refresh() => setState(() => _snapshot = _load());

  Future<void> _showTestNotification() async {
    try {
      await NotificationService.instance.showDebugTestNotification();
      _testResult = 'Immediate test requested (ID 99001). Check the notification shade now.';
    } catch (error) {
      _testResult = 'Immediate test failed: $error';
    }
    if (mounted) setState(() => _snapshot = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification diagnostics')),
      body: FutureBuilder<NotificationDebugSnapshot>(
        future: _snapshot,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text('Could not load diagnostics: ${snapshot.error}'));
          final data = snapshot.requireData;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Service initialized: ${data.initialized}'),
              if (data.pluginError != null) ...[
                const SizedBox(height: 12),
                Text('pendingNotificationRequests error:\n${data.pluginError}'),
              ],
              const SizedBox(height: 16),
              Text('Pending plugin requests (${data.pending.length})', style: Theme.of(context).textTheme.titleMedium),
              for (final request in data.pending)
                Text('ID ${request.id}: ${request.title ?? ''} — ${request.body ?? ''}'),
              const SizedBox(height: 16),
              Text('Requested schedules (app record)', style: Theme.of(context).textTheme.titleMedium),
              for (final detail in data.scheduleDetails) SelectableText(detail),
              const SizedBox(height: 16),
              Text('Last initialization error', style: Theme.of(context).textTheme.titleMedium),
              SelectableText(data.lastInitError ?? 'None'),
              const SizedBox(height: 16),
              Text('Persistent diagnostic log', style: Theme.of(context).textTheme.titleMedium),
              for (final entry in data.log.reversed) SelectableText(entry),
              const SizedBox(height: 24),
              if (_testResult != null) Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_testResult!),
              ),
              if (kDebugMode)
                FilledButton.icon(
                  onPressed: _showTestNotification,
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Show test notification now'),
                ),
              OutlinedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          );
        },
      ),
    );
  }
}
