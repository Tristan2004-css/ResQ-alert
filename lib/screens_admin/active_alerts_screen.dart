// lib/screens_admin/active_alerts_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:resq_alert/widgets/admin_scaffold.dart';

class ActiveAlertsScreen extends StatefulWidget {
  const ActiveAlertsScreen({super.key});

  @override
  State<ActiveAlertsScreen> createState() => _ActiveAlertsScreenState();
}

class _ActiveAlertsScreenState extends State<ActiveAlertsScreen> {
  DatabaseReference get _alertsRef => FirebaseDatabase.instance.ref('alerts');

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: "Active Alerts",
      selected: AdminMenuItem.activeAlerts,
      body: StreamBuilder<DatabaseEvent>(
        stream: _alertsRef.orderByChild('timestamp').onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load alerts: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Text('No alerts found.'),
            );
          }

          final raw = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

          final List<Map<String, dynamic>> alerts =
              raw.entries.map<Map<String, dynamic>>((e) {
            final m = Map<String, dynamic>.from(e.value);
            m['id'] = e.key; // keep alert id for updating status / delete
            return m;
          }).toList();

          // newest first
          alerts.sort(
              (a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (context, i) => _AlertCard(
              data: alerts[i],
              onChangeStatus: (newStatus) async {
                final id = alerts[i]['id'] as String;
                await _updateStatus(id, newStatus);
              },
              onDelete: () async {
                final id = alerts[i]['id'] as String;
                await _confirmAndDeleteAlert(context, id);
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      await _alertsRef.child(id).update({'status': newStatus});
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

  Future<void> _confirmAndDeleteAlert(
      BuildContext parentContext, String id) async {
    // Ask for confirmation using a dialog that returns user's choice
    final confirm = await showDialog<bool>(
      context: parentContext,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete alert?'),
          content:
              const Text('This will permanently delete the alert. Continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    // Show progress indicator (use parentContext) and perform delete
    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _alertsRef.child(id).remove();

      // After async work, ensure widget still mounted before using context
      if (!mounted) return;

      // Dismiss progress dialog
      Navigator.of(parentContext).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      // Dismiss progress dialog
      Navigator.of(parentContext).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete alert: $e')),
      );
    }
  }
}

class _AlertCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Future<void> Function(String newStatus) onChangeStatus;
  final Future<void> Function() onDelete;

  const _AlertCard({
    required this.data,
    required this.onChangeStatus,
    required this.onDelete,
  });

  static const List<String> statusOptions = [
    'CRITICAL',
    'ACTIVE',
    'IN PROGRESS',
    'MONITORING',
    'RESOLVED',
  ];

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case "CRITICAL":
        return Colors.red;
      case "ACTIVE":
        return Colors.redAccent;
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

  void _showStatusSheet(BuildContext context) {
    final currentStatus = (data['status'] ?? 'ACTIVE').toString().toUpperCase();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Text(
                  'Update Alert Status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const Divider(height: 1),
              ...statusOptions.map((s) {
                final selected = s == currentStatus;
                final color = _statusColor(s);
                return ListTile(
                  leading: Icon(
                    selected ? Icons.check_circle : Icons.radio_button_off,
                    color: color,
                  ),
                  title: Text(
                    s,
                    style: TextStyle(
                      color: color,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await onChangeStatus(s);
                  },
                );
              }).toList(),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Change status'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showStatusSheet(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete alert',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  String _formatTimestamp(dynamic ts) {
    try {
      if (ts == null) return '';
      int ms;
      if (ts is int)
        ms = ts;
      else if (ts is double)
        ms = ts.toInt();
      else if (ts is String)
        ms = int.tryParse(ts) ?? 0;
      else
        return '';
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = (data['type'] ?? data['emergency'] ?? 'Emergency').toString();
    final building = (data['building'] ?? '').toString();
    final floor = (data['floor'] ?? '').toString();
    final room = (data['room'] ?? '').toString();
    final status = (data['status'] ?? 'ACTIVE').toString().toUpperCase();
    final timeText = data['timestamp'] != null
        ? _formatTimestamp(data['timestamp'])
        : (data['time'] ?? '').toString();
    final target = (data['target'] ?? '').toString();
    final message = (data['message'] ?? data['details'] ?? '').toString();

    String subtitle = '';
    if (target.isNotEmpty) subtitle += '$target · ';
    if (building.isNotEmpty) subtitle += building;
    if (floor.isNotEmpty) subtitle += ' – $floor';
    if (room.isNotEmpty) subtitle += ' · $room';
    if (timeText.isNotEmpty) subtitle += ' · $timeText';
    if (subtitle.isEmpty) subtitle = 'Location not specified';

    final color = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showStatusSheet(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left colored accent
            Container(
              width: 6,
              height: 120,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),

            // Main content
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + optional target badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            type,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // subtitle / location
                    Text(
                      subtitle,
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black54),
                    ),

                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          message,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black87),
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Actions row: quick status button + menu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _showStatusSheet(context),
                          icon: Icon(Icons.change_circle, color: color),
                          label: Text('Change status',
                              style: TextStyle(color: color)),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'More',
                          icon: const Icon(Icons.more_vert),
                          onPressed: () => _showMoreOptions(context),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon:
                              const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => onDelete(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
