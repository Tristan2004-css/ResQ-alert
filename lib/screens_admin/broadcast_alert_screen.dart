import 'package:flutter/material.dart';
import 'package:resq_alert/widgets/admin_scaffold.dart';

class BroadcastAlertScreen extends StatefulWidget {
  const BroadcastAlertScreen({super.key});

  @override
  State<BroadcastAlertScreen> createState() => _BroadcastAlertScreenState();
}

class _BroadcastAlertScreenState extends State<BroadcastAlertScreen> {
  String selectedType = "Medical Emergency";
  final message = TextEditingController();

  final types = const [
    "Medical Emergency",
    "Fire Emergency",
    "Security Threat",
    "Natural Disaster",
    "Other Emergency"
  ];

  void _send() {
    if (message.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Message required")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Broadcast Sent: $selectedType")),
    );
    message.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: "Broadcast Alert ",
      // we highlight Dashboard in the drawer while on this screen
      selected: AdminMenuItem.dashboard,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Alert Type",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: types.map((t) {
                final selected = selectedType == t;
                return ChoiceChip(
                  label: Text(t),
                  selected: selected,
                  onSelected: (_) => setState(() => selectedType = t),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),
            const Text(
              "Message",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: message,
                  maxLines: 5,
                  decoration: const InputDecoration.collapsed(
                    hintText: "Type emergency broadcast message...",
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text(
                  "Send Alert",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                onPressed: _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
