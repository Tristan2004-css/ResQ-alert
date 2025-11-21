import 'package:flutter/material.dart';
import 'package:resq_alert/widgets/admin_scaffold.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: "Help & Support",
      selected: AdminMenuItem.helpSupport,
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: const [
          _HelpItem(Icons.email, "Email Support", "support@resq-alert.com"),
          _HelpItem(Icons.call, "Call Support", "+123 456 789"),
          _HelpItem(Icons.chat, "Live Chat", "24/7 support"),
          _HelpItem(Icons.bug_report, "Report a Bug", "Submit issue"),
        ],
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _HelpItem(this.icon, this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.red),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
