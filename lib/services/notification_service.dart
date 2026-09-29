import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/medicine_model.dart';

class NotificationService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();

  static const String _notificationEnabledKey = 'notifications_enabled';
  static const String _soundEnabledKey = 'notification_sound_enabled';

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// ===============================
  /// DEFAULT REMINDER TIMES
  /// ===============================

  static const List<Map<String, dynamic>> defaultSchedule = [
    {'label': 'Morning', 'hour': 8, 'minute': 0, 'index': 0},
    {'label': 'Afternoon', 'hour': 14, 'minute': 0, 'index': 1},
    {'label': 'Evening', 'hour': 20, 'minute': 0, 'index': 2},
  ];

  /// ===============================
  /// INITIALIZE
  /// ===============================

  Future<void> initialize() async {
    tz.initializeTimeZones();

    tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));

    const android = AndroidInitializationSettings('@mipmap/launcher_icon');

    const ios = DarwinInitializationSettings();

    const settings = InitializationSettings(android: android, iOS: ios);

    await _notificationsPlugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onTapNotification,
    );

    await _requestPermissions();
  }

  void _onTapNotification(NotificationResponse response) {
    // open medicine page
  }

  /// ===============================
  /// PERMISSION
  /// ===============================

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      final ios = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    }

    if (Platform.isAndroid) {
      final android = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await android?.requestNotificationsPermission();

      await android?.requestExactAlarmsPermission();
    }
  }

  /// ===============================
  /// SAVE CUSTOM TIME
  /// ===============================

  Future<void> saveReminderTime({
    required int index,
    required int hour,
    required int minute,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'reminder_time_$index',
      jsonEncode({'hour': hour, 'minute': minute}),
    );
  }

  /// ===============================
  /// GET REMINDER SCHEDULE
  /// ===============================

  Future<List<Map<String, dynamic>>> getReminderSchedule() async {
    final prefs = await SharedPreferences.getInstance();

    List<Map<String, dynamic>> updated = [];

    for (final item in defaultSchedule) {
      final index = item['index'];

      final saved = prefs.getString('reminder_time_$index');

      if (saved != null) {
        final decoded = jsonDecode(saved);

        updated.add({
          ...item,
          'hour': decoded['hour'],
          'minute': decoded['minute'],
        });
      } else {
        updated.add(item);
      }
    }

    return updated;
  }

  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationEnabledKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationEnabledKey, enabled);
  }

  Future<bool> getSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundEnabledKey) ?? true;
  }

  Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, enabled);
  }

  /// ===============================
  /// SCHEDULE MEDICINE
  /// ===============================

  Future<void> scheduleMedicineReminder(Medicine medicine) async {
    if (medicine.id == null || medicine.dosage.isEmpty) {
      return;
    }

    final enabled = await getNotificationsEnabled();
    if (!enabled) return;

    final parts = medicine.dosage.split('+');

    final scheduleMap = await getReminderSchedule();

    for (final item in scheduleMap) {
      final index = item['index'] as int;

      if (index >= parts.length) continue;

      final doseCount = int.tryParse(parts[index].trim()) ?? 0;

      if (doseCount > 0) {
        await _scheduleSingleNotification(
          id: _notificationId(medicine.id!, index),

          title: 'Medicine Reminder',

          body:
              'Take ${medicine.name} '
              '(${medicine.dosage}) '
              '- ${item['label']}',

          hour: item['hour'] as int,

          minute: item['minute'] as int,
          imagePath: medicine.image.isNotEmpty ? medicine.image : null,
        );
      }
    }
  }

  /// ===============================
  /// SINGLE NOTIFICATION
  /// ===============================

  Future<void> _scheduleSingleNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? imagePath,
  }) async {
    // Resolve image: if it's a network URL, download to a temporary file;
    // if it's a local path, keep as is. If not found, set to null.
    String? resolvedImagePath;
    try {
      if (imagePath != null && imagePath.isNotEmpty) {
        resolvedImagePath = await _resolveImagePath(imagePath);
        print('Notification image resolved: $resolvedImagePath');
      }
    } catch (e) {
      print('Failed to resolve image for notification: $e');
      resolvedImagePath = null;
    }
    final now = tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final soundEnabled = await getSoundEnabled();

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: _notificationDetails(
        imagePath: resolvedImagePath,
        title: title,
        body: body,
        soundEnabled: soundEnabled,
      ),

      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<String?> _resolveImagePath(String image) async {
    // If it's a network URL, download to temp file
    if (image.startsWith('http://') || image.startsWith('https://')) {
      try {
        final uri = Uri.parse(image);
        final httpClient = HttpClient();
        final request = await httpClient.getUrl(uri);
        final response = await request.close();
        if (response.statusCode == 200) {
          final bytes = await consolidateHttpClientResponseBytes(response);
          final tempDir = Directory.systemTemp.createTempSync('med_img_');
          final file = File(
            '${tempDir.path}/${uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'image.jpg'}',
          );
          await file.writeAsBytes(bytes);
          return file.path;
        }
      } catch (e) {
        print('Download failed: $e');
        return null;
      }
    }

    // If it's a local file path, verify it exists
    final local = File(image);
    if (local.existsSync()) return local.path;

    return null;
  }

  /// ===============================
  /// NOTIFICATION STYLE
  /// ===============================

  NotificationDetails _notificationDetails({
    String? imagePath,
    String? title,
    String? body,
    bool soundEnabled = true,
  }) {
    // If an image path is provided and the file exists, show a big picture style notification
    if (imagePath != null && File(imagePath).existsSync()) {
      final style = BigPictureStyleInformation(
        FilePathAndroidBitmap(imagePath),
        largeIcon: FilePathAndroidBitmap(imagePath),
        contentTitle: title,
        summaryText: body,
      );

      final androidDetails = AndroidNotificationDetails(
        'medicine_channel',
        'Medicine Reminder',
        icon: '@mipmap/launcher_icon',
        channelDescription: 'Medicine reminder notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: soundEnabled,
        enableVibration: true,
        category: AndroidNotificationCategory.alarm,
        styleInformation: style,
      );

      final iosDetails = DarwinNotificationDetails(
        attachments: [DarwinNotificationAttachment(imagePath)],
        presentSound: soundEnabled,
      );

      return NotificationDetails(android: androidDetails, iOS: iosDetails);
    }

    // Default notification details
    final androidDetails = AndroidNotificationDetails(
      'medicine_channel',
      'Medicine Reminder',
      icon: '@mipmap/launcher_icon',
      channelDescription: 'Medicine reminder notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: soundEnabled,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
    );

    final iosDetails = DarwinNotificationDetails(presentSound: soundEnabled);

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  /// ===============================
  /// TEST NOTIFICATION
  /// ===============================

  Future<void> showTestNotification() async {
    final soundEnabled = await getSoundEnabled();

    final androidDetails = AndroidNotificationDetails(
      'medicine_channel',
      'Medicine Reminder',
      icon: '@mipmap/launcher_icon',
      channelDescription: 'Medicine reminder notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: soundEnabled,
    );

    final iosDetails = DarwinNotificationDetails(presentSound: soundEnabled);

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: 0,
      title: 'Test Medicine Reminder',
      body: 'This is a test notification '
          'working perfectly!',
      notificationDetails: notificationDetails,
    );
  }

  /// ===============================
  /// CANCEL SINGLE
  /// ===============================

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);

    for (var index = 0; index < 3; index++) {
      await _notificationsPlugin.cancel(id: _notificationId(id, index));
    }
  }

  /// ===============================
  /// CANCEL ALL
  /// ===============================

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  /// ===============================
  /// RESCHEDULE ALL MEDICINES
  /// ===============================

  Future<void> rescheduleMedicines(List<Medicine> medicines) async {
    for (final medicine in medicines) {
      await scheduleMedicineReminder(medicine);
    }
  }

  /// ===============================
  /// UNIQUE ID
  /// ===============================

  int _notificationId(int medicineId, int doseIndex) {
    return (medicineId * 10) + doseIndex;
  }

  /// ===============================
  /// TEST BACKGROUND
  /// ===============================

  Future<void> testBackgroundNotification() async {
    await _notificationsPlugin.zonedSchedule(
      id: 1,
      title: "TEST",
      body: "App closed test notification",

      scheduledDate:
          tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1)),

      notificationDetails: _notificationDetails(),

      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
