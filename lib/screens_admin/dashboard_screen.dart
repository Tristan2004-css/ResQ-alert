// lib/screens_admin/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:resq_alert/widgets/admin_scaffold.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  DatabaseReference get _alertsRef => FirebaseDatabase.instance.ref('alerts');
  DatabaseReference get _userAlertsRef =>
      FirebaseDatabase.instance.ref('userAlerts');

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: "Dashboard",
      selected: AdminMenuItem.dashboard,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Today's Overview",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // ======= STATS SECTION (ROW 1 – ALERTS FROM RTDB) =======
            StreamBuilder<DatabaseEvent>(
              stream: _alertsRef.onValue,
              builder: (context, snapshotAlerts) {
                int activeCount = 0;
                int resolvedCount = 0;

                if (snapshotAlerts.hasData &&
                    snapshotAlerts.data!.snapshot.value != null) {
                  final raw = snapshotAlerts.data!.snapshot.value
                      as Map<dynamic, dynamic>;

                  for (final entry in raw.entries) {
                    try {
                      final data = Map<String, dynamic>.from(entry.value);
                      final status =
                          (data['status'] ?? 'ACTIVE').toString().toUpperCase();

                      if (status == 'RESOLVED') {
                        resolvedCount++;
                      } else {
                        activeCount++;
                      }
                    } catch (_) {
                      // ignore malformed entries
                    }
                  }
                }

                // SECOND STREAM for userAlerts count (so it matches UserReportsScreen)
                return StreamBuilder<DatabaseEvent>(
                  stream: _userAlertsRef.onValue,
                  builder: (context, snapshotUserAlerts) {
                    int userReportsCount = 0;

                    if (snapshotUserAlerts.hasData &&
                        snapshotUserAlerts.data!.snapshot.value != null) {
                      final rawUsers = snapshotUserAlerts.data!.snapshot.value;
                      // rawUsers may be a Map or a List depending on data structure
                      if (rawUsers is Map) {
                        userReportsCount = rawUsers.length;
                      } else if (rawUsers is List) {
                        // in case it's a list-like structure
                        userReportsCount =
                            rawUsers.where((e) => e != null).length;
                      }
                    }

                    return Column(
                      children: [
                        _ScrollableStatsRow(
                          cards: [
                            _StatCard(
                              icon: Icons.warning_amber_outlined,
                              label: "Active Alerts",
                              value: activeCount.toString(),
                              color: Colors.red,
                              onTap: () {
                                Navigator.pushNamed(context, '/Active Alerts');
                              },
                            ),
                            _StatCard(
                              icon: Icons.check_circle_outline,
                              label: "Resolved",
                              value: resolvedCount.toString(),
                              color: Colors.green,
                              onTap: () {
                                Navigator.pushNamed(
                                    context, '/Reports & Analytics');
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _ScrollableStatsRow(
                          cards: [
                            _StatCard(
                              icon: Icons.bar_chart,
                              label: "User Reports",
                              // 👇 now uses /userAlerts count
                              value: userReportsCount.toString(),
                              color: Colors.blue,
                              onTap: () {
                                Navigator.pushNamed(
                                    context, '/admin/user-reports');
                              },
                            ),
                            const _UsersCountCard(),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 24),

            // ======= BIG EMERGENCY BROADCAST BUTTON =======
            InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                Navigator.pushNamed(context, '/admin/broadcast');
              },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.warning_rounded, color: Colors.white, size: 40),
                    SizedBox(height: 10),
                    Text(
                      "EMERGENCY",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.1,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Tap to send urgent broadcast",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Recent Emergencies",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // ======= RECENT EMERGENCIES (LIST FROM RTDB) =======
            StreamBuilder<DatabaseEvent>(
              stream:
                  _alertsRef.orderByChild('timestamp').limitToLast(5).onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Failed to load alerts: ${snapshot.error}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      "No recent emergencies.",
                      style: TextStyle(fontSize: 13),
                    ),
                  );
                }

                final raw =
                    snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                final List<Map<String, dynamic>> alerts =
                    raw.entries.map<Map<String, dynamic>>((e) {
                  final m = Map<String, dynamic>.from(e.value);
                  m['id'] = e.key;
                  return m;
                }).toList();

                // newest first
                alerts.sort((a, b) =>
                    (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));

                return Column(
                  children: alerts
                      .map((a) => _AlertTile(
                            data: a,
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Users card uses Firestore snapshot to show live count
class _UsersCountCard extends StatelessWidget {
  const _UsersCountCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        String userCountText = '...';

        if (snapshot.hasData) {
          final count = snapshot.data!.docs.length;
          userCountText = count.toString();
        } else if (snapshot.hasError) {
          userCountText = 'Err';
        }

        return _StatCard(
          icon: Icons.people_alt_outlined,
          label: "Users",
          value: userCountText,
          color: Colors.purple,
          onTap: () {
            Navigator.pushNamed(context, '/User Management');
          },
        );
      },
    );
  }
}

/// Row of stat cards that can scroll horizontally on small screens
class _ScrollableStatsRow extends StatelessWidget {
  final List<Widget> cards;
  const _ScrollableStatsRow({required this.cards});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            SizedBox(width: 180, child: cards[i]),
            if (i != cards.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withOpacity(.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );

    if (onTap == null) return cardContent;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: cardContent,
    );
  }
}

class _AlertTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AlertTile({required this.data});

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

  @override
  Widget build(BuildContext context) {
    final emergency = (data['emergency'] ?? 'Emergency').toString();
    final category = (data['category'] ?? '').toString(); // category as title
    final building = (data['building'] ?? '').toString();
    final room = (data['room'] ?? '').toString();
    final floor = (data['floor'] ?? '').toString();
    final status = (data['status'] ?? 'ACTIVE').toString().toUpperCase();

    // Build full location string
    String locationLine = '';
    if (floor.isNotEmpty) {
      locationLine += floor;
    }
    if (building.isNotEmpty) {
      locationLine += locationLine.isEmpty ? building : ' · $building';
    }
    if (room.isNotEmpty) {
      locationLine += ' · $room';
    }
    if (locationLine.isEmpty) {
      locationLine = 'Location not specified';
    }

    // ✅ Title = category (if present) else emergency
    final titleText = category.isNotEmpty ? category : emergency;

    // ✅ Subtitle = specific emergency + newline + location
    final subtitleText = '$emergency\n$locationLine';

    final statusColor = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(.15),
          child: Icon(Icons.emergency_share, color: statusColor),
        ),
        title: Text(
          titleText,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitleText,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: FittedBox(
          fit: BoxFit.scaleDown,
          child: Chip(
            label: Text(
              status,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: statusColor.withOpacity(0.08),
            side: BorderSide(color: statusColor),
          ),
        ),
        onTap: () => Navigator.pushNamed(context, '/Active Alerts'),
      ),
    );
  }
}
