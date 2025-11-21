import 'package:flutter/material.dart';
import 'package:resq_alert/widgets/admin_scaffold.dart';

class GuidesScreen extends StatelessWidget {
  const GuidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final guides = [
      {"title": "How to Broadcast Alerts", "file": "Guide PDF"},
      {"title": "Admin Basics", "file": "Getting Started"},
      {"title": "User Permission Rules", "file": "Access Control"},
    ];

    return AdminScaffold(
      title: "Guides",
      selected: AdminMenuItem.guides,
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: guides
            .map((g) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.menu_book, color: Colors.red),
                    title: Text(g["title"]!),
                    subtitle: Text(g["file"]!),
                    trailing: const Icon(Icons.download),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
