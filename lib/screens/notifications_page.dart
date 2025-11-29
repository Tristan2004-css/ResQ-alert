// lib/screens/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

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
    final s = status.toString().toLowerCase();
    if (s == 'active' || s == 'critical') return Colors.red;
    if (s == 'in_progress' || s == 'in-progress' || s == 'in progress')
      return Colors.orange;
    if (s == 'monitoring') return Colors.blue;
    if (s == 'resolved' || s == 'closed') return Colors.green;
    return Colors.grey;
  }

  // Convert RTDB /alerts snapshot children to list of maps (most recent first)
  List<Map<String, dynamic>> _itemsFromAlertsSnapshot(DatabaseEvent event) {
    final snap = event.snapshot;
    if (snap.value == null) return [];
    final map = Map<dynamic, dynamic>.from(snap.value as Map);
    final items = <Map<String, dynamic>>[];
    for (final entry in map.entries) {
      final rec = Map<String, dynamic>.from(entry.value as Map);
      rec['key'] = entry.key;
      // normalize fields
      rec['status'] = (rec['status'] ?? 'active').toString();
      rec['type'] =
          (rec['category'] ?? rec['emergency'] ?? 'Broadcast Alert').toString();
      rec['desc'] = (rec['message'] ??
              rec['details'] ??
              rec['description'] ??
              rec['desc'] ??
              '')
          .toString();

      // timestamp -> readable (handle int/double)
      final ts = rec['timestamp'];
      if (ts is int || ts is double) {
        final ms = ts is double ? ts.toInt() : ts as int;
        final dt = DateTime.fromMillisecondsSinceEpoch(ms);
        rec['timeStr'] =
            "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      } else {
        rec['timeStr'] = rec['timeStr'] ?? '';
      }

      // prefer numeric timestamp normalized to int if possible (used for sorting)
      if (ts is int) {
        rec['timestamp'] = ts;
      } else if (ts is double) {
        rec['timestamp'] = ts.toInt();
      } else {
        // fallback: set 0 so it goes to the end
        rec['timestamp'] = rec['timestamp'] ?? 0;
      }

      // keep target if present (useful for debugging)
      rec['target'] = (rec['target'] ?? '').toString();

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

    final alertsRef =
        FirebaseDatabase.instance.ref('alerts').orderByChild('timestamp');

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

            // StreamBuilder reads /alerts only
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: alertsRef.onValue,
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
                      ? _itemsFromAlertsSnapshot(snapshot.data!)
                      : <Map<String, dynamic>>[];

                  // Filtered lists:
                  final allNonResolved = items.where((m) {
                    final s = (m['status'] ?? '').toString().toLowerCase();
                    return s != 'resolved' && s != 'closed';
                  }).toList();

                  final activeList = items.where((m) {
                    final s = (m['status'] ?? '').toString().toLowerCase();
                    return s == 'active' ||
                        s == 'critical' ||
                        s == 'in_progress' ||
                        s == 'in-progress' ||
                        s == 'in progress' ||
                        s == 'monitoring';
                  }).toList();

                  final historyList = items.where((m) {
                    final s = (m['status'] ?? '').toString().toLowerCase();
                    return s == 'resolved' || s == 'closed';
                  }).toList();

                  // --- COUNTS FOR BADGES (live)
                  final totalCount = items.length;
                  final activeCount = activeList.length;
                  final inProgressCount = items.where((m) {
                    final s = (m['status'] ?? '').toString().toLowerCase();
                    return s == 'in_progress' ||
                        s == 'in-progress' ||
                        s == 'in progress';
                  }).length;
                  final monitoringCount = items.where((m) {
                    final s = (m['status'] ?? '').toString().toLowerCase();
                    return s == 'monitoring';
                  }).length;
                  final resolvedCount = historyList.length;

                  // Build the UI with counts + debug section + tab views
                  return Column(
                    children: [
                      // counts row
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _countChip('Total', totalCount, Colors.grey),
                              const SizedBox(width: 8),
                              _countChip('Active', activeCount, Colors.red),
                              const SizedBox(width: 8),
                              _countChip('In-Progress', inProgressCount,
                                  Colors.orange),
                              const SizedBox(width: 8),
                              _countChip(
                                  'Monitoring', monitoringCount, Colors.blue),
                              const SizedBox(width: 8),
                              _countChip(
                                  'Resolved', resolvedCount, Colors.green),
                            ],
                          ),
                        ),
                      ),
                      // main tab content (fills remaining vertical space)
                      Expanded(
                        child: TabBarView(
                          controller: _tc,
                          children: [
                            // All (non-resolved)
                            _boxedListView(allNonResolved),
                            // Active
                            _boxedListView(activeList),
                            // History (resolved/closed)
                            _boxedListView(historyList),
                          ],
                        ),
                      ),
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

  // Build the boxed (card) list view for the given list
  Widget _boxedListView(List<Map<String, dynamic>> items) {
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
                Text(desc, style: const TextStyle(color: Colors.black54)),

              const SizedBox(height: 8),

              // timestamp / optional additional details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(timeStr,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black45)),
                  TextButton(
                    onPressed: () {
                      // show full details dialog
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

  // small helper to create a count chip
  Widget _countChip(String label, int count, Color color) {
    return Chip(
      backgroundColor: color.withOpacity(0.12),
      avatar: CircleAvatar(
        backgroundColor: color,
        child: Text(count.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 12)),
      ),
      label: Text(label),
    );
  }
}
