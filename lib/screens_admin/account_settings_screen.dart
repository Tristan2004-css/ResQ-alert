import 'package:flutter/material.dart';
import 'package:resq_alert/widgets/admin_scaffold.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final name = TextEditingController(text: "Admin User");
    final email = TextEditingController(text: "admin@resq-alert.com");
    final phone = TextEditingController(text: "+123 456 789");

    return AdminScaffold(
      title: "Account Settings",
      selected: AdminMenuItem.accountSettings,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _input("Full Name", name, Icons.person),
          const SizedBox(height: 12),
          _input("Email", email, Icons.email),
          const SizedBox(height: 12),
          _input("Phone Number", phone, Icons.phone),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Profile Updated")));
              },
              child: const Text(
                "Save Changes",
                style: TextStyle(color: Colors.white),
              ),
            ),
          )
        ]),
      ),
    );
  }

  Widget _input(String label, TextEditingController ctrl, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            labelText: label,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
