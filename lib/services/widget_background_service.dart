import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';

import '../core/twilight/twilight_state.dart';
import 'widget_service.dart';

const _widgetRefreshTask = 'our-space-widget-refresh';

@pragma('vm:entry-point')
void widgetBackgroundDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (taskName != _widgetRefreshTask) return true;
    final latestNote = await HomeWidget.getWidgetData<String>(
      'latest_note',
      defaultValue: 'no notes yet...',
    );
    final now = DateTime.now();
    await WidgetService.update(
      TwilightState.from(now, batteryLevel: 100, isCharging: false),
      daysTogether: TwilightState.countTwilightsTogether(now),
      latestNote: latestNote ?? 'no notes yet...',
    );
    return true;
  });
}

class WidgetBackgroundService {
  static Future<void> initialize() => Workmanager().initialize(
        widgetBackgroundDispatcher,
        isInDebugMode: false,
      );

  static Future<void> registerPeriodicRefresh() =>
      Workmanager().registerPeriodicTask(
        _widgetRefreshTask,
        _widgetRefreshTask,
        frequency: const Duration(minutes: 15),
        existingWorkPolicy: ExistingWorkPolicy.keep,
      );
}
