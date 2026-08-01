import 'package:home_widget/home_widget.dart';
import '../core/twilight/twilight_state.dart';

class WidgetService {
  static const _androidPackage = 'com.example.our_space';
  static const _androidWidgetName = 'OurSpaceWidgetProvider';

  static Future<void> update(TwilightState state) async {
    await HomeWidget.saveWidgetData<int>('twilights_together', state.twilightsTogether);
    await HomeWidget.saveWidgetData<String>('twilight_phase', state.phase.name);
    await HomeWidget.saveWidgetData<bool>('is_charging', state.isCharging);
    await HomeWidget.saveWidgetData<int>('battery_level', state.batteryLevel);
    await HomeWidget.saveWidgetData<String>('comfort_message', state.comfortMessage);
    await HomeWidget.saveWidgetData<String>('panda_label', state.pandaLabel);

    await HomeWidget.updateWidget(
      androidName: _androidWidgetName,
      qualifiedAndroidName: '$_androidPackage.$_androidWidgetName',
    );
  }
}
