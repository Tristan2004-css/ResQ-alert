// lib/screens/emergency_contacts_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyContactsPage extends StatelessWidget {
  static const routeName = '/settings/emergency_contacts';
  const EmergencyContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFC82323);

    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar:
          AppBar(title: const Text('Emergency Contacts'), backgroundColor: red),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: currentUser == null
              ? const Center(
                  child: Text(
                    'You must be logged in to view emergency contacts.',
                    textAlign: TextAlign.center,
                  ),
                )
              // Use StreamBuilder so UI updates immediately after saving
              : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser.uid)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snap.hasError) {
                      return Center(
                        child: Text('Error loading contacts: ${snap.error}'),
                      );
                    }

                    if (!snap.hasData || !snap.data!.exists) {
                      return const Center(
                        child: Text(
                          'No profile data found.\nComplete your registration first.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    final data = snap.data!.data() ?? <String, dynamic>{};
                    final guardianName =
                        (data['guardianName'] ?? '').toString().trim();
                    final guardianPhone =
                        (data['guardianPhone'] ?? '').toString().trim();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (guardianName.isNotEmpty || guardianPhone.isNotEmpty)
                          Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.person),
                              ),
                              title: Text(
                                guardianName.isNotEmpty
                                    ? guardianName
                                    : 'Guardian',
                              ),
                              subtitle: Text(
                                guardianPhone.isNotEmpty
                                    ? guardianPhone
                                    : 'No phone number set',
                              ),
                              trailing: TextButton(
                                onPressed: () async {
                                  await _showEditGuardianDialog(
                                    context,
                                    currentUser.uid,
                                    initialName: guardianName,
                                    initialPhone: guardianPhone,
                                  );
                                },
                                child: const Text('Edit'),
                              ),
                            ),
                          )
                        else
                          Card(
                            child: ListTile(
                              leading:
                                  const CircleAvatar(child: Icon(Icons.person)),
                              title: const Text('No guardian saved'),
                              subtitle: const Text(
                                  'Add one so we can contact them in emergencies.'),
                              trailing: TextButton(
                                onPressed: () async {
                                  await _showEditGuardianDialog(
                                    context,
                                    currentUser.uid,
                                    initialName: '',
                                    initialPhone: '',
                                  );
                                },
                                child: const Text('Add'),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await _showEditGuardianDialog(
                              context,
                              currentUser.uid,
                              initialName: guardianName,
                              initialPhone: guardianPhone,
                            );
                          },
                          icon: const Icon(Icons.edit_location_alt),
                          label: const Text('Edit / Add Guardian Contact'),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }

  /// Shows dialog to edit guardian name & phone, validates and updates Firestore.
  Future<void> _showEditGuardianDialog(
    BuildContext context,
    String uid, {
    required String initialName,
    required String initialPhone,
  }) async {
    final _nameCtl = TextEditingController(text: initialName);
    final _phoneCtl = TextEditingController(text: initialPhone);
    final _formKey = GlobalKey<FormState>();
    bool _saving = false;

    // local helper to format phone like +63 9xx xxx xxxx grouping
    void _formatPhone(String value) {
      String digits = value.replaceAll(RegExp(r'[^0-9+]'), '');
      if (!digits.startsWith('+63')) digits = '+63';
      String rest = '';
      if (digits.length > 3) rest = digits.substring(3);
      String formatted;
      if (rest.isEmpty) {
        formatted = '+63';
      } else if (rest.length <= 3) {
        formatted = '+63 $rest';
      } else if (rest.length <= 6) {
        formatted = '+63 ${rest.substring(0, 3)} ${rest.substring(3)}';
      } else {
        formatted =
            '+63 ${rest.substring(0, 3)} ${rest.substring(3, 6)} ${rest.substring(6)}';
      }
      if (formatted != value) {
        // preserve cursor at end since we always append/remove groups
        _phoneCtl.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }

    // show dialog and wait for save/cancel
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Edit Guardian Contact'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameCtl,
                    decoration: const InputDecoration(
                      labelText: 'Guardian Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) {
                      // allow empty to remove contact; otherwise require at least 2 chars
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return null;
                      if (s.length < 2) return 'Enter a valid name';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneCtl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Guardian Phone (+63)',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    onChanged: (v) {
                      // format while typing
                      _formatPhone(v);
                    },
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return null; // allow empty to clear
                      String raw = s.replaceAll(RegExp(r'[^0-9+]'), '');
                      if (!raw.startsWith('+639'))
                        return 'Phone must start with +639';
                      if (raw.length != 13)
                        return 'Phone must be +639XXXXXXXXX';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: _saving
                    ? null
                    : () {
                        Navigator.of(ctx).pop();
                      },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: _saving
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;

                        final name = _nameCtl.text.trim();
                        final phone = _phoneCtl.text
                            .trim()
                            .replaceAll(RegExp(r'[^0-9+]'), '');

                        // if both empty -> treat as remove contact
                        setState(() => _saving = true);
                        try {
                          final Map<String, dynamic> payload = {};
                          if (name.isEmpty && phone.isEmpty) {
                            // delete fields
                            payload['guardianName'] = FieldValue.delete();
                            payload['guardianPhone'] = FieldValue.delete();
                          } else {
                            payload['guardianName'] = name;
                            payload['guardianPhone'] = phone;
                          }

                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .set(
                                payload,
                                SetOptions(merge: true),
                              );

                          if (!ctx.mounted) return;
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                                content: Text('Guardian contact updated.')),
                          );
                          Navigator.of(ctx).pop();
                        } catch (e) {
                          if (!ctx.mounted) return;
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Failed to update: $e')),
                          );
                          setState(() => _saving = false);
                        }
                      },
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          );
        });
      },
    );

    // dispose controllers (they are local)
    _nameCtl.dispose();
    _phoneCtl.dispose();
  }
}
