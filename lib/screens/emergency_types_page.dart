import 'package:flutter/material.dart';

class EmergencyTypesPage extends StatelessWidget {
  static const routeName = '/emergency_types';
  const EmergencyTypesPage({super.key});

  final List<Map<String,String>> types = const [
    {'title': 'Medical Emergency', 'desc': 'Illness or health crisis requiring immediate medical attention', 'asset': 'assets/em_medical.png'},
    {'title': 'Fire Emergency', 'desc': 'Active fire or smoke detected on campus', 'asset': 'assets/em_fire.png'},
    {'title': 'Security Threat', 'desc': 'Dangerous person, violent or security concern', 'asset': 'assets/em_security.png'},
    {'title': 'Accident', 'desc': 'Vehicle or other incidents causing injury', 'asset': 'assets/em_accident.png'},
    {'title': 'Natural Disaster', 'desc': 'Weather or natural event threatening safety', 'asset': 'assets/em_natural.png'},
    {'title': 'Other Emergency', 'desc': 'Any urgent situation not listed above', 'asset': 'assets/em_other.png'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Types')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          separatorBuilder: (_,__) => const SizedBox(height: 12),
          itemCount: types.length,
          itemBuilder: (context, index) {
            final t = types[index];
            return ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: SizedBox(width: 56, height: 56, child: Image.asset(t['asset']!, fit: BoxFit.contain)),
              title: Text(t['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(t['desc']!, style: const TextStyle(color: Colors.black54)),
              onTap: () { /* optional detail */ },
            );
          },
        ),
      ),
    );
  }
}
