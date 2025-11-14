import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  static const routeName = '/profile';
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFC82323);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Information')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            CircleAvatar(radius: 36, backgroundColor: red, child: const Text('CV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            const Text('Cass Veraque', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(child: SingleChildScrollView(child: Column(children: [
              TextFormField(decoration: const InputDecoration(labelText: 'First Name')),
              const SizedBox(height: 8),
              TextFormField(decoration: const InputDecoration(labelText: 'Last Name')),
              const SizedBox(height: 8),
              TextFormField(decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 8),
              TextFormField(decoration: const InputDecoration(labelText: 'Contact Number')),
              const SizedBox(height: 8),
              TextFormField(decoration: const InputDecoration(labelText: 'Year Level')),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved (demo)'))), style: ElevatedButton.styleFrom(backgroundColor: red), child: const Text('Save Changes')),
            ]))),
          ]),
        ),
      ),
    );
  }
}
