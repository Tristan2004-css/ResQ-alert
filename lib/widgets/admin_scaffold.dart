import 'package:flutter/material.dart';
import 'package:resq_alert/screens/login_page.dart';

enum AdminMenuItem {
  dashboard,
  activeAlerts,
  userManagement,
  reports,
  accountSettings,
  helpSupport,
  faqs,
  guides,
  notifications,
}

class AdminScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final AdminMenuItem selected;
  final FloatingActionButton? fab;

  const AdminScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.selected,
    this.fab,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          // ⛔️ Broadcast button removed successfully

          // Logout only
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                LoginPage.routeName,
                (_) => false,
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: body,
      floatingActionButton: fab,
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Color(0xFFE53935)),
            currentAccountPicture: CircleAvatar(child: Text("AD")),
            accountName: Text("Admin User"),
            accountEmail: Text("admin@resq-alert.com"),
          ),
          _item(context, AdminMenuItem.dashboard, Icons.dashboard, "Dashboard"),
          _item(context, AdminMenuItem.activeAlerts, Icons.warning,
              "Active Alerts"),
          _item(context, AdminMenuItem.userManagement, Icons.group,
              "User Management"),
          _item(context, AdminMenuItem.reports, Icons.bar_chart,
              "Reports & Analytics"),
          const Divider(),
          _item(context, AdminMenuItem.accountSettings, Icons.person,
              "Account Settings"),
          _item(
              context, AdminMenuItem.helpSupport, Icons.help, "Help & Support"),
          _item(context, AdminMenuItem.faqs, Icons.question_answer, "FAQs"),
          _item(context, AdminMenuItem.guides, Icons.menu_book, "Guides"),
          _item(context, AdminMenuItem.notifications, Icons.notifications,
              "Notifications"),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context,
    AdminMenuItem item,
    IconData icon,
    String label,
  ) {
    final bool isSelected = selected == item;

    const routes = <AdminMenuItem, String>{
      AdminMenuItem.dashboard: '/Dashboard',
      AdminMenuItem.activeAlerts: '/Active Alerts',
      AdminMenuItem.userManagement: '/User Management',
      AdminMenuItem.reports: '/Reports & Analytics',
      AdminMenuItem.accountSettings: '/Account Settings',
      AdminMenuItem.helpSupport: '/Help & Support',
      AdminMenuItem.faqs: '/FAQs',
      AdminMenuItem.guides: '/Guides',
      AdminMenuItem.notifications: '/Notifications',
    };

    final route = routes[item];
    if (route == null) {
      return const SizedBox.shrink();
    }

    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.red : null),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.red : null,
        ),
      ),
      selected: isSelected,
      onTap: () {
        Navigator.of(context).pop();
        final currentRoute = ModalRoute.of(context)?.settings.name;

        if (currentRoute != route) {
          Navigator.pushNamed(context, route);
        }
      },
    );
  }
}
