import 'package:flutter/material.dart';

class EmergencyContactsPage extends StatelessWidget {
  static const routeName = '/settings/emergency_contacts';
  const EmergencyContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    const red = Color(0xFFC82323);
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contacts')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Card(
                child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: const Text('Tristan Balbuena'),
                    subtitle: const Text('Mother\n(123) 456-7891'),
                    trailing: TextButton(
                        onPressed: () {}, child: const Text('Edit')))),
            const SizedBox(height: 8),
            Card(
                child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: const Text('Miguel Arriola'),
                    subtitle: const Text('Father\n(123) 456-7892'),
                    trailing: TextButton(
                        onPressed: () {}, child: const Text('Edit')))),
            const SizedBox(height: 12),
            ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Add New Contact')),
          ]),
        ),
      ),
    );
  }
}
