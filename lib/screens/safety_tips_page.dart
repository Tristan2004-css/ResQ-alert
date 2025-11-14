import 'package:flutter/material.dart';

class SafetyTipsPage extends StatelessWidget {
  static const routeName = '/safety_tips';
  const SafetyTipsPage({super.key});

  final List<Map<String,String>> tips = const [
    {'title': 'Stay Aware', 'desc': 'Always be aware of your surroundings and trust your instincts.'},
    {'title': 'Know your Routes', 'desc': 'Familiarize yourself with emergency exits and evacuation routes.'},
    {'title': 'Keep Contacts Updated', 'desc': 'Ensure emergency contacts and your phone number are current.'},
    {'title': 'Walk in Groups', 'desc': 'When possible, walk with friends or classmates.'},
    {'title': 'Report Concerns', 'desc': 'Report suspicious activity to campus security.'},
    {'title': 'Emergency Preparedness', 'desc': 'Keep your phone charged and know location of first aid stations.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safety Tips')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: tips.length,
          separatorBuilder: (_,__) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final t = tips[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(backgroundColor: Colors.blue.shade50, child: Text('${index+1}', style: const TextStyle(color: Colors.black))),
                title: Text(t['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(t['desc']!),
              ),
            );
          },
        ),
      ),
    );
  }
}
