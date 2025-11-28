// lib/screens/dashboard_page.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

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

    // Wrap the whole page in WillPopScope so "back" triggers exit-confirm
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
              Text(
                'ResQ Alert',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2),
              Text(
                'Student Safety Dashboard',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () =>
                  Navigator.pushNamed(context, NotificationsPage.routeName),
            )
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
                        Text(
                          'EMERGENCY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Tap for immediate help',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ================= RECENT ALERTS (RTDB) =================
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
                      // header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Alerts',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {
                              // TODO: open map page later
                            },
                            child: const Text(
                              'View Map',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // ======= RTDB STREAM =======
                      StreamBuilder<DatabaseEvent>(
                        stream: FirebaseDatabase.instance
                            .ref('alerts')
                            .orderByChild('timestamp')
                            .limitToLast(5)
                            .onValue,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Failed to load alerts: ${snapshot.error}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }

                          final snap = snapshot.data?.snapshot;
                          if (snap == null || !snap.exists) {
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'No recent alerts.',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }

                          // Build list from children (newest first)
                          final children = snap.children.toList();
                          children.sort((a, b) {
                            final at = (a.child('timestamp').value ?? 0) as num;
                            final bt = (b.child('timestamp').value ?? 0) as num;
                            return bt.compareTo(at); // descending
                          });

                          return Column(
                            children: children.map((c) {
                              final data =
                                  (c.value ?? {}) as Map<dynamic, dynamic>;

                              // 👇 NEW: read both category & specific emergency
                              final category =
                                  (data['category'] ?? 'Emergency') as String;
                              final emergency =
                                  (data['emergency'] ?? 'Emergency') as String;

                              final building = (data['building'] ??
                                  'Unknown building') as String;
                              final floor =
                                  (data['floor'] ?? 'Unknown floor') as String;
                              final room =
                                  (data['room'] ?? 'Unknown room') as String;
                              final status =
                                  (data['status'] ?? 'ACTIVE') as String;

                              // subtitle: specific emergency + location
                              final subtitle =
                                  '$emergency · $floor · $building · $room';

                              final statusColor = _statusColor(status);
                              final iconData = _iconForEmergency(emergency);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: _alertRow(
                                  context,
                                  icon: iconData,
                                  // 👇 Title is now category
                                  title: category,
                                  subtitle: subtitle,
                                  statusLabel: status.toUpperCase(),
                                  statusColor: statusColor,
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ================= EMERGENCY HOTLINES IMAGE =================
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

                // ================= SAFETY TIP CARD =================
                Container(
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFF6C5CE7).withOpacity(0.95), // purple-ish
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
                          'Safety Tip\nAlways keep your emergency contacts updated and '
                          'familiarize yourself with campus evacuation routes.',
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

  // ===== Helper: icon based on emergency text =====
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

  // ===== Helper: status color (supports CRITICAL / ACTIVE / IN PROGRESS / MONITORING / RESOLVED) =====
  Color _statusColor(String status) {
    final s = status.toUpperCase();

    switch (s) {
      case 'CRITICAL':
        return Colors.red;
      case 'ACTIVE':
        return Colors.redAccent;
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

  // ===== Row widget for a single alert =====
  Widget _alertRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String statusLabel,
    required Color statusColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: statusColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title, // category
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle, // specific emergency + location
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // Confirm exit when system back pressed on dashboard
  Future<bool> _onWillPop(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit app?'),
        content:
            const Text('Do you want to exit the app? You will stay logged in.'),
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
