import 'package:flutter/material.dart';
import 'emergency_contacts_page.dart';

class SettingsPage extends StatelessWidget {
  static const routeName = '/settings';
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    const red = Color(0xFFC82323);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notifications'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/notifications')),
            ListTile(
                leading: const Icon(Icons.contact_phone),
                title: const Text('Emergency Contacts'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(
                    context, EmergencyContactsPage.routeName)),
            ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Privacy & Security'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/change_password')),
            ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Help & Info'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/help_info')),
          ],
        ),
      ),
    );
  }
}
