import 'package:flutter/material.dart';
import '../screens/dashboard_page.dart';
import '../screens/profile_page.dart';
import '../screens/settings_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(children: [
          Container(
              color: const Color(0xFFC82323),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Row(children: const [
                CircleAvatar(radius: 28, child: Text('CV')),
                SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Cass Veraque',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('ID: 22-CO02271',
                      style: TextStyle(color: Colors.white70))
                ]),
              ])),
          ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pushReplacementNamed(
                  context, DashboardPage.routeName)),
          ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () => Navigator.pushNamed(context, ProfilePage.routeName)),
          ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () =>
                  Navigator.pushNamed(context, SettingsPage.routeName)),
          const Spacer(),
          ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.popUntil(context, (route) => route.isFirst);
                Navigator.pushReplacementNamed(context, '/login');
              }),
        ]),
      ),
    );
  }
}
