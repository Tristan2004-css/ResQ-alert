import 'package:flutter/material.dart';

class ContactUsPage extends StatelessWidget {
  static const routeName = '/contact_us';
  const ContactUsPage({super.key});

  Widget _card(String title, String subtitle, IconData icon, String phone, String email, String hours) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          CircleAvatar(radius: 26, child: Icon(icon, size: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(subtitle, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 6),
              Row(children: [Icon(Icons.phone, size: 14, color: Colors.black54), const SizedBox(width: 6), Text(phone)]),
              const SizedBox(height: 4),
              Row(children: [Icon(Icons.email, size: 14, color: Colors.black54), const SizedBox(width: 6), Text(email)]),
              const SizedBox(height: 4),
              Text(hours, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ]),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _card('Campus Security', '24/7 Emergency Hotline', Icons.security, '0945-294-0608', 'security@wcc.edu', 'Available 24/7'),
            _card('Medical Services', 'Campus Health Center', Icons.local_hospital, '3438-4580', 'health@wcc.edu', 'Mon-Fri: 8AM-5PM'),
            _card('IT Support', 'App Technical Support', Icons.settings, '123-456-7890', 'support@wcc.edu', 'Mon-Fri: 8AM-6PM'),
          ]),
        ),
      ),
    );
  }
}
