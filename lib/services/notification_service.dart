import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../core/utils/currency_formatter.dart';
import '../models/bill_model.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings: settings);
    _isInitialized = true;
  }

  Future<void> requestPermission() async {
    await initialize();

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleBillReminder(BillModel bill) async {
    await initialize();

    if (bill.isPaid) {
      await cancelBillReminder(bill.id);
      return;
    }

    final reminderDate = DateTime(
      bill.dueDate.year,
      bill.dueDate.month,
      bill.dueDate.day,
      9,
    ).subtract(Duration(days: bill.reminderDaysBefore));

    if (!reminderDate.isAfter(DateTime.now())) return;

    final dueDateLabel = DateFormat(
      'dd MMMM yyyy',
      'id_ID',
    ).format(bill.dueDate);

    await _notifications.zonedSchedule(
      id: _notificationId(bill.id),
      title: 'Tagihan akan jatuh tempo',
      body:
          'Tagihan ${bill.title} sebesar ${CurrencyFormatter.format(bill.amount)} jatuh tempo pada $dueDateLabel',
      scheduledDate: tz.TZDateTime.from(reminderDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'bill_reminders',
          'Pengingat Tagihan',
          channelDescription: 'Notifikasi pengingat tagihan DompetKampus',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelBillReminder(String billId) async {
    await initialize();
    await _notifications.cancel(id: _notificationId(billId));
  }

  Future<void> cancelAllBillReminders() async {
    await initialize();
    await _notifications.cancelAll();
  }

  int _notificationId(String value) {
    return value.codeUnits.fold<int>(
      0,
      (previous, codeUnit) => (previous * 31 + codeUnit) & 0x7fffffff,
    );
  }
}
