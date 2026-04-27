import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/food_item.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize the Service
  static Future<void> initialize() async {
    tz.initializeTimeZones(); // Set up timezones

  final currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone.identifier));

    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitSettings =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _notificationsPlugin.initialize(settings: initSettings);

    _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  // The Main Scheduling Logic
  static Future<void> scheduleExpiryNotifications(FoodItem item) async {
    final int baseId = item.name.hashCode;

    // Set the time of day you want the alert to sound (10:00 AM)
    DateTime expiryDate = DateTime(
      item.expiryDate.year,
      item.expiryDate.month,
      item.expiryDate.day,
      10,
      0,
    );
    DateTime now = DateTime.now();

    // Alert 1: Two days before
    await _scheduleAlert(
      id: baseId + 1,
      title: 'Expiring Soon! ⚠️',
      body: 'Your ${item.name} will expire in 2 days.',
      scheduledTime: expiryDate.subtract(const Duration(days: 2)),
    );

    // Alert 2: One day before
    await _scheduleAlert(
      id: baseId + 2,
      title: 'Expiring Tomorrow! ⏰',
      body: 'Your ${item.name} expires tomorrow. Plan a meal!',
      scheduledTime: expiryDate.subtract(const Duration(days: 1)),
    );

    // Alert 3: Day of expiry
    
    // If the item expires today, but 10:00 AM has already passed, schedule it 10 seconds from now so you can see it!
    DateTime todayAlertTime = expiryDate;
    if (item.expiryDate.day == now.day &&
        item.expiryDate.month == now.month &&
        item.expiryDate.year == now.year) {
      if (now.isAfter(expiryDate)) {
        todayAlertTime = now.add(
          const Duration(seconds: 10),
        ); // Trigger in 10 seconds!
      }
    }
    
    await _scheduleAlert(
      id: baseId + 3,
      title: 'Item Expiring Today! 🚨',
      body: 'Your ${item.name} expires today. Consume it now to avoid waste!',
      scheduledTime: todayAlertTime, //expiryDate,
    );

    // Alert 4: One day AFTER expiry
    await _scheduleAlert(
      id: baseId + 4,
      title: 'Item Expired! 🗑️',
      body:
          'Your ${item.name} expired. Please discard it to keep your fridge fresh.',
      scheduledTime: expiryDate.add(const Duration(days: 1)),
    );
  }

  // The Backend "Worker" that actually talks to the phone
  static Future<void> _scheduleAlert({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    // Do not schedule notifications for times that have already passed
    DateTime now = DateTime.now();
    DateTime timeToSchedule = scheduledTime;

    // Catch-up logic instead of instantly returning!
    if (timeToSchedule.isBefore(now)) {
      // If the alert was supposed to happen earlier today, trigger it 1 minute from now!
      if (now.difference(timeToSchedule).inHours < 24) {
        timeToSchedule = now.add(const Duration(minutes: 1));
      } 
      else {
        // Only ignore it if it's over a day old
        return; 
      }
  }

    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(timeToSchedule, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'expiry_alerts_final',
            'Expiry Alerts',
            channelDescription: 'Notifications for expiring food items',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } 
    catch (e) {
      print("Error scheduling $title: $e");
    }
  }
}
