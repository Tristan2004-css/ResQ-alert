// lib/main.dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:torch_light/torch_light.dart';
import 'package:audioplayers/audioplayers.dart';

import 'firebase_options.dart';

// ================= USER SCREENS =================
import 'screens/landing_page.dart';
import 'screens/login_page.dart';
import 'screens/user_login_page.dart';
import 'screens/user_register_page.dart';
import 'screens/dashboard_page.dart';
import 'screens/emergency_page.dart';
import 'screens/profile_page.dart';
import 'screens/settings_page.dart';
import 'screens/emergency_contacts_page.dart';
import 'screens/user_guide_page.dart';
import 'screens/help_info_page.dart';
import 'screens/faqs_page.dart';
import 'screens/emergency_types_page.dart';
import 'screens/contact_us_page.dart';
import 'screens/safety_tips_page.dart';
import 'screens/change_password_page.dart';
import 'screens/notifications_page.dart';
import 'screens/my_reports_page.dart';

// ================= ADMIN SCREENS =================
import 'screens_admin/login_screen.dart';
import 'screens_admin/dashboard_screen.dart';
import 'screens_admin/active_alerts_screen.dart';
import 'screens_admin/user_management_screen.dart';
import 'screens_admin/reports_analytics_screen.dart';
import 'screens_admin/broadcast_alert_screen.dart';
import 'screens_admin/account_settings_screen.dart';
import 'screens_admin/help_support_screen.dart';
import 'screens_admin/faqs_screen.dart';
import 'screens_admin/guides_screen.dart';
import 'screens_admin/notifications_screen.dart';
import 'screens_admin/user_reports_screen.dart'; // ✅ user reports

// ----- Local notifications globals -----
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const String channelId = 'emergency_alerts_channel';
const String channelName = 'Emergency Alerts';
const String channelDesc = 'High priority emergency alerts';

Future<void> _initLocalNotifications() async {
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final DarwinInitializationSettings iosInit = DarwinInitializationSettings(
    requestSoundPermission: true,
    requestBadgePermission: true,
    requestAlertPermission: true,
  );

  final InitializationSettings initSettings =
      InitializationSettings(android: androidInit, iOS: iosInit);

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // Create Android channel (importance high so it can show full-screen intents if needed)
  final AndroidNotificationChannel channel = AndroidNotificationChannel(
    channelId,
    channelName,
    description: channelDesc,
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 250, 100, 250]),
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

/// Show a local emergency notification. This is used by NotificationService.
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
        'alert_sound'), // optional raw resource
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 250, 100, 250]),
    visibility: NotificationVisibility.public,
  );

  final iosDetails = DarwinNotificationDetails(
    presentSound: true,
    presentAlert: true,
    presentBadge: true,
  );

  final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

  final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  await flutterLocalNotificationsPlugin.show(
    id,
    title,
    body,
    details,
    payload: data != null ? data.toString() : null,
  );

  // Play an extra app sound using audioplayers (optional)
  try {
    final player = AudioPlayer();
    await player.play(AssetSource('sounds/alert.mp3'));
  } catch (_) {}

  // Blink device flash once (best effort)
  try {
    await TorchLight.enableTorch();
    await Future.delayed(const Duration(milliseconds: 140));
    await TorchLight.disableTorch();
  } catch (_) {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // init notifications
  await _initLocalNotifications();

  runApp(const RootApp());
}

class RootApp extends StatelessWidget {
  const RootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ResQ Alert',
      debugShowCheckedModeBanner: false,
      initialRoute: LandingPage.routeName,
      routes: {
        // -------- USER ROUTES --------
        LandingPage.routeName: (_) => const LandingPage(),
        LoginPage.routeName: (_) => const LoginPage(),
        UserLoginPage.routeName: (_) => const UserLoginPage(),
        UserRegisterPage.routeName: (_) => const UserRegisterPage(),
        DashboardPage.routeName: (_) => const DashboardPage(),
        EmergencyPage.routeName: (_) => const EmergencyPage(),
        ProfilePage.routeName: (_) => const ProfilePage(),
        SettingsPage.routeName: (_) => const SettingsPage(),
        EmergencyContactsPage.routeName: (_) => const EmergencyContactsPage(),
        UserGuidePage.routeName: (_) => const UserGuidePage(),
        HelpInfoPage.routeName: (_) => const HelpInfoPage(),
        FaqsPage.routeName: (_) => const FaqsPage(),
        EmergencyTypesPage.routeName: (_) => const EmergencyTypesPage(),
        ContactUsPage.routeName: (_) => const ContactUsPage(),
        SafetyTipsPage.routeName: (_) => const SafetyTipsPage(),
        ChangePasswordPage.routeName: (_) => const ChangePasswordPage(),
        NotificationsPage.routeName: (_) => const NotificationsPage(),
        MyReportsPage.routeName: (_) => const MyReportsPage(),

        // -------- ADMIN ROUTES --------
        LoginScreen.routeName: (_) => const LoginScreen(),
        '/Dashboard': (_) => const DashboardScreen(),
        '/Active Alerts': (_) => const ActiveAlertsScreen(),
        '/User Management': (_) => const UserManagementScreen(),
        '/Reports & Analytics': (_) => const ReportsAnalyticsScreen(),
        '/admin/broadcast': (_) => const BroadcastAlertScreen(),
        '/Account Settings': (_) => const AccountSettingsScreen(),
        '/Help & Support': (_) => const HelpSupportScreen(),
        '/FAQs': (_) => const FaqsScreen(),
        '/Guides': (_) => const GuidesScreen(),
        '/Notifications': (_) => const NotificationsScreen(),

        // ✅ NEW: User Reports screen
        '/admin/user-reports': (_) => const UserReportsScreen(),
      },
    );
  }
}
