import 'package:flutter/material.dart';
import 'faqs_page.dart';
import 'emergency_types_page.dart';
import 'contact_us_page.dart';
import 'safety_tips_page.dart';
import 'user_guide_page.dart';

class HelpInfoPage extends StatelessWidget {
  static const routeName = '/help_info';
  const HelpInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    const red = Color(0xFFC82323);
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Information')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _helpCard(
                    context,
                    'FAQs',
                    'Common questions',
                    Icons.help_outline,
                    () => Navigator.pushNamed(context, FaqsPage.routeName)),
                _helpCard(
                    context,
                    'User Guide',
                    'How to use app',
                    Icons.menu_book_outlined,
                    () =>
                        Navigator.pushNamed(context, UserGuidePage.routeName)),
                _helpCard(
                    context,
                    'Emergency Types',
                    'What to report',
                    Icons.warning_amber_outlined,
                    () => Navigator.pushNamed(
                        context, EmergencyTypesPage.routeName)),
                _helpCard(
                    context,
                    'Contact Us',
                    'Get in touch',
                    Icons.phone_in_talk,
                    () =>
                        Navigator.pushNamed(context, ContactUsPage.routeName)),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              tileColor: Colors.purple.shade50,
              title: const Text('Safety Tips',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('View helpful tips and best practices'),
              trailing: TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, SafetyTipsPage.routeName),
                  child: const Text('View All')),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('About Rescue Alert',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text(
                              'A comprehensive safety app designed to keep World Citi Colleges students safe and connected.'),
                          const Spacer(),
                          Center(
                              child: SizedBox(
                                  height: 80,
                                  child: Image.asset(
                                      'assets/help_about_placeholder.png',
                                      fit: BoxFit.contain))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _helpCard(BuildContext context, String title, String subtitle,
      IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2)),
            ]),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 32, color: const Color(0xFFC82323)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ]),
      ),
    );
  }
}
