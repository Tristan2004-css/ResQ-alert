// lib/screens/user_register_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserRegisterPage extends StatefulWidget {
  static const routeName = '/register';
  const UserRegisterPage({super.key});

  @override
  State<UserRegisterPage> createState() => _UserRegisterPageState();
}

class _UserRegisterPageState extends State<UserRegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _idNumberCtl = TextEditingController();
  final _contactCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _confirmPassCtl = TextEditingController();
  final _guardianNameCtl = TextEditingController();
  final _guardianPhoneCtl = TextEditingController();

  bool _loading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  // Roles
  final List<String> _roles = [
    'Student',
    'Teacher',
    'School Staff',
  ];
  String? _selectedRole;

  // School selection (when Student)
  String? _selectedSchool; // 'SHS' or 'College'

  // SHS levels
  final List<String> _shsLevels = [
    'Grade 11',
    'Grade 12',
  ];
  String? _selectedShsLevel;

  // College years
  final List<String> _collegeYears = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
  ];
  String? _selectedCollegeYear;

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _idNumberCtl.dispose();
    _contactCtl.dispose();
    _passCtl.dispose();
    _confirmPassCtl.dispose();
    _guardianNameCtl.dispose();
    _guardianPhoneCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Additional student-specific validation
    if (_selectedRole == 'Student') {
      if (_selectedSchool == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select SHS or College.')),
        );
        return;
      }
      if (_selectedSchool == 'SHS' && _selectedShsLevel == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select SHS grade level.')),
        );
        return;
      }
      if (_selectedSchool == 'College' && _selectedCollegeYear == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select college year.')),
        );
        return;
      }
    }

    setState(() => _loading = true);

    final name = _nameCtl.text.trim();
    final email = _emailCtl.text.trim();
    final idNumber = _selectedRole == 'Student' ? _idNumberCtl.text.trim() : '';
    final contactNumber = _contactCtl.text.replaceAll(RegExp(r'[^0-9+]'), '');
    final password = _passCtl.text.trim();
    final guardianName = _guardianNameCtl.text.trim();
    final guardianPhone =
        _guardianPhoneCtl.text.replaceAll(RegExp(r'[^0-9+]'), '');

    final role = _selectedRole!;
    String? school;
    String? yearLevel;
    if (role == 'Student') {
      school = _selectedSchool;
      yearLevel =
          _selectedSchool == 'SHS' ? _selectedShsLevel : _selectedCollegeYear;
    }

    try {
      // 1️⃣ Create Auth user
      debugPrint('AUTH: creating user for $email');
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = cred.user;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration failed: no user returned'),
            ),
          );
        }
        return;
      }

      final uid = user.uid;
      debugPrint('AUTH: user created with uid=$uid');

      // 2️⃣ Build Firestore data
      final Map<String, dynamic> userData = {
        'name': name,
        'email': email,
        'contactNumber': contactNumber,
        'role': role,
        if (idNumber.isNotEmpty) 'idNumber': idNumber,
        if (school != null) 'school': school,
        if (yearLevel != null) 'yearLevel': yearLevel,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (guardianName.isNotEmpty || guardianPhone.isNotEmpty) {
        userData['guardianName'] = guardianName;
        userData['guardianPhone'] = guardianPhone;
      }

      // 3️⃣ Write to Firestore /users/{uid}
      try {
        debugPrint('FIRESTORE: writing users/$uid');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(userData);
        debugPrint('FIRESTORE: users/$uid write OK');
      } on FirebaseException catch (fe) {
        debugPrint(
          'FIRESTORE ERROR: code=${fe.code}, message=${fe.message}, details=${fe.stackTrace}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Firestore write failed (${fe.code}): ${fe.message ?? 'Unknown error'}',
              ),
            ),
          );
        }
        // rollback auth user if Firestore failed
        await user.delete();
        return;
      }

      // 4️⃣ Send verification email
      try {
        debugPrint('AUTH: sending email verification');
        await user.sendEmailVerification();
      } catch (e) {
        debugPrint('AUTH: sendEmailVerification error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send verification email: $e')),
          );
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Registered! Please verify your email before logging in.'),
        ),
      );

      await FirebaseAuth.instance.signOut();

      Navigator.pushReplacementNamed(context, '/user_login');
    } on FirebaseAuthException catch (e) {
      debugPrint('AUTH ERROR: code=${e.code}, message=${e.message}');
      String msg = 'Registration failed';
      if (e.code == 'email-already-in-use') {
        msg = 'An account already exists for that email.';
      } else if (e.code == 'weak-password') {
        msg = 'Password is too weak.';
      } else if (e.message != null) {
        msg = e.message!;
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e, st) {
      debugPrint('UNKNOWN ERROR during register: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _idHelperTextForSchool() {
    if (_selectedSchool == 'SHS') {
      return 'e.g. 23-SHS00123';
    } else if (_selectedSchool == 'College') {
      return 'e.g. 22-QC02377';
    }
    return '';
  }

  String? _validateIdForSchool(String? v) {
    if (_selectedRole != 'Student') return null;
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Enter your ID number';
    // basic length check (adjust to your preferred pattern)
    if (value.length < 4) return 'ID too short';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFC82323);

    return Scaffold(
      backgroundColor: red,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/whitelog.png',
                    height: 90,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image, size: 72),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Create your Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Fill in your details to get started.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // WHITE CARD
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 22),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // BASIC INFO
                          Row(
                            children: const [
                              Icon(Icons.person_add_alt_1,
                                  color: red, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Basic Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _nameCtl,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v!.isEmpty ? 'Enter your name' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailCtl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final value = v?.trim() ?? '';
                              if (value.isEmpty) return 'Enter your email';
                              if (!value.contains('@') ||
                                  !value.contains('.')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _contactCtl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number (+63)',
                              prefixIcon: Icon(Icons.phone_outlined),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              String digits =
                                  value.replaceAll(RegExp(r'[^0-9+]'), '');
                              if (!digits.startsWith('+63')) digits = '+63';
                              String rest = '';
                              if (digits.length > 3) {
                                rest = digits.substring(3);
                              }
                              String formatted;
                              if (rest.isEmpty) {
                                formatted = '+63';
                              } else if (rest.length <= 3) {
                                formatted = '+63 $rest';
                              } else if (rest.length <= 6) {
                                formatted =
                                    '+63 ${rest.substring(0, 3)} ${rest.substring(3)}';
                              } else {
                                formatted =
                                    '+63 ${rest.substring(0, 3)} ${rest.substring(3, 6)} ${rest.substring(6)}';
                              }
                              if (formatted != value) {
                                _contactCtl.value = TextEditingValue(
                                  text: formatted,
                                  selection: TextSelection.collapsed(
                                      offset: formatted.length),
                                );
                              }
                            },
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Enter your phone number';
                              }
                              String raw = v.replaceAll(RegExp(r'[^0-9+]'), '');
                              if (!raw.startsWith('+639')) {
                                return 'Phone must start with +639';
                              }
                              if (raw.length != 13) {
                                return 'Phone must be +639XXXXXXXXX';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),

                          // ROLE & SCHOOL / LEVEL
                          Row(
                            children: const [
                              Icon(Icons.account_box_outlined,
                                  color: red, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Role & Level',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedRole,
                            decoration: const InputDecoration(
                              labelText: 'Role',
                              border: OutlineInputBorder(),
                            ),
                            items: _roles
                                .map(
                                  (r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(r),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedRole = val;
                                _selectedSchool = null;
                                _selectedShsLevel = null;
                                _selectedCollegeYear = null;
                                if (val != 'Student') {
                                  _idNumberCtl.clear();
                                  _guardianNameCtl.clear();
                                  _guardianPhoneCtl.clear();
                                }
                              });
                            },
                            validator: (v) =>
                                v == null ? 'Select a role' : null,
                          ),
                          const SizedBox(height: 12),

                          // When Student: choose School (SHS / College)
                          if (_selectedRole == 'Student') ...[
                            DropdownButtonFormField<String>(
                              value: _selectedSchool,
                              decoration: const InputDecoration(
                                labelText: 'School',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'SHS', child: Text('SHS')),
                                DropdownMenuItem(
                                    value: 'College', child: Text('College')),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedSchool = val;
                                  _selectedShsLevel = null;
                                  _selectedCollegeYear = null;
                                });
                              },
                              validator: (v) =>
                                  v == null ? 'Select SHS or College' : null,
                            ),
                            const SizedBox(height: 12),

                            // If SHS: show SHS grade dropdown
                            if (_selectedSchool == 'SHS') ...[
                              DropdownButtonFormField<String>(
                                value: _selectedShsLevel,
                                decoration: const InputDecoration(
                                  labelText: 'SHS Grade Level',
                                  border: OutlineInputBorder(),
                                ),
                                items: _shsLevels
                                    .map(
                                      (y) => DropdownMenuItem(
                                        value: y,
                                        child: Text(y),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  setState(() => _selectedShsLevel = val);
                                },
                                validator: (v) =>
                                    v == null ? 'Select grade' : null,
                              ),
                              const SizedBox(height: 12),
                            ],

                            // If College: show college year dropdown
                            if (_selectedSchool == 'College') ...[
                              DropdownButtonFormField<String>(
                                value: _selectedCollegeYear,
                                decoration: const InputDecoration(
                                  labelText: 'College Year Level',
                                  border: OutlineInputBorder(),
                                ),
                                items: _collegeYears
                                    .map(
                                      (y) => DropdownMenuItem(
                                        value: y,
                                        child: Text(y),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  setState(() => _selectedCollegeYear = val);
                                },
                                validator: (v) =>
                                    v == null ? 'Select year' : null,
                              ),
                              const SizedBox(height: 12),
                            ],

                            // 📌 ID NUMBER here under Role (Student only)
                            TextFormField(
                              controller: _idNumberCtl,
                              decoration: InputDecoration(
                                labelText: 'ID Number',
                                helperText: _idHelperTextForSchool(),
                                prefixIcon: const Icon(Icons.badge_outlined),
                                border: const OutlineInputBorder(),
                              ),
                              validator: _validateIdForSchool,
                            ),
                            const SizedBox(height: 16),
                          ] else
                            const SizedBox(height: 8),

                          // GUARDIAN SECTION – only for STUDENT
                          if (_selectedRole == 'Student') ...[
                            Row(
                              children: const [
                                Icon(Icons.family_restroom,
                                    color: red, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Guardian (for emergencies)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _guardianNameCtl,
                              decoration: const InputDecoration(
                                labelText: 'Guardian Name',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _guardianPhoneCtl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Guardian Phone Number (+63)',
                                prefixIcon: Icon(Icons.phone),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                String digits =
                                    value.replaceAll(RegExp(r'[^0-9+]'), '');
                                if (!digits.startsWith('+63')) digits = '+63';
                                String rest = '';
                                if (digits.length > 3) {
                                  rest = digits.substring(3);
                                }
                                String formatted;
                                if (rest.isEmpty) {
                                  formatted = '+63';
                                } else if (rest.length <= 3) {
                                  formatted = '+63 $rest';
                                } else if (rest.length <= 6) {
                                  formatted =
                                      '+63 ${rest.substring(0, 3)} ${rest.substring(3)}';
                                } else {
                                  formatted =
                                      '+63 ${rest.substring(0, 3)} ${rest.substring(3, 6)} ${rest.substring(6)}';
                                }
                                if (formatted != value) {
                                  _guardianPhoneCtl.value = TextEditingValue(
                                    text: formatted,
                                    selection: TextSelection.collapsed(
                                        offset: formatted.length),
                                  );
                                }
                              },
                              // optional, but if filled, enforce proper format
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return null; // optional field
                                }
                                String raw =
                                    v.replaceAll(RegExp(r'[^0-9+]'), '');
                                if (!raw.startsWith('+639')) {
                                  return 'Phone must start with +639';
                                }
                                if (raw.length != 13) {
                                  return 'Phone must be +639XXXXXXXXX';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                          ],

                          // SECURITY SECTION
                          Row(
                            children: const [
                              Icon(Icons.lock_outline, color: red, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Security',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passCtl,
                            obscureText: !_passwordVisible,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _passwordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () => setState(
                                    () => _passwordVisible = !_passwordVisible),
                              ),
                            ),
                            validator: (v) => v!.length < 6
                                ? 'Password must be at least 6 characters'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirmPassCtl,
                            obscureText: !_confirmPasswordVisible,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: const Icon(Icons.lock_reset_outlined),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _confirmPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () => setState(() =>
                                    _confirmPasswordVisible =
                                        !_confirmPasswordVisible),
                              ),
                            ),
                            validator: (v) => v != _passCtl.text
                                ? 'Passwords do not match'
                                : null,
                          ),
                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: red,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Register',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(
                              context,
                              '/user_login',
                            ),
                            child: const Text(
                              'Already have an account? Log in',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Image.asset(
                    'assets/wcc_logo.png',
                    height: 40,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
