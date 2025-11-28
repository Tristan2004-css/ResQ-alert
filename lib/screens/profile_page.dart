// lib/screens/profile_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  static const routeName = '/profile';
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _idNumberCtl = TextEditingController();
  final _contactCtl = TextEditingController();
  final _guardianNameCtl = TextEditingController();
  final _guardianPhoneCtl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  // Role + school/year values (editable now)
  String? _role; // Student / Teacher / School Staff
  String? _school; // 'SHS' or 'College' (for students)
  String? _yearLevel; // grade or college year (depends on _school)

  // Options
  final List<String> _roles = ['Student', 'Teacher', 'School Staff'];
  final List<String> _shsLevels = ['Grade 11', 'Grade 12'];
  final List<String> _collegeYears = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year'
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _idNumberCtl.dispose();
    _contactCtl.dispose();
    _guardianNameCtl.dispose();
    _guardianPhoneCtl.dispose();
    super.dispose();
  }

  void _show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _loadProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _show('No logged-in user. Please log in again.');
        if (mounted) Navigator.pop(context);
        return;
      }

      final uid = user.uid;
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!doc.exists) {
        // if profile doc missing, at least show email
        _emailCtl.text = user.email ?? '';
        _show('Profile not found, showing basic info.');
      } else {
        final data = doc.data() as Map<String, dynamic>;

        _nameCtl.text = (data['name'] ?? '').toString();
        _emailCtl.text = (data['email'] ?? user.email ?? '').toString();
        _idNumberCtl.text = (data['idNumber'] ?? '').toString();
        _contactCtl.text = (data['contactNumber'] ?? '').toString();

        _role = (data['role'] ?? '').toString().isEmpty
            ? null
            : (data['role'] ?? '').toString();
        _school = (data['school'] ?? '').toString().isEmpty
            ? null
            : (data['school'] ?? '').toString();
        final yr = (data['yearLevel'] ?? '').toString();
        _yearLevel = yr.isNotEmpty ? yr : null;

        _guardianNameCtl.text = (data['guardianName'] ?? '').toString();
        _guardianPhoneCtl.text = (data['guardianPhone'] ?? '').toString();
      }
    } catch (e) {
      _show('Failed to load profile: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // phone validator same behavior as register
  String? _phoneValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter your phone number';
    String raw = v.replaceAll(RegExp(r'[^0-9+]'), '');
    if (!raw.startsWith('+639')) return 'Phone must start with +639';
    if (raw.length != 13) return 'Phone must be +639XXXXXXXXX';
    return null;
  }

  // id validator only for Student
  String? _idValidator(String? v) {
    if (_role != 'Student') return null;
    if (v == null || v.trim().isEmpty) return 'Enter your ID number';
    if (v.trim().length < 4) return 'ID too short';
    return null;
  }

  // guardian phone formatting helper (same as register)

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // if role is student, ensure school/year selected
    if (_role == 'Student') {
      if (_school == null || _school!.isEmpty) {
        _show('Please select SHS or College.');
        return;
      }
      if (_yearLevel == null || _yearLevel!.isEmpty) {
        _show('Please select your year/grade level.');
        return;
      }
    }

    setState(() => _saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _show('No logged-in user.');
        return;
      }
      final uid = user.uid;

      final contactNumber = _contactCtl.text.replaceAll(RegExp(r'[^0-9+]'), '');
      final guardianPhone =
          _guardianPhoneCtl.text.replaceAll(RegExp(r'[^0-9+]'), '');
      final Map<String, dynamic> payload = {
        'name': _nameCtl.text.trim(),
        // email is read-only, but keep it in firestore for consistency
        'email': _emailCtl.text.trim(),
        'contactNumber': contactNumber,
      };

      // role editable now — save if provided
      if (_role != null && _role!.isNotEmpty) {
        payload['role'] = _role;
      }

      // If student, save idNumber, school and yearLevel, guardian fields
      if (_role == 'Student') {
        payload['idNumber'] = _idNumberCtl.text.trim();
        if (_school != null) payload['school'] = _school;
        if (_yearLevel != null) payload['yearLevel'] = _yearLevel;
        if (_guardianNameCtl.text.trim().isNotEmpty) {
          payload['guardianName'] = _guardianNameCtl.text.trim();
        } else {
          payload['guardianName'] = '';
        }
        if (guardianPhone.isNotEmpty) {
          payload['guardianPhone'] = guardianPhone;
        } else {
          payload['guardianPhone'] = '';
        }
      } else {
        // user is not student: remove student-specific fields from the document
        payload['idNumber'] = FieldValue.delete();
        payload['school'] = FieldValue.delete();
        payload['yearLevel'] = FieldValue.delete();
        payload['guardianName'] = FieldValue.delete();
        payload['guardianPhone'] = FieldValue.delete();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(payload, SetOptions(merge: true));

      _show('Profile updated successfully.');
    } catch (e) {
      _show('Failed to update profile: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _idHelperTextForSchool() {
    if (_school == 'SHS') {
      return 'e.g. 23-SHS00123';
    } else if (_school == 'College') {
      return 'e.g. 22-QC02377';
    }
    return '';
  }

  Future<bool> _confirmChangingRole(
      BuildContext context, String? newRole) async {
    // If switching away from Student, confirm because student fields will be removed
    if (_role == 'Student' && newRole != 'Student') {
      final res = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Change role?'),
          content: const Text(
              'Changing role away from Student will remove student-specific details (ID, school, year, guardian). Continue?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Yes, continue')),
          ],
        ),
      );
      return res ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFC82323);

    // Simple, clean styles for inputs
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: red,
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Header card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [red, red.withOpacity(0.85)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: Colors.white24,
                            child: Text(
                              _nameCtl.text.isNotEmpty
                                  ? _nameCtl.text
                                      .trim()
                                      .split(' ')
                                      .where((e) => e.isNotEmpty)
                                      .take(2)
                                      .map((e) => e[0].toUpperCase())
                                      .join()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nameCtl.text.isNotEmpty
                                      ? _nameCtl.text
                                      : 'Your Name',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _role ?? 'No role set',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.9)),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _emailCtl.text,
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.95),
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Card with form fields
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Name
                              TextFormField(
                                controller: _nameCtl,
                                decoration:
                                    inputDecoration.copyWith(labelText: 'Name'),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Enter your name'
                                    : null,
                              ),
                              const SizedBox(height: 12),

                              // Role dropdown
                              DropdownButtonFormField<String>(
                                value: _role,
                                decoration:
                                    inputDecoration.copyWith(labelText: 'Role'),
                                items: _roles
                                    .map((r) => DropdownMenuItem(
                                          value: r,
                                          child: Text(r),
                                        ))
                                    .toList(),
                                onChanged: (val) async {
                                  final ok =
                                      await _confirmChangingRole(context, val);
                                  if (!ok) return;
                                  setState(() {
                                    _role = val;
                                    if (_role != 'Student') {
                                      _idNumberCtl.clear();
                                      _school = null;
                                      _yearLevel = null;
                                      _guardianNameCtl.clear();
                                      _guardianPhoneCtl.clear();
                                    }
                                  });
                                },
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Select role'
                                    : null,
                              ),
                              const SizedBox(height: 12),

                              // ID Number (student only)
                              if (_role == 'Student') ...[
                                TextFormField(
                                  controller: _idNumberCtl,
                                  decoration: inputDecoration.copyWith(
                                      labelText: 'ID Number',
                                      helperText: _idHelperTextForSchool()),
                                  validator: _idValidator,
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Contact + Email row
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _contactCtl,
                                      keyboardType: TextInputType.phone,
                                      decoration: inputDecoration.copyWith(
                                          labelText: 'Phone (+63)'),
                                      validator: _phoneValidator,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _emailCtl,
                                      readOnly: true,
                                      decoration: inputDecoration.copyWith(
                                          labelText: 'Email'),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Student-specific school/year + guardian
                              if (_role == 'Student') ...[
                                DropdownButtonFormField<String>(
                                  value: _school,
                                  decoration: inputDecoration.copyWith(
                                      labelText: 'School'),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'SHS',
                                      child: Text('SHS'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'College',
                                      child: Text('College'),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      _school = val;
                                      _yearLevel = null;
                                    });
                                  },
                                  validator: (v) => v == null
                                      ? 'Select SHS or College'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                if (_school == 'SHS')
                                  DropdownButtonFormField<String>(
                                    value: _yearLevel,
                                    decoration: inputDecoration.copyWith(
                                        labelText: 'SHS Grade'),
                                    items: _shsLevels
                                        .map((y) => DropdownMenuItem(
                                              value: y,
                                              child: Text(y),
                                            ))
                                        .toList(),
                                    onChanged: (val) => setState(() {
                                      _yearLevel = val;
                                    }),
                                    validator: (v) =>
                                        v == null ? 'Select grade' : null,
                                  )
                                else if (_school == 'College')
                                  DropdownButtonFormField<String>(
                                    value: _yearLevel,
                                    decoration: inputDecoration.copyWith(
                                        labelText: 'College Year'),
                                    items: _collegeYears
                                        .map((y) => DropdownMenuItem(
                                              value: y,
                                              child: Text(y),
                                            ))
                                        .toList(),
                                    onChanged: (val) => setState(() {
                                      _yearLevel = val;
                                    }),
                                    validator: (v) =>
                                        v == null ? 'Select year' : null,
                                  ),
                                const SizedBox(height: 14),

                                // Guardian read-only fields with small edit button
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Guardian (for emergencies)',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _guardianNameCtl,
                                  readOnly: true,
                                  decoration: inputDecoration.copyWith(
                                    labelText: 'Guardian Name',
                                    suffixIcon: IconButton(
                                      tooltip: 'Edit guardian contact',
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () {
                                        Navigator.pushNamed(context,
                                            '/settings/emergency_contacts');
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _guardianPhoneCtl,
                                  readOnly: true,
                                  decoration: inputDecoration.copyWith(
                                    labelText: 'Guardian Phone (+63)',
                                    suffixIcon: IconButton(
                                      tooltip: 'Edit guardian contact',
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () {
                                        Navigator.pushNamed(context,
                                            '/settings/emergency_contacts');
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],

                              // Save button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _saving ? null : _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: red,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _saving
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Save Changes',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Small helpful footer
                    Text(
                      'Tip: To change guardian contact, use the edit icon next to guardian fields.',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
      ),
    );
  }
}
