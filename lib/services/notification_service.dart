import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/medication_schedule.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// High Priority Channel for Daily Medication Dose Alarms
  static const String channelDoseRemindersId = 'medsafe_dose_reminders';
  static const String channelDoseRemindersName = 'Medication Reminders';
  static const String channelDoseRemindersDesc =
      'Reliable alarms for taking your scheduled medication on time.';

  /// Channel for Cabinet Expiry Warnings & Recalls
  static const String channelAlertsId = 'medsafe_expiry_alerts';
  static const String channelAlertsName = 'Safety & Expiry Alerts';
  static const String channelAlertsDesc =
      'Alerts for medicines approaching expiration or safety recalls.';

  Future<void> initialize({Function(String?)? onNotificationTap}) async {
    if (_isInitialized) return;

    // 1. Initialize timezone database and match local device timezone
    tz.initializeTimeZones();
    try {
      final now = DateTime.now();
      String? matchedZone;
      for (final entry in tz.timeZoneDatabase.locations.entries) {
        if (tz.TZDateTime.from(now, entry.value).timeZoneOffset == now.timeZoneOffset) {
          matchedZone = entry.key;
          tz.setLocalLocation(entry.value);
          break;
        }
      }
      debugPrint('NOTIFICATION_SERVICE: Matched timezone -> $matchedZone (${now.timeZoneOffset})');
    } catch (e) {
      debugPrint('NOTIFICATION_SERVICE: Timezone setup fallback: $e');
      tz.setLocalLocation(tz.UTC);
    }

    // 2. Android Initialization Settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    // 3. iOS Initialization Settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // 4. Initialize Plugin
    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('NOTIFICATION_SERVICE: Tap detected -> ${response.payload}');
        if (onNotificationTap != null) {
          onNotificationTap(response.payload);
        }
      },
    );

    // 5. Create Android Notification Channels with high importance
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          channelDoseRemindersId,
          channelDoseRemindersName,
          description: channelDoseRemindersDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
          ledColor: Color(0xFF2563EB),
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          channelAlertsId,
          channelAlertsName,
          description: channelAlertsDesc,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          showBadge: true,
          ledColor: Color(0xFFDC2626),
        ),
      );
    }

    _isInitialized = true;
    debugPrint('NOTIFICATION_SERVICE: Initialized successfully');
  }

  /// Request permissions on Android 13+ and iOS
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final bool? granted =
            await androidPlugin.requestNotificationsPermission();
        try {
          await androidPlugin.requestExactAlarmsPermission();
        } catch (_) {}
        return granted ?? false;
      }
    } else if (Platform.isIOS) {
      final iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final bool? granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    }
    return true;
  }

  /// Parse time strings reliably in either 12-hour AM/PM (e.g. '08:45 PM') or 24-hour (e.g. '20:45')
  static ({int hour, int minute})? parseTimeString(String timeString) {
    try {
      final clean = timeString.trim().toUpperCase();
      final isPm = clean.contains('PM');
      final isAm = clean.contains('AM');

      // Extract only digits and colon
      final digitsPart = clean.replaceAll(RegExp(r'[^\d:]'), '').trim();
      final parts = digitsPart.split(':');
      if (parts.length != 2) return null;

      int hour = int.parse(parts[0]);
      final int minute = int.parse(parts[1]);

      if (isPm) {
        if (hour < 12) hour += 12;
      } else if (isAm) {
        if (hour == 12) hour = 0;
      }

      return (hour: hour, minute: minute);
    } catch (e) {
      debugPrint('NOTIFICATION_SERVICE: Error parsing time "$timeString": $e');
      return null;
    }
  }

  /// Show an immediate styled notification
  Future<void> showInstantNotification({
    int id = 100,
    required String title,
    required String body,
    String? subtext,
    String? payload,
    bool isWarning = false,
  }) async {
    await initialize();

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      isWarning ? channelAlertsId : channelDoseRemindersId,
      isWarning ? channelAlertsName : channelDoseRemindersName,
      channelDescription:
          isWarning ? channelAlertsDesc : channelDoseRemindersDesc,
      importance: Importance.max,
      priority: Priority.high,
      color: isWarning ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
      colorized: true,
      subText: subtext ?? (isWarning ? 'Cabinet Safety Alert' : 'MedSafe Health Alert'),
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: subtext ?? (isWarning ? 'Cabinet Expiry Warning' : 'MedSafe Medication Alert'),
      ),
      actions: isWarning
          ? <AndroidNotificationAction>[
              const AndroidNotificationAction(
                'action_view_cabinet',
                '🔍 View Cabinet',
                showsUserInterface: true,
                cancelNotification: true,
              ),
              const AndroidNotificationAction(
                'action_dismiss',
                'Dismiss',
                showsUserInterface: false,
                cancelNotification: true,
              ),
            ]
          : <AndroidNotificationAction>[
              const AndroidNotificationAction(
                'action_taken',
                '✓ Taken',
                showsUserInterface: true,
                cancelNotification: true,
              ),
              const AndroidNotificationAction(
                'action_snooze',
                '⏰ Snooze 10m',
                showsUserInterface: false,
                cancelNotification: true,
              ),
            ],
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  /// Schedule a daily repeating reminder at a specific time (e.g. '08:45 PM' or '20:45')
  Future<void> scheduleDailyMedicationReminder({
    required int id,
    required String medicineName,
    required String timeString,
    String? dosageInstructions,
    String? payload,
  }) async {
    await initialize();

    final parsedTime = parseTimeString(timeString);
    if (parsedTime == null) {
      debugPrint('NOTIFICATION_SERVICE: Could not parse time string "$timeString"');
      return;
    }

    final int hour = parsedTime.hour;
    final int minute = parsedTime.minute;
    final tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);

    final String title = '💊 Time for your dose: $medicineName';
    final String body = dosageInstructions != null && dosageInstructions.isNotEmpty
        ? '$dosageInstructions\nScheduled for $timeString'
        : 'Please take your scheduled dose of $medicineName ($timeString).';

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelDoseRemindersId,
      channelDoseRemindersName,
      channelDescription: channelDoseRemindersDesc,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      color: const Color(0xFF2563EB),
      colorized: true,
      subText: 'Scheduled Dose ($timeString)',
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Daily Medication Reminder',
      ),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'action_taken',
          '✓ Dose Taken',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          'action_snooze',
          '⏰ Snooze 10m',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload ?? 'medicine_dose_$id',
      );
    } catch (exactErr) {
      debugPrint('NOTIFICATION_SERVICE: exactAllowWhileIdle failed ($exactErr), using inexactAllowWhileIdle');
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload ?? 'medicine_dose_$id',
      );
    }

    debugPrint(
        'NOTIFICATION_SERVICE: Successfully scheduled daily alarm for "$medicineName" at $hour:${minute.toString().padLeft(2, '0')} (Next: $scheduledDate)');
  }

  /// Sync all existing schedules into device alarms
  Future<void> syncSchedules(List<MedicationSchedule> schedules, List<dynamic> medicines) async {
    final medMap = <String, String>{};
    for (final m in medicines) {
      try {
        medMap[m.id.toString()] = m.name.toString();
      } catch (_) {}
    }

    for (final schedule in schedules) {
      final name = medMap[schedule.cabinetItemId] ?? 'Medication';
      for (int i = 0; i < schedule.scheduledTimes.length; i++) {
        final timeStr = schedule.scheduledTimes[i];
        final alarmId = (schedule.cabinetItemId.hashCode + i).abs() % 100000;
        await scheduleDailyMedicationReminder(
          id: alarmId,
          medicineName: name,
          timeString: timeStr,
          dosageInstructions: 'Take scheduled dose of $name',
        );
      }
    }
  }

  final Set<String> _notifiedExpirySessionKeys = {};

  /// Check a medicine's expiry date and immediately alert or schedule alerts
  Future<void> checkAndScheduleExpiryAlert({
    required int id,
    required String medicineName,
    required DateTime expiryDate,
    bool fireInstantIfUrgent = true,
  }) async {
    await initialize();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetExpiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    final daysRemaining = targetExpiry.difference(today).inDays;

    final formattedDate =
        '${expiryDate.day.toString().padLeft(2, '0')}/${expiryDate.month.toString().padLeft(2, '0')}/${expiryDate.year}';

    debugPrint(
        'NOTIFICATION_SERVICE: checkAndScheduleExpiryAlert for "$medicineName" - Expiry: $formattedDate, Days remaining: $daysRemaining');

    // Case 1: Medicine has ALREADY EXPIRED!
    if (daysRemaining < 0) {
      final daysAgo = daysRemaining.abs();
      if (fireInstantIfUrgent) {
        await showInstantNotification(
          id: id,
          title: '⛔ Expired Medicine Alert: $medicineName',
          body:
              'CRITICAL SAFETY WARNING: $medicineName expired $daysAgo day(s) ago (on $formattedDate). Please do NOT consume it! Safely discard.',
          subtext: 'Expired Medicine Warning',
          isWarning: true,
          payload: 'expired_medicine_$id',
        );
      }
      return;
    }

    // Case 2: Medicine expires TODAY!
    if (daysRemaining == 0) {
      if (fireInstantIfUrgent) {
        await showInstantNotification(
          id: id,
          title: '⛔ Medicine Expires Today: $medicineName',
          body:
              'URGENT: $medicineName reaches its expiration date TODAY ($formattedDate). Do not consume after today. Consult your pharmacist.',
          subtext: 'Expires Today',
          isWarning: true,
          payload: 'expires_today_$id',
        );
      }
      return;
    }

    // Case 3: Medicine expires within 7 days (e.g., in 2 days)!
    if (daysRemaining <= 7) {
      if (fireInstantIfUrgent) {
        final dayText = daysRemaining == 1 ? 'TOMORROW' : 'in $daysRemaining days';
        await showInstantNotification(
          id: id,
          title: '⚠️ Urgent Expiry Warning: $medicineName',
          body:
              'Attention: $medicineName will expire $dayText (on $formattedDate)! Please ensure you replenish your supply or safely discard.',
          subtext: 'Expires $dayText',
          isWarning: true,
          payload: 'expiring_soon_$id',
        );
      }

      // Also schedule a morning reminder at 10:00 AM on the expiry day
      final expiryMorning = tz.TZDateTime(
        tz.local,
        targetExpiry.year,
        targetExpiry.month,
        targetExpiry.day,
        10,
        0,
      );
      if (expiryMorning.isAfter(tz.TZDateTime.now(tz.local))) {
        await _scheduleZonedSafetyAlert(
          id: id + 50000,
          title: '⛔ Medicine Expires Today: $medicineName',
          body:
              '$medicineName expires today ($formattedDate). Do not take expired medication.',
          scheduledDate: expiryMorning,
          payload: 'expires_today_$id',
        );
      }
      return;
    }

    // Case 4: Medicine expires more than 7 days away (e.g. 15 days, 1 month, 6 months)
    // 4a. Schedule alert for 7 days before expiry at 10:00 AM
    final sevenDaysPrior = targetExpiry.subtract(const Duration(days: 7));
    final scheduled7DayAlert = tz.TZDateTime(
      tz.local,
      sevenDaysPrior.year,
      sevenDaysPrior.month,
      sevenDaysPrior.day,
      10,
      0,
    );

    if (scheduled7DayAlert.isAfter(tz.TZDateTime.now(tz.local))) {
      await _scheduleZonedSafetyAlert(
        id: id,
        title: '⚠️ Expiry Notice: $medicineName',
        body:
            '$medicineName will expire in 7 days (on $formattedDate). Please inspect your medicine cabinet.',
        scheduledDate: scheduled7DayAlert,
        payload: 'expiry_7days_$id',
      );
      debugPrint(
          'NOTIFICATION_SERVICE: Scheduled 7-day expiry alert for "$medicineName" on $scheduled7DayAlert');
    }

    // 4b. Schedule on the exact day of expiry at 10:00 AM
    final scheduledExpiryDayAlert = tz.TZDateTime(
      tz.local,
      targetExpiry.year,
      targetExpiry.month,
      targetExpiry.day,
      10,
      0,
    );
    if (scheduledExpiryDayAlert.isAfter(tz.TZDateTime.now(tz.local))) {
      await _scheduleZonedSafetyAlert(
        id: id + 50000,
        title: '⛔ Medicine Expires Today: $medicineName',
        body:
            '$medicineName expires today ($formattedDate). Safely discard or replace.',
        scheduledDate: scheduledExpiryDayAlert,
        payload: 'expires_today_$id',
      );
    }
  }

  /// Helper to schedule a high-priority zoned notification for safety / expiry
  Future<void> _scheduleZonedSafetyAlert({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelAlertsId,
      channelAlertsName,
      channelDescription: channelAlertsDesc,
      importance: Importance.high,
      priority: Priority.high,
      color: const Color(0xFFDC2626),
      colorized: true,
      category: AndroidNotificationCategory.reminder,
      subText: 'Cabinet Safety Notice',
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Medicine Expiration Warning',
      ),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'action_view_cabinet',
          '🔍 View Cabinet',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          'action_dismiss',
          'Dismiss',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload ?? 'expiry_$id',
      );
    } catch (e) {
      debugPrint('NOTIFICATION_SERVICE: exact zoned schedule failed ($e), using inexact');
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload ?? 'expiry_$id',
      );
    }
  }

  /// Sync expiry alerts for all medicines in cabinet
  Future<void> syncCabinetExpiries(List<dynamic> medicines) async {
    for (final med in medicines) {
      try {
        final String id = med.id?.toString() ?? '';
        final String name = med.name?.toString() ?? 'Medicine';
        final DateTime? expiry =
            med.expiryDate is DateTime ? (med.expiryDate as DateTime) : null;
        if (expiry == null) continue;

        final alertId = (id.hashCode + 8888).abs() % 100000;
        final sessionKey = '$id-${expiry.year}-${expiry.month}-${expiry.day}';
        final bool shouldFireInstant =
            !_notifiedExpirySessionKeys.contains(sessionKey);

        await checkAndScheduleExpiryAlert(
          id: alertId,
          medicineName: name,
          expiryDate: expiry,
          fireInstantIfUrgent: shouldFireInstant,
        );

        if (shouldFireInstant) {
          _notifiedExpirySessionKeys.add(sessionKey);
        }
      } catch (e) {
        debugPrint('NOTIFICATION_SERVICE: Error syncing expiry for med: $e');
      }
    }
  }

  /// Schedule an alert 7 days prior to medicine expiration (wrapper for backward compatibility)
  Future<void> scheduleExpiryAlert({
    required int id,
    required String medicineName,
    required DateTime expiryDate,
  }) async {
    await checkAndScheduleExpiryAlert(
      id: id,
      medicineName: medicineName,
      expiryDate: expiryDate,
      fireInstantIfUrgent: true,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the scheduled time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Cancel a specific notification
  Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  /// List pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }
}
