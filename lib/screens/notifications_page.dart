// lib/screens/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsPage extends StatefulWidget {
  static const routeName = '/notifications';
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tc;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    final s = (status).toString().toLowerCase();
    if (s == 'active') return Colors.red;
    if (s == 'in_progress' || s == 'in-progress' || s == 'in progress')
      return Colors.orange;
    if (s == 'resolved') return Colors.green;
    return Colors.grey;
  }

  // Convert RTDB snapshot children to list of maps (most recent first)
  List<Map<String, dynamic>> _itemsFromSnapshot(DatabaseEvent event) {
    final snap = event.snapshot;
    if (snap.value == null) return [];
    final map = Map<dynamic, dynamic>.from(snap.value as Map);
    final items = <Map<String, dynamic>>[];
    for (final entry in map.entries) {
      final rec = Map<String, dynamic>.from(entry.value as Map);
      rec['key'] = entry.key;
      // ensure status and type exist
      rec['status'] = (rec['status'] ?? 'active').toString();
      rec['type'] = (rec['type'] ?? rec['emergency'] ?? 'Alert').toString();
      rec['desc'] = (rec['details'] ??
              rec['message'] ??
              rec['description'] ??
              rec['desc'] ??
              '')
          .toString();
      // timestamp -> readable
      final ts = rec['timestamp'];
      if (ts is int || ts is double) {
        final ms = ts is double ? ts.toInt() : ts as int;
        final dt = DateTime.fromMillisecondsSinceEpoch(ms);
        rec['timeStr'] =
            "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      } else {
        rec['timeStr'] = rec['timeStr'] ?? '';
      }
      items.add(rec);
    }
    // sort newest first by timestamp if available
    items.sort((a, b) {
      final at = (a['timestamp'] ?? 0) as num;
      final bt = (b['timestamp'] ?? 0) as num;
      return bt.compareTo(at);
    });
    return items;
  }

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFC82323);

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    // If not logged in, show friendly message
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(
          child: Text('Please log in to view your notifications.'),
        ),
      );
    }

    final dbRef = FirebaseDatabase.instance
        .ref('userAlerts')
        .orderByChild('userId')
        .equalTo(uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: red,
      ),
      body: SafeArea(
        child: Column(
          children: [
            TabBar(
              controller: _tc,
              labelColor: red,
              unselectedLabelColor: Colors.black54,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Active'),
                Tab(text: 'History'),
              ],
            ),

            // StreamBuilder reads the user's alerts once and we filter per tab
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: dbRef.onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                          'Failed to load notifications: ${snapshot.error}'),
                    );
                  }

                  final items = snapshot.hasData
                      ? _itemsFromSnapshot(snapshot.data!)
                      : <Map<String, dynamic>>[];

                  // Build filtered lists
                  final all = items;
                  final active = items.where((m) {
                    final s = (m['status'] ?? '').toString().toLowerCase();
                    return s == 'active';
                  }).toList();
                  final history = items.where((m) {
                    final s = (m['status'] ?? '').toString().toLowerCase();
                    return s == 'resolved';
                  }).toList();

                  return TabBarView(
                    controller: _tc,
                    children: [
                      _listView(all),
                      _listView(active),
                      _listView(history),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listView(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const Center(child: Text('No notifications'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final it = items[i];
        final statusRaw = (it['status'] ?? 'active').toString();
        statusRaw.toLowerCase();
        final statusColor = _statusColor(statusRaw);

        final title = (it['type'] ?? it['emergency'] ?? 'Alert').toString();
        final desc = (it['desc'] ?? '').toString();
        final timeStr = (it['timeStr'] ?? '').toString();

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row with status chip
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusRaw.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Description
              if (desc.isNotEmpty)
                Text(
                  desc,
                  style: const TextStyle(color: Colors.black54),
                ),

              const SizedBox(height: 8),

              // timestamp / optional additional details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    timeStr,
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                  // Optionally: a view button to open full report (left empty for now)
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) {
                          return AlertDialog(
                            title: Text(title),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (desc.isNotEmpty) Text(desc),
                                const SizedBox(height: 8),
                                Text('Status: ${statusRaw.toUpperCase()}'),
                                if (timeStr.isNotEmpty) Text('Time: $timeStr'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('Close')),
                            ],
                          );
                        },
                      );
                    },
                    child: const Text('View', style: TextStyle(fontSize: 13)),
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
