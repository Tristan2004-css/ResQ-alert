// lib/screens_admin/user_reports_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:resq_alert/widgets/admin_scaffold.dart';

class UserReportsScreen extends StatelessWidget {
  const UserReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: "User Reports",
      selected: AdminMenuItem.reports,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "User Emergency Reports",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "These alerts were triggered by students / staff from the app.",
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),

            // ===== LIVE LIST FROM REALTIME DATABASE =====
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: FirebaseDatabase.instance
                    .ref('userAlerts')
                    .orderByChild('timestamp')
                    .onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Failed to load user reports: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    );
                  }

                  final snap = snapshot.data?.snapshot;
                  if (snap == null || !snap.exists) {
                    return const Center(
                      child: Text(
                        'No user reports yet.',
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                    );
                  }

                  final children = snap.children.toList();

                  // newest first
                  children.sort((a, b) {
                    final at = (a.child('timestamp').value ?? 0) as num;
                    final bt = (b.child('timestamp').value ?? 0) as num;
                    return bt.compareTo(at);
                  });

                  return ListView.builder(
                    itemCount: children.length,
                    itemBuilder: (context, index) {
                      final c = children[index];
                      final keyId = c.key ?? '';
                      final data = (c.value ?? {}) as Map<dynamic, dynamic>;

                      final name =
                          (data['userName'] ?? 'Unknown user').toString();
                      final idNumber = (data['idNumber'] ?? '').toString();
                      final type = (data['type'] ?? 'Emergency').toString();
                      final floor =
                          (data['floor'] ?? 'Unknown floor').toString();
                      final details = (data['details'] ?? '').toString();
                      final status = (data['status'] ?? 'active').toString();
                      final timeMs = (data['timestamp'] ?? 0) as num;

                      final date =
                          DateTime.fromMillisecondsSinceEpoch(timeMs.toInt());
                      final timeStr =
                          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} "
                          "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

                      return _UserAlertRow(
                        keyId: keyId,
                        name: name,
                        idNumber: idNumber,
                        emergencyType: type,
                        floor: floor,
                        details: details,
                        status: status,
                        timeLabel: timeStr,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Converted to StatefulWidget so we can use `mounted` safely in async callbacks
class _UserAlertRow extends StatefulWidget {
  final String keyId;
  final String name;
  final String idNumber;
  final String emergencyType;
  final String floor;
  final String details;
  final String status;
  final String timeLabel;

  const _UserAlertRow({
    required this.keyId,
    required this.name,
    required this.idNumber,
    required this.emergencyType,
    required this.floor,
    required this.details,
    required this.status,
    required this.timeLabel,
    Key? key,
  }) : super(key: key);

  @override
  State<_UserAlertRow> createState() => _UserAlertRowState();
}

class _UserAlertRowState extends State<_UserAlertRow> {
  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'active') return Colors.red;
    if (s == 'in_progress' || s == 'in-progress' || s == 'in progress')
      return Colors.orange;
    if (s == 'monitoring') return Colors.blue;
    if (s == 'resolved') return Colors.green;
    return Colors.grey;
  }

  Future<void> _updateStatus(
      BuildContext context, String newStatus, String keyId) async {
    try {
      await FirebaseDatabase.instance
          .ref('userAlerts')
          .child(keyId)
          .update({'status': newStatus});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $newStatus')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  Future<void> _confirmAndDelete(BuildContext context, String keyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete report?'),
          content: const Text(
              'Are you sure you want to permanently delete this user report? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // show a simple progress dialog while deleting
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await FirebaseDatabase.instance.ref('userAlerts').child(keyId).remove();

      // ensure widget is still in the tree before using context
      if (!mounted) return;

      // Dismiss progress dialog safely
      if (Navigator.canPop(context)) Navigator.of(context).pop();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report deleted')),
      );
    } catch (e) {
      // Dismiss progress if still open, then show error
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete report: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(widget.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(.15),
          child: Icon(Icons.person, color: statusColor),
        ),
        title: Text(
          widget.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.idNumber.isNotEmpty)
              Text("ID: ${widget.idNumber}",
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
            Text(
              widget.emergencyType,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            Text(
              "${widget.floor} • ${widget.timeLabel}",
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            if (widget.details.isNotEmpty)
              Text(
                widget.details,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'active') {
              await _updateStatus(context, 'active', widget.keyId);
            } else if (value == 'in_progress') {
              await _updateStatus(context, 'in_progress', widget.keyId);
            } else if (value == 'resolved') {
              await _updateStatus(context, 'resolved', widget.keyId);
            } else if (value == 'delete') {
              await _confirmAndDelete(context, widget.keyId);
            }
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: 'active',
              child: Row(
                children: const [
                  Icon(Icons.radio_button_checked, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Mark as ACTIVE'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'in_progress',
              child: Row(
                children: const [
                  Icon(Icons.radio_button_checked, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Mark as IN-PROGRESS'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'resolved',
              child: Row(
                children: const [
                  Icon(Icons.radio_button_checked, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Mark as RESOLVED'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: const [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete Report'),
                ],
              ),
            ),
          ],
          child: Chip(
            label: Text(
              widget.status.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: statusColor,
          ),
        ),
        onTap: () {
          // optional: show details dialog / expand — left empty for now
        },
      ),
    );
  }
}
