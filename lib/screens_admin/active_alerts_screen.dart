import 'package:flutter/material.dart';
import 'package:resq_alert/widgets/admin_scaffold.dart';

class ActiveAlertsScreen extends StatelessWidget {
  const ActiveAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alerts = [
      {
        "type": "Fire Emergency",
        "location": "Warehouse",
        "status": "CRITICAL",
        "time": "1 min ago"
      },
      {
        "type": "Medical Emergency",
        "location": "Building A - Lab 3",
        "status": "IN PROGRESS",
        "time": "3 min ago"
      },
      {
        "type": "Security Threat",
        "location": "Main Gate",
        "status": "IN PROGRESS",
        "time": "6 min ago"
      },
      {
        "type": "Natural Disaster",
        "location": "City Zone 5",
        "status": "MONITORING",
        "time": "10 min ago"
      },
      {
        "type": "Fire Emergency",
        "location": "Cafeteria",
        "status": "RESOLVED",
        "time": "15 min ago"
      },
    ];

    return AdminScaffold(
      title: "Active Alerts",
      selected: AdminMenuItem.activeAlerts,
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: alerts.length,
        itemBuilder: (context, i) => _AlertCard(data: alerts[i]),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Map data;
  const _AlertCard({required this.data});

  Color _statusColor(String status) {
    switch (status) {
      case "CRITICAL":
        return Colors.red;
      case "IN PROGRESS":
        return Colors.orange;
      case "MONITORING":
        return Colors.blue;
      case "RESOLVED":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor(data["status"]).withOpacity(.15),
          child: Icon(Icons.warning, color: _statusColor(data["status"])),
        ),
        title: Text(data["type"],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${data["location"]} · ${data["time"]}"),
        trailing: Chip(
          label: Text(data["status"],
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          backgroundColor: _statusColor(data["status"]).withOpacity(.12),
          side: BorderSide(color: _statusColor(data["status"])),
        ),
        onTap: () {},
      ),
    );
  }
}
