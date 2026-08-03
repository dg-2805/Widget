import 'package:flutter_test/flutter_test.dart';
import 'package:our_space/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
  });

  test('next monthly reminder rolls December into January', () {
    final now = tz.TZDateTime(tz.local, 2026, 12, 5, 8);

    final scheduled = NotificationService.nextMonthlyInstanceAt(now, 4, 0, 0);

    expect(scheduled.year, 2027);
    expect(scheduled.month, 1);
    expect(scheduled.day, 4);
    expect(scheduled.hour, 0);
    expect(scheduled.minute, 0);
  });
}
