import 'package:flutter/material.dart';
import 'package:resq_alert/widgets/admin_scaffold.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final users = List.generate(
      10,
      (i) => {
        "name": "Responder ${i + 1}",
        "role": i % 3 == 0 ? "Admin" : "Responder",
        "status": i % 2 == 0 ? "Active" : "Offline",
      },
    );

    return AdminScaffold(
      title: "User Management",
      selected: AdminMenuItem.userManagement,
      fab: FloatingActionButton(
        backgroundColor: const Color(0xFFE53935),
        child: const Icon(Icons.person_add),
        onPressed: () {},
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (_, i) => _UserCard(user: users[i]),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    bool active = user["status"] == "Active";

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.shade100,
          child:
              Text(user["name"][0], style: const TextStyle(color: Colors.red)),
        ),
        title: Text(user["name"]),
        subtitle: Text(user["role"]),
        trailing: Text(
          user["status"],
          style: TextStyle(
            color: active ? Colors.green : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
