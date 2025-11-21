import 'package:flutter/material.dart';
import 'package:resq_alert/widgets/admin_scaffold.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logs = [
      {"msg": "Fire emergency resolved", "time": "5 min ago"},
      {"msg": "Responder joined: Unit 21", "time": "10 min ago"},
      {"msg": "Medical assistance dispatched", "time": "30 min ago"},
    ];

    return AdminScaffold(
      title: "Notifications",
      selected: AdminMenuItem.notifications,
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: logs.length,
        itemBuilder: (_, i) => Card(
          child: ListTile(
            leading: const Icon(Icons.notifications_active, color: Colors.red),
            title: Text(logs[i]["msg"]!),
            subtitle: Text(logs[i]["time"]!),
          ),
        ),
      ),
    );
  }
}
