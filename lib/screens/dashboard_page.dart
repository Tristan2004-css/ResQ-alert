import 'package:flutter/material.dart';
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

    return Scaffold(
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
              // Emergency big button
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

              // Recent Alerts card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(cardRadius),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04), blurRadius: 8)
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
                        const Text('Recent Alerts',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () {
                            // TODO: view map
                          },
                          child: const Text('View Map',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // list of alerts (sample items)
                    Column(
                      children: [
                        _alertRow(
                          context,
                          icon: Icons.medical_information_outlined,
                          title: 'Medical Emergency',
                          subtitle: 'Bldg A - Room 205 · 10 mins ago',
                          statusLabel: 'active',
                          statusColor: Colors.redAccent,
                        ),
                        const SizedBox(height: 8),
                        _alertRow(
                          context,
                          icon: Icons.report_problem_outlined,
                          title: 'Security Threat',
                          subtitle: 'Campus Gate 2 · 1 hour ago',
                          statusLabel: 'resolved',
                          statusColor: Colors.green,
                        ),
                        const SizedBox(height: 8),
                        _alertRow(
                          context,
                          icon: Icons.local_fire_department,
                          title: 'Fire Emergency',
                          subtitle: 'Laboratory Building · 2 hours ago',
                          statusLabel: 'active',
                          statusColor: Colors.redAccent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Emergency Contacts card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(cardRadius),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04), blurRadius: 8)
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Emergency Contacts',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    // hotline header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('#911',
                            style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold)),
                        Text('NATIONAL EMERGENCY HOTLINE',
                            style:
                                TextStyle(fontSize: 12, color: Colors.black54)),
                        SizedBox(width: 8),
                        Text('#122',
                            style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold)),
                        Text('QUEZON CITY HOTLINE',
                            style:
                                TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // icons / contact logos row (replace placeholders with real images)
                    SizedBox(
                      height: 72,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _contactLogoPlaceholder('SECURITY'),
                          const SizedBox(width: 8),
                          _contactLogoPlaceholder('SAFETY'),
                          const SizedBox(width: 8),
                          _contactLogoPlaceholder('SCHOOL'),
                          const SizedBox(width: 8),
                          _contactLogoPlaceholder('MEDICAL'),
                          const SizedBox(width: 8),
                          _contactLogoPlaceholder('RED CROSS'),
                          const SizedBox(width: 8),
                          _contactLogoPlaceholder('DOH'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Safety tip purple card
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
                        'Safety Tip\nAlways keep your emergency contacts updated and familiarize yourself with campus evacuation routes.',
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
    );
  }

  // small helper widgets used above
  Widget _alertRow(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required String statusLabel,
      required Color statusColor}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: statusColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ]),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16)),
          child: Text(statusLabel,
              style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ),
      ],
    );
  }

  Widget _contactLogoPlaceholder(String label) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        // replace Container below with Image.asset('assets/your_logo.png') when you add logos
        Container(width: 40, height: 28, color: Colors.grey.shade200),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
      ]),
    );
  }
}
