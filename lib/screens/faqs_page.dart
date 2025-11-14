import 'package:flutter/material.dart';

class FaqsPage extends StatelessWidget {
  static const routeName = '/faqs';
  const FaqsPage({super.key});

  final List<Map<String, String>> faqs = const [
    {
      'q': 'How do I send an emergency alert?',
      'a':
          'Tap the red EMERGENCY button on the main dashboard, select the type of emergency, add any additional details, and tap Send Emergency Alert. Help will be dispatched immediately to your location.'
    },
    {
      'q': 'Who receives my emergency alerts?',
      'a':
          'Your alerts are sent to WCC Campus Security, Medical Services, and your designated emergency contacts. Response teams are notified instantly and can track your location.'
    },
    {
      'q': 'Can I cancel an alert after sending?',
      'a':
          'Yes, you can cancel an alert from the Recent Alerts section. However, if responders are already on the way, you should contact Campus Security directly.'
    },
    {
      'q': 'What if I\'m in an area with no internet?',
      'a':
          'The app will attempt to send your alert via SMS when internet is unavailable. Make sure your phone number is updated in your profile settings.'
    },
    {
      'q': 'How do I add emergency contacts?',
      'a':
          'Go to Settings > Emergency Contacts > Add New Contact. Add their name, relationship, and phone number. They will be notified when you send an alert.'
    },
    {
      'q': 'What types of emergencies can I report?',
      'a':
          'You can report Medical Emergencies, Fire Emergencies, Security Threats, Accidents, Natural Disasters, or Other Emergencies. Choose the most relevant type.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Frequently Asked Questions')),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: faqs.length,
          itemBuilder: (context, index) {
            final item = faqs[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                title: Text(item['q']!,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(item['a']!))
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
