// lib/screens_admin/reports_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:resq_alert/widgets/admin_scaffold.dart';

class ReportsAnalyticsScreen extends StatelessWidget {
  const ReportsAnalyticsScreen({super.key});

  DatabaseReference get _alertsRef => FirebaseDatabase.instance.ref('alerts');
  DatabaseReference get _userReportsRef =>
      FirebaseDatabase.instance.ref('userAlerts');

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: "Reports & Analytics",
      selected: AdminMenuItem.reports,
      // Outer StreamBuilder listens for alerts (all alerts)
      body: StreamBuilder<DatabaseEvent>(
        stream: _alertsRef.onValue,
        builder: (context, alertsSnapshot) {
          // Counters derived from alerts
          int total = 0;
          int resolved = 0;
          int active = 0;

          // Categories according to emergency list
          int security = 0;
          int safety = 0;
          int natural = 0;
          int other = 0;

          if (alertsSnapshot.hasData &&
              alertsSnapshot.data!.snapshot.value is Map<dynamic, dynamic>) {
            final raw =
                alertsSnapshot.data!.snapshot.value as Map<dynamic, dynamic>;

            raw.forEach((key, value) {
              final data = Map<String, dynamic>.from(value);

              final status =
                  (data['status'] ?? 'ACTIVE').toString().toUpperCase();
              final typeText =
                  (data['type'] ?? data['emergency'] ?? 'Unknown').toString();
              final lower = typeText.toLowerCase();

              total++;

              if (status == 'RESOLVED') {
                resolved++;
              } else {
                active++;
              }

              // ===== CATEGORY DETECTION =====
              if (lower.contains('intruder') ||
                  lower.contains('unauthorized') ||
                  lower.contains('weapon') ||
                  lower.contains('bomb') ||
                  lower.contains('security')) {
                security++;
              } else if (lower.contains('fire') ||
                  lower.contains('gas') ||
                  lower.contains('chemical') ||
                  lower.contains('power') ||
                  lower.contains('structural') ||
                  lower.contains('medical') ||
                  lower.contains('safety')) {
                safety++;
              } else if (lower.contains('earthquake') ||
                  lower.contains('typhoon') ||
                  lower.contains('flood') ||
                  lower.contains('storm') ||
                  lower.contains('volcanic') ||
                  lower.contains('natural')) {
                natural++;
              } else {
                other++;
              }
            });
          }

          final resolvedPercent =
              total == 0 ? 0 : ((resolved / total) * 100).round();

          // Now nest a StreamBuilder for userReports (userAlerts) so we get realtime count
          return StreamBuilder<DatabaseEvent>(
            stream: _userReportsRef.onValue,
            builder: (context, userReportsSnapshot) {
              int userReportsCount = 0;
              int urActive = 0;
              int urInProgress = 0;
              int urResolved = 0;

              if (userReportsSnapshot.hasData &&
                  userReportsSnapshot.data!.snapshot.value
                      is Map<dynamic, dynamic>) {
                final uraw = userReportsSnapshot.data!.snapshot.value
                    as Map<dynamic, dynamic>;

                userReportsCount = uraw.length;

                // Count by status
                uraw.forEach((key, value) {
                  final d = Map<String, dynamic>.from(value);
                  final s = (d['status'] ?? 'active').toString().toLowerCase();
                  if (s == 'active')
                    urActive++;
                  else if (s == 'in_progress' ||
                      s == 'in-progress' ||
                      s == 'in progress') {
                    urInProgress++;
                  } else if (s == 'resolved') {
                    urResolved++;
                  } else {
                    // treat unknown as active-ish
                    urActive++;
                  }
                });
              } else if (userReportsSnapshot.hasData &&
                  userReportsSnapshot.data!.snapshot.value == null) {
                userReportsCount = 0;
                urActive = urInProgress = urResolved = 0;
              }

              // Determine max for chart scaling
              int maxType = [security, safety, natural, other]
                  .reduce((a, b) => a > b ? a : b);
              if (maxType == 0) maxType = 1;

              final breakdown = "$security / $safety / $natural / $other";

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _ReportCard(
                      icon: Icons.analytics,
                      color: Colors.indigo,
                      title: "Total Alerts",
                      value: "$total",
                      subtitle: "All-time alerts recorded",
                    ),
                    const SizedBox(height: 12),

                    _ReportCard(
                      icon: Icons.warning_amber_rounded,
                      color: Colors.redAccent,
                      title: "Active Alerts",
                      value: "$active",
                      subtitle: "Currently ongoing emergencies",
                    ),
                    const SizedBox(height: 12),

                    _ReportCard(
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                      title: "Resolved Alerts",
                      value: "$resolved",
                      subtitle: "Completed & closed",
                    ),
                    const SizedBox(height: 12),

                    // TAPPABLE user reports card with breakdown in subtitle
                    _ReportCard(
                      icon: Icons.person_search_outlined,
                      color: Colors.blue,
                      title: "User Reports",
                      value: "$userReportsCount",
                      subtitle:
                          "Submitted by users (live) — $urActive active · $urInProgress in-progress · $urResolved resolved",
                      onTap: () {
                        Navigator.pushNamed(context, '/admin/user-reports');
                      },
                    ),
                    const SizedBox(height: 12),

                    _ReportCard(
                      icon: Icons.timeline_outlined,
                      color: Colors.deepPurple,
                      title: "Resolution Rate",
                      value: "$resolvedPercent%",
                      subtitle: total == 0
                          ? "No alerts yet"
                          : "$resolved of $total resolved",
                    ),

                    const SizedBox(height: 20),

                    // CATEGORY SECTION TITLE
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Emergency Breakdown by Category",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    _ReportCard(
                      icon: Icons.pie_chart_outline,
                      color: Colors.blue,
                      title: "By Type",
                      value: breakdown,
                      subtitle: "Security / Safety / Natural Disaster / Other",
                    ),

                    const SizedBox(height: 10),

                    // BAR CHART
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            _typeBar(
                              label: "Security",
                              count: security,
                              max: maxType,
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 6),
                            _typeBar(
                              label: "Safety",
                              count: safety,
                              max: maxType,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 6),
                            _typeBar(
                              label: "Natural Disaster",
                              count: natural,
                              max: maxType,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 6),
                            _typeBar(
                              label: "Other",
                              count: other,
                              max: maxType,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _typeBar({
    required String label,
    required int count,
    required int max,
    required Color color,
  }) {
    final fraction = max <= 0 ? 0.0 : (count / max);

    return Row(
      children: [
        SizedBox(width: 120, child: Text(label)),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: fraction.clamp(0, 1),
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text("$count"),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String subtitle;
  final VoidCallback? onTap;

  const _ReportCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(.9),
              color.withOpacity(.7),
            ],
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white.withOpacity(.2),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            Text(value,
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
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
