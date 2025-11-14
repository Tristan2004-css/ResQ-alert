// lib/main.dart
import 'package:flutter/material.dart';

// Import all screens you have in lib/screens/
import 'screens/landing_page.dart';
import 'screens/login_page.dart';
import 'screens/user_login_page.dart';
import 'screens/register_page.dart';
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

void main() {
  runApp(const ResQApp());
}

class ResQApp extends StatelessWidget {
  const ResQApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Primary app color used across screens
    const Color primaryRed = Color(0xFFC82323);

    // Centralized routes map (simple WidgetBuilder)
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      LandingPage.routeName: (_) => const LandingPage(),
      LoginPage.routeName: (_) => const LoginPage(),
      UserLoginPage.routeName: (_) => const UserLoginPage(),
      RegisterPage.routeName: (_) => const RegisterPage(),
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
    };

    return MaterialApp(
      title: 'ResQ Alert',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: primaryRed,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryRed,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(backgroundColor: primaryRed),
        ),
      ),

      // Which page to show first (adjust to LandingPage or LoginPage as you prefer)
      initialRoute: LandingPage.routeName,

      // Provide the named routes map
      routes: routes,

      // Universal smooth fade+slide transition for all named routes (keeps pushNamed behavior)
      onGenerateRoute: (RouteSettings settings) {
        final name = settings.name;
        final WidgetBuilder? builder = routes[name];

        // If route is not registered, return null (lets Flutter fallback or throw)
        if (builder == null) return null;

        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: const Duration(milliseconds: 360),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // combine fade & subtle slide from the right
            final fade =
                CurvedAnimation(parent: animation, curve: Curves.easeInOut);
            final offsetAnim =
                Tween<Offset>(begin: const Offset(0.08, 0.0), end: Offset.zero)
                    .chain(CurveTween(curve: Curves.easeInOut))
                    .animate(animation);

            return FadeTransition(
                opacity: fade,
                child: SlideTransition(position: offsetAnim, child: child));
          },
        );
      },
    );
  }
}
