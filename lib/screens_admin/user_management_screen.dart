// lib/screens_admin/user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resq_alert/widgets/admin_scaffold.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchCtl = TextEditingController();

  String _searchQuery = '';
  String _roleFilter = 'All'; // All, Student, Teacher, School Staff

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFE53935);

    return AdminScaffold(
      title: "User Management",
      selected: AdminMenuItem.userManagement,
      body: Column(
        children: [
          // ===== TOP FILTER BAR =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar
                TextField(
                  controller: _searchCtl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: "Search by name or ID number",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Role filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _roleChip("All", red),
                      const SizedBox(width: 8),
                      _roleChip("Student", Colors.blue),
                      const SizedBox(width: 8),
                      _roleChip("Teacher", Colors.deepPurple),
                      const SizedBox(width: 8),
                      _roleChip("School Staff", Colors.teal),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ===== USER LIST (STREAM) =====
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No users found."));
                }

                final allDocs = snapshot.data!.docs;

                // Map to user objects and sort alphabetically (case-insensitive)
                final allUsers = allDocs
                    .map((d) => _UserRecord.fromDoc(d))
                    .toList()
                  ..sort((a, b) =>
                      a.name.toLowerCase().compareTo(b.name.toLowerCase()));

                // Filter by role
                List<_UserRecord> filtered = allUsers.where((u) {
                  if (_roleFilter == 'All') return true;
                  return u.role == _roleFilter;
                }).toList();

                // Filter by search (name or id)
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered.where((u) {
                    final name = u.name.toLowerCase();
                    final idNum = u.idNumber.toLowerCase();
                    return name.contains(_searchQuery) ||
                        idNum.contains(_searchQuery);
                  }).toList();
                }

                // Group by role for display sections
                final students =
                    filtered.where((u) => u.role == 'Student').toList();
                final teachers =
                    filtered.where((u) => u.role == 'Teacher').toList();
                final staff =
                    filtered.where((u) => u.role == 'School Staff').toList();

                // If filter is not All, we still want nice section structure
                final List<Widget> children = [];

                void addSection(String title, List<_UserRecord> list) {
                  if (list.isEmpty) return;
                  children.add(Padding(
                    padding:
                        const EdgeInsets.only(left: 16, right: 16, top: 16),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ));
                  children.add(const SizedBox(height: 8));
                  children.addAll(
                    list.map((u) => _UserCard(
                          user: u,
                          onTap: () => _showUserDetails(context, u),
                          onDelete: () => _confirmAndDeleteUser(context, u),
                        )),
                  );
                  children.add(const SizedBox(height: 12));
                }

                if (_roleFilter == 'All') {
                  addSection("Students", students);
                  addSection("Teachers", teachers);
                  addSection("School Staff", staff);
                } else if (_roleFilter == 'Student') {
                  addSection("Students", students);
                } else if (_roleFilter == 'Teacher') {
                  addSection("Teachers", teachers);
                } else if (_roleFilter == 'School Staff') {
                  addSection("School Staff", staff);
                }

                if (children.isEmpty) {
                  return const Center(
                    child: Text("No users match your filters."),
                  );
                }

                return ListView(
                  children: children,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===== ROLE FILTER CHIP WIDGET =====
  Widget _roleChip(String label, Color color) {
    final bool selected = _roleFilter == label;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontSize: 12,
        ),
      ),
      selected: selected,
      selectedColor: color,
      backgroundColor: Colors.grey.shade100,
      onSelected: (_) {
        setState(() {
          _roleFilter = label;
        });
      },
    );
  }

  // ===== DETAIL POPUP =====
  void _showUserDetails(BuildContext context, _UserRecord user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.red.shade50,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(user.role),
                  )
                ],
              ),
              const SizedBox(height: 16),
              if (user.idNumber.isNotEmpty)
                _detailRow("ID Number", user.idNumber),
              if (user.yearLevel.isNotEmpty && user.role == "Student")
                _detailRow("Year Level", user.yearLevel),
              if (user.email.isNotEmpty) _detailRow("Email", user.email),
              if (user.contactNumber.isNotEmpty)
                _detailRow("Contact", user.contactNumber),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _confirmAndDeleteUser(context, user);
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text(
                      "Delete user",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ===== CONFIRM + DELETE =====
  Future<void> _confirmAndDeleteUser(BuildContext ctx, _UserRecord user) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(child: Text('Delete user')),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${user.name}" (ID: ${user.idNumber})? '
            'This action will permanently remove the user from the database.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dCtx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dCtx).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // Perform delete
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .delete();

      if (!mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text('Deleted "${user.name}"'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text('Failed to delete user: $e'),
        ),
      );
    }
  }
}

// ===== DATA MODEL FOR USER ROW =====
class _UserRecord {
  final String id; // Firestore document id
  final String name;
  final String role;
  final String idNumber;
  final String yearLevel;
  final String contactNumber;
  final String email;

  _UserRecord({
    required this.id,
    required this.name,
    required this.role,
    required this.idNumber,
    required this.yearLevel,
    required this.contactNumber,
    required this.email,
  });

  factory _UserRecord.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return _UserRecord(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      role: (data['role'] ?? '').toString(),
      idNumber: (data['idNumber'] ?? '').toString(),
      yearLevel: (data['yearLevel'] ?? '').toString(),
      contactNumber: (data['contactNumber'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
    );
  }
}

// ===== CARD FOR LIST VIEW =====
class _UserCard extends StatelessWidget {
  final _UserRecord user;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Color roleColor;
    if (user.role == 'Student') {
      roleColor = Colors.blue;
    } else if (user.role == 'Teacher') {
      roleColor = Colors.deepPurple;
    } else if (user.role == 'School Staff') {
      roleColor = Colors.teal;
    } else {
      roleColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: roleColor.withOpacity(.12),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: roleColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ID + role
            Row(
              children: [
                Text(
                  "ID: ${user.idNumber}",
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(width: 8),
                Text(
                  "• ${user.role}",
                  style: TextStyle(
                    fontSize: 12,
                    color: roleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            // Year level only for students
            if (user.role == "Student" && user.yearLevel.isNotEmpty)
              Text(
                "Year Level: ${user.yearLevel}",
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            Text(
              "Contact: ${user.contactNumber}",
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: onDelete,
          tooltip: 'Delete user',
        ),
      ),
    );
  }
}
