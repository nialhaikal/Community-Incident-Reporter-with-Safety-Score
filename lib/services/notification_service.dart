import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'safezone_alerts';
  static const _channelName = 'SafeZone Alerts';
  static const _channelDesc = 'Community safety notifications from SafeZone';

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: _channelDesc,
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    playSound: true,
    enableVibration: true,
  );

  static const NotificationDetails _details =
      NotificationDetails(android: _androidDetails);

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings);

    // Request notification permission on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showIncidentSubmitted(String incidentType) async {
    await _plugin.show(
      1,
      'Incident Reported',
      'Your $incidentType report has been submitted. Thank you for keeping the community safe.',
      _details,
    );
  }

  Future<void> showSafetyAlert(double score) async {
    final String title;
    final String body;

    if (score < 40) {
      title = 'HIGH RISK ALERT';
      body =
          'Safety score is critically low (${score.toInt()}/100). Avoid travelling alone in this area.';
    } else {
      title = 'Moderate Risk Warning';
      body =
          'Safety score has dropped to ${score.toInt()}/100. Exercise caution in this area.';
    }

    await _plugin.show(2, title, body, _details);
  }

  Future<void> showAdminStatusUpdated(
      String incidentType, String newStatus) async {
    await _plugin.show(
      3,
      'Status Updated',
      '$incidentType report marked as "$newStatus".',
      _details,
    );
  }

  Future<void> showAdminIncidentDeleted(String incidentType) async {
    await _plugin.show(
      4,
      'Incident Deleted',
      '$incidentType report has been permanently removed.',
      _details,
    );
  }
}
