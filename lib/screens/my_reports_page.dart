// lib/screens/my_reports_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyReportsPage extends StatelessWidget {
  static const routeName = '/my-reports';
  const MyReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: uid == null
            ? const Center(child: Text('Not logged in'))
            : StreamBuilder<DatabaseEvent>(
                stream: FirebaseDatabase.instance
                    .ref('userAlerts')
                    .orderByChild('timestamp')
                    .onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2));
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Failed to load reports: ${snapshot.error}'),
                    );
                  }

                  final snap = snapshot.data?.snapshot;
                  if (snap == null || !snap.exists) {
                    return const Center(child: Text('No reports yet.'));
                  }

                  // Safely iterate children to collect current user's reports
                  final allChildren = snap.children.toList();
                  final List<DataSnapshot> mine = [];

                  for (final child in allChildren) {
                    try {
                      final map = (child.value ?? {}) as Map<dynamic, dynamic>;
                      final ruid = map['userId'];
                      if (ruid != null && ruid.toString() == uid) {
                        mine.add(child);
                      }
                    } catch (_) {
                      // ignore malformed child and continue
                      continue;
                    }
                  }

                  if (mine.isEmpty) {
                    return const Center(child: Text('You have no reports.'));
                  }

                  // Sort newest-first using timestamp if available
                  mine.sort((a, b) {
                    num at = 0;
                    num bt = 0;
                    try {
                      at = (a.child('timestamp').value ?? 0) as num;
                    } catch (_) {
                      at = 0;
                    }
                    try {
                      bt = (b.child('timestamp').value ?? 0) as num;
                    } catch (_) {
                      bt = 0;
                    }
                    return bt.compareTo(at);
                  });

                  return ListView.separated(
                    itemCount: mine.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final s = mine[index];
                      final key = s.key ?? '';
                      final data = (s.value ?? {}) as Map<dynamic, dynamic>;

                      final type =
                          (data['type'] ?? data['emergency'] ?? 'Report')
                              .toString();
                      final details =
                          (data['details'] ?? data['message'] ?? '').toString();
                      final floor =
                          (data['floor'] ?? data['location'] ?? '').toString();
                      final room = (data['room'] ?? '').toString();

                      // timestamp safe parsing
                      num timeMs = 0;
                      try {
                        timeMs = (data['timestamp'] ?? 0) as num;
                      } catch (_) {
                        timeMs = 0;
                      }
                      final status = (data['status'] ?? 'active').toString();

                      final date =
                          DateTime.fromMillisecondsSinceEpoch((timeMs).toInt());
                      final timeStr = timeMs > 0
                          ? "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} "
                              "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}"
                          : 'Unknown time';

                      Color statusColor() {
                        final s = status.toLowerCase();
                        if (s == 'active') return Colors.red;
                        if (s.contains('in_prog') ||
                            s.contains('in progress') ||
                            s.contains('in-progress')) return Colors.orange;
                        if (s == 'monitoring') return Colors.blue;
                        if (s == 'resolved') return Colors.green;
                        return Colors.grey;
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: statusColor().withOpacity(.12),
                            child: Icon(Icons.report, color: statusColor()),
                          ),
                          title: Text(type,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (floor.isNotEmpty || room.isNotEmpty)
                                Text(
                                  [floor, room]
                                      .where((x) => x.isNotEmpty)
                                      .join(' · '),
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black54),
                                ),
                              if (details.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(details,
                                    style: const TextStyle(fontSize: 13)),
                              ],
                              const SizedBox(height: 6),
                              Text(timeStr,
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.black45)),
                            ],
                          ),
                          trailing: Chip(
                            label: Text(status.toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                            backgroundColor: statusColor(),
                          ),
                          isThreeLine: true,
                          onTap: () => _showDetailsDialog(context, key, data),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  void _showDetailsDialog(
      BuildContext context, String key, Map<dynamic, dynamic> data) {
    final type = (data['type'] ?? data['emergency'] ?? 'Report').toString();
    final details = (data['details'] ?? data['message'] ?? '').toString();
    final floor = (data['floor'] ?? '').toString();
    final room = (data['room'] ?? '').toString();
    final status = (data['status'] ?? '').toString();
    final reporter =
        (data['userName'] ?? data['reporterName'] ?? '').toString();

    num timeMs = 0;
    try {
      timeMs = (data['timestamp'] ?? 0) as num;
    } catch (_) {
      timeMs = 0;
    }

    final date = DateTime.fromMillisecondsSinceEpoch((timeMs).toInt());
    final timeStr = timeMs > 0
        ? "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} "
            "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}"
        : 'Unknown time';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(type),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (reporter.isNotEmpty) Text('By: $reporter'),
              if (floor.isNotEmpty || room.isNotEmpty)
                Text('Location: ${[
                  floor,
                  room
                ].where((x) => x.isNotEmpty).join(' · ')}'),
              const SizedBox(height: 8),
              if (details.isNotEmpty) Text('Details:\n$details'),
              const SizedBox(height: 8),
              Text('Status: ${status.toUpperCase()}'),
              const SizedBox(height: 6),
              Text('Time: $timeStr',
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close')),
        ],
      ),
    );
  }
}
