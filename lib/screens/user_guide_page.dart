import 'package:flutter/material.dart';

class UserGuidePage extends StatelessWidget {
  static const routeName = '/user_guide';
  const UserGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    const red = Color(0xFFC82323);
    return Scaffold(
      appBar: AppBar(title: const Text('User Guide')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            const Text('Getting Started',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Card(child: ListTile(title: const Text('1. Set Up Your Profile'))),
            Card(child: ListTile(title: const Text('2. Enable Notifications'))),
            Card(child: ListTile(title: const Text('3. You\'re Ready!'))),
            const SizedBox(height: 12),
            const Text('How to Report an Emergency',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
                child: ListTile(
                    title: const Text('Step 1: Tap Emergency Button'))),
            Card(
                child: ListTile(
                    title: const Text('Step 2: Select Emergency Type'))),
            Card(
                child: ListTile(
                    title: const Text('Step 3: Add Details and Send'))),
          ]),
        ),
      ),
    );
  }
}
