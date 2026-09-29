import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class MedicineActionService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Snooze 10 minutes
  static Future<void> snooze(int id) async {
    await _plugin.cancel(id: id);

    await _plugin.zonedSchedule(
      id: id,
      title: '⏰ Snoozed Medicine',
      body: 'Reminder after snooze',
      scheduledDate:
          tz.TZDateTime.now(tz.local).add(const Duration(minutes: 10)),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'medicine_channel',
          'Medicine Reminder',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // Mark as taken
  static Future<void> markAsTaken(int id) async {
    await _plugin.cancel(id: id);
  }
}
