// lib/screens/dashboard_page.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/app_drawer.dart';
import 'emergency_page.dart';
import 'notifications_page.dart';

class DashboardPage extends StatelessWidget {
  static const routeName = '/dashboard';
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFC82323);
    const cardRadius = 16.0;

    final uid = FirebaseAuth.instance.currentUser?.uid;

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: red,
          elevation: 0,
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          title: Column(
            children: const [
              Text('ResQ Alert',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 2),
              Text('Student Safety Dashboard', style: TextStyle(fontSize: 12)),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () =>
                  Navigator.pushNamed(context, NotificationsPage.routeName),
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ================= EMERGENCY BIG BUTTON =================
                Container(
                  decoration: BoxDecoration(
                    color: red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  child: InkWell(
                    onTap: () =>
                        Navigator.pushNamed(context, EmergencyPage.routeName),
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.warning_amber_outlined,
                            color: Colors.white, size: 32),
                        SizedBox(height: 8),
                        Text('EMERGENCY',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 6),
                        Text('Tap for immediate help',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ================= MY REPORTS CARD =================
                SizedBox(
                  height: 84,
                  child: InkWell(
                    onTap: () => Navigator.pushNamed(context, '/my-reports'),
                    borderRadius: BorderRadius.circular(12),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: StreamBuilder<DatabaseEvent>(
                          stream: FirebaseDatabase.instance
                              .ref('userAlerts')
                              .orderByChild('timestamp')
                              .onValue,
                          builder: (context, snapshot) {
                            int myCount = 0;

                            if (snapshot.hasData &&
                                snapshot.data!.snapshot.value != null &&
                                uid != null) {
                              final raw = snapshot.data!.snapshot.value
                                  as Map<dynamic, dynamic>;
                              for (final entry in raw.entries) {
                                final d =
                                    Map<String, dynamic>.from(entry.value);
                                if (d['userId'] != null &&
                                    d['userId'].toString() == uid) {
                                  myCount++;
                                }
                              }
                            }

                            return Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: Colors.blue.shade50,
                                  child: Icon(Icons.report_problem_outlined,
                                      color: Colors.blue),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('My Reports',
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.black54)),
                                      Text(myCount.toString(),
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ================= RECENT ALERTS (shows 3 at a time; scroll to see more) =================
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(cardRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Recent Alerts',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: () {},
                            child: const Text('View Map',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // FIX: Use a ListView with fixed height so it displays 3 cards and is scrollable
                      StreamBuilder<DatabaseEvent>(
                        stream: FirebaseDatabase.instance
                            .ref('alerts')
                            .orderByChild('timestamp')
                            .onValue,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                            );
                          }

                          if (snapshot.hasError) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Failed to load alerts: ${snapshot.error}',
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 12),
                              ),
                            );
                          }

                          final snap = snapshot.data?.snapshot;
                          if (snap == null || !snap.exists) {
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('No recent alerts.',
                                  style: TextStyle(
                                      color: Colors.black54, fontSize: 12)),
                            );
                          }

                          // get children list sorted newest first
                          final children = snap.children.toList()
                            ..sort((a, b) {
                              final at =
                                  (a.child('timestamp').value ?? 0) as num;
                              final bt =
                                  (b.child('timestamp').value ?? 0) as num;
                              return bt.compareTo(at);
                            });

                          // ===== NEW: filter out resolved/closed alerts =====
                          final visibleChildren = children.where((c) {
                            final statusValue =
                                (c.child('status').value ?? '').toString();
                            final s = statusValue
                                .toLowerCase()
                                .replaceAll('_', ' ')
                                .trim();
                            // treat resolved/closed as not visible in recent alerts
                            if (s == 'resolved' || s == 'closed') return false;
                            return true;
                          }).toList();

                          // Show a fixed-height ListView that displays 3 cards' worth of space
                          // so the user can scroll vertically to see more alerts.
                          const double singleCardHeight =
                              120; // approx per card
                          final double listHeight = singleCardHeight * 3;

                          return SizedBox(
                            height: listHeight,
                            child: ListView.builder(
                              itemCount: visibleChildren.length,
                              padding: const EdgeInsets.only(top: 6),
                              itemBuilder: (ctx, idx) {
                                final c = visibleChildren[idx];
                                final data =
                                    (c.value ?? {}) as Map<dynamic, dynamic>;

                                final category =
                                    (data['category'] ?? 'Emergency') as String;
                                final emergency = (data['emergency'] ??
                                    'Emergency') as String;
                                final building =
                                    (data['building'] ?? 'Unknown') as String;
                                final floor =
                                    (data['floor'] ?? 'Unknown') as String;
                                final room =
                                    (data['room'] ?? 'Unknown') as String;
                                final status =
                                    (data['status'] ?? 'ACTIVE') as String;

                                final message =
                                    (data['message'] ?? data['details'] ?? '')
                                        .toString();

                                final subtitle =
                                    '$emergency · $floor · $building · $room';

                                return Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 12, left: 0, right: 0),
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 1,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // top row with icon, title and status chip
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: _statusColor(status)
                                                      .withOpacity(0.08),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Icon(
                                                  _iconForEmergency(emergency),
                                                  color: _statusColor(status),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(category,
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                    const SizedBox(height: 4),
                                                    Text(subtitle,
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.black54,
                                                            fontSize: 12)),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: _statusColor(status)
                                                      .withOpacity(0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                child: Text(
                                                  status
                                                      .toString()
                                                      .toUpperCase(),
                                                  style: TextStyle(
                                                    color: _statusColor(status),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          // message box (if any)
                                          if (message.isNotEmpty) ...[
                                            const SizedBox(height: 10),
                                            Container(
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                    color:
                                                        Colors.grey.shade200),
                                              ),
                                              padding: const EdgeInsets.all(10),
                                              child: Text(
                                                message,
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.black87),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ================= HOTLINES =================
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(cardRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/EmergencyHotlines.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ================= SAFETY TIP =================
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.lightbulb_outline, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Safety Tip\nAlways keep your emergency contacts updated '
                          'and familiarize yourself with campus evacuation routes.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== Helpers ==========
  IconData _iconForEmergency(String emergency) {
    final lower = emergency.toLowerCase();
    if (lower.contains('fire')) return Icons.local_fire_department;
    if (lower.contains('medical')) return Icons.medical_services_outlined;
    if (lower.contains('earthquake')) return Icons.house_siding_outlined;
    if (lower.contains('typhoon') ||
        lower.contains('storm') ||
        lower.contains('flood')) {
      return Icons.water_damage_outlined;
    }
    if (lower.contains('security') ||
        lower.contains('intruder') ||
        lower.contains('weapon') ||
        lower.contains('bomb')) {
      return Icons.shield_outlined;
    }
    return Icons.report_problem_outlined;
  }

  Color _statusColor(String status) {
    switch (status.toString().toUpperCase().replaceAll('_', ' ').trim()) {
      case 'CRITICAL':
        return Colors.red;
      case 'ACTIVE':
        return Colors.red;
      case 'IN PROGRESS':
        return Colors.orange;
      case 'MONITORING':
        return Colors.blue;
      case 'RESOLVED':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<bool> _onWillPop(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit app?'),
        content: const Text(
          'Do you want to exit the app? You will stay logged in.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Exit')),
        ],
      ),
    );
    return shouldExit ?? false;
  }
}
