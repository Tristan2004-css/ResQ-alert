// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/dashboard_page.dart';
import '../screens/profile_page.dart';
import '../screens/settings_page.dart';
import '../screens/emergency_contacts_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<Map<String, dynamic>?> _getUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final snap =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!snap.exists) return null;
    return snap.data() as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    const headerColor = Color(0xFFC82323);

    return Drawer(
      child: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _getUser(),
          builder: (context, snapshot) {
            // loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // error state
            if (snapshot.hasError) {
              return Column(
                children: [
                  Container(
                    color: headerColor,
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: const Text('Error loading profile',
                        style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Failed to load profile: ${snapshot.error}'),
                  ),
                  const Spacer(),
                  ListTile(
                    leading: const Icon(Icons.exit_to_app, color: Colors.red),
                    title: const Text('Logout',
                        style: TextStyle(color: Colors.red)),
                    onTap: () async {
                      // close drawer then logout
                      Navigator.pop(context);
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacementNamed(context, '/user_login');
                    },
                  ),
                ],
              );
            }

            // data (may be null if user doc missing)
            final data = snapshot.data;
            final name = (data?['name'] ?? 'Unknown User').toString();
            final idNum = (data?['idNumber'] ?? '---').toString();
            final role = (data?['role'] ?? '').toString();

            // initials for avatar (safe)
            String initials = 'U';
            if (name.trim().isNotEmpty) {
              final parts = name
                  .trim()
                  .split(RegExp(r'\s+'))
                  .where((s) => s.isNotEmpty)
                  .toList();
              if (parts.length >= 2) {
                initials = (parts[0][0] + parts[1][0]).toUpperCase();
              } else {
                initials = parts[0][0].toUpperCase();
              }
            }

            // helper to navigate and close drawer
            void _navTo(String routeName) {
              Navigator.pop(context); // close drawer first
              Navigator.pushReplacementNamed(context, routeName);
            }

            return Column(
              children: [
                // header
                Container(
                  color: headerColor,
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Color(0xFFC82323),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "ID: $idNum",
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // menu
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Dashboard'),
                  onTap: () => _navTo(DashboardPage.routeName),
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profile'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, ProfilePage.routeName);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, SettingsPage.routeName);
                  },
                ),

                // emergency contacts only for students
                if (role.toLowerCase() == 'student')
                  ListTile(
                    leading: const Icon(Icons.contact_phone),
                    title: const Text('Emergency Contacts'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                          context, EmergencyContactsPage.routeName);
                    },
                  ),

                const Spacer(),

                // logout
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.red),
                  title:
                      const Text('Logout', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context); // close drawer first
                    await FirebaseAuth.instance.signOut();
                    // After sign out redirect to user login
                    Navigator.pushReplacementNamed(context, '/user_login');
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
