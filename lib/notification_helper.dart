// lib/notification_helper.dart
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:torch_light/torch_light.dart';
import 'package:audioplayers/audioplayers.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const String channelId = 'emergency_alerts_channel';
const String channelName = 'Emergency Alerts';
const String channelDesc = 'High priority emergency alerts';

/// NOTE: Native Android sound resource name (no extension):
///   android/app/src/main/res/raw/alarm.mp3  -> resource name = 'alarm'
///
/// Flutter asset fallback:
///   assets/sounds/alarm.mp3 (declare in pubspec.yaml)
Future<void> initLocalNotifications() async {
  const AndroidInitializationSettings androidInit = AndroidInitializationSettings(
      '@mipmap/ic_launcher'); // you may change to 'ic_notification' if you added a white icon

  final DarwinInitializationSettings iosInit = DarwinInitializationSettings(
    requestSoundPermission: true,
    requestBadgePermission: true,
    requestAlertPermission: true,
  );

  final InitializationSettings initSettings =
      InitializationSettings(android: androidInit, iOS: iosInit);

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (kDebugMode)
        dev.log('Notification tapped payload=${response.payload}');
    },
  );

  // Create Android channel. sound uses raw resource name (no extension).
  final AndroidNotificationChannel channel = AndroidNotificationChannel(
    channelId,
    channelName,
    description: channelDesc,
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound(
        'alarm'), // <-- native raw resource name
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 250, 100, 250]),
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

/// Show notification + play fallback sound + blink torch for 10s
Future<void> showEmergencyNotification({
  required String title,
  required String body,
  bool fullScreen = false,
  Map<String, dynamic>? data,
}) async {
  final androidDetails = AndroidNotificationDetails(
    channelId,
    channelName,
    channelDescription: channelDesc,
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
    fullScreenIntent: fullScreen,
    playSound: true,
    sound: RawResourceAndroidNotificationSound(
        'alarm'), // native raw resource name
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 250, 100, 250]),
    visibility: NotificationVisibility.public,
  );

  final iosDetails = DarwinNotificationDetails(
    presentSound: true,
  );

  final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

  try {
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: data?.toString(),
    );
  } catch (e, st) {
    if (kDebugMode) dev.log('Error showing notification: $e\n$st');
  }

  // Play flutter asset fallback (optional)
  try {
    final player = AudioPlayer();
    await player.play(AssetSource('assets/sounds/alarm.mp3'));
  } catch (e, st) {
    if (kDebugMode) dev.log('Audio fallback error: $e\n$st');
  }

  // Blink torch for 10 seconds (non-blocking)
  _startBlinkingTorch(durationSeconds: 10);
}

// Simple guarded torch blinker
bool _torchBlinkerRunning = false;

Future<void> _startBlinkingTorch({required int durationSeconds}) async {
  if (_torchBlinkerRunning) return;
  _torchBlinkerRunning = true;
  try {
    final int onMs = 200;
    final int offMs = 200;
    final int totalMs = durationSeconds * 1000;
    final int cycleMs = onMs + offMs;
    final int iterations = (totalMs / cycleMs).ceil();

    for (int i = 0; i < iterations; i++) {
      try {
        await TorchLight.enableTorch();
      } catch (e) {
        if (kDebugMode) dev.log('Torch enable failed: $e');
        break;
      }
      await Future.delayed(Duration(milliseconds: onMs));
      try {
        await TorchLight.disableTorch();
      } catch (e) {
        if (kDebugMode) dev.log('Torch disable failed: $e');
      }
      final elapsed = (i + 1) * cycleMs;
      if (elapsed >= totalMs) break;
      await Future.delayed(Duration(milliseconds: offMs));
    }
  } catch (e, st) {
    if (kDebugMode) dev.log('Torch blinker error: $e\n$st');
  } finally {
    try {
      await TorchLight.disableTorch();
    } catch (_) {}
    _torchBlinkerRunning = false;
  }
}
