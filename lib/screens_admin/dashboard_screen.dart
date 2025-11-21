import 'package:flutter/material.dart';
// if your package name is different, adjust this:
import 'package:resq_alert/widgets/admin_scaffold.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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

            // ======= STATS SECTION (HORIZONTAL SCROLL, NO OVERFLOW) =======
            _ScrollableStatsRow(
              cards: const [
                _StatCard(
                  icon: Icons.warning_amber_outlined,
                  label: "Active Alerts",
                  value: "23",
                  color: Colors.red,
                ),
                _StatCard(
                  icon: Icons.check_circle_outline,
                  label: "Resolved",
                  value: "47",
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ScrollableStatsRow(
              cards: const [
                _StatCard(
                  icon: Icons.timer_outlined,
                  label: "Avg Response",
                  value: "2.5m",
                  color: Colors.orange,
                ),
                _StatCard(
                  icon: Icons.person_add_alt_1_outlined,
                  label: "New Users",
                  value: "12",
                  color: Colors.blue,
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text(
              "Recent Emergencies",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ...List.generate(5, (i) => const _AlertTile()),
          ],
        ),
      ),
    );
  }
}

/// Row of stat cards that can scroll horizontally on small screens
/// so it never overflows.
class _ScrollableStatsRow extends StatelessWidget {
  final List<_StatCard> cards;
  const _ScrollableStatsRow({required this.cards});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            SizedBox(
              width: 180, // width per card; adjust if you like
              child: cards[i],
            ),
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

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
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
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.red,
          child: Icon(Icons.emergency_share, color: Colors.white),
        ),
        title: const Text("Medical Emergency"),
        subtitle: const Text("Building A - Room 203 · 2 min ago"),
        // make sure trailing never forces overflow
        trailing: FittedBox(
          fit: BoxFit.scaleDown,
          child: Chip(
            label: const Text(
              "ACTIVE",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.red.shade50,
            side: BorderSide(color: Colors.red.shade300),
          ),
        ),
        onTap: () => Navigator.pushNamed(context, '/admin/active-alerts'),
      ),
    );
  }
}
