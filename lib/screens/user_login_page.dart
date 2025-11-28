// lib/screens/user_login_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserLoginPage extends StatefulWidget {
  static const routeName = '/user_login';
  const UserLoginPage({super.key});

  @override
  State<UserLoginPage> createState() => _UserLoginPageState();
}

class _UserLoginPageState extends State<UserLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();

  bool _loading = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _emailCtl.dispose();
    _passCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final email = _emailCtl.text.trim();
    final password = _passCtl.text.trim();

    try {
      final cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final user = cred.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'unknown-error',
          message: "Unknown error occurred.",
        );
      }

      await user.reload();

      // ✅ Optional: Require email verification
      if (!user.emailVerified) {
        await user.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please verify your email before logging in."),
          ),
        );
        await FirebaseAuth.instance.signOut();
        return;
      }

      // ✅ Ensure Firestore user doc exists
      final uid = user.uid;
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!doc.exists) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set({'email': user.email});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login successful!")),
      );

      Navigator.pushReplacementNamed(context, '/dashboard');
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth error code: ${e.code}, message: ${e.message}');

      String msg = "Login failed";

      switch (e.code) {
        case 'invalid-email':
          msg = "Invalid email format.";
          break;

        case 'invalid-credential':
        case 'wrong-password':
          msg = "Incorrect password. Please try again.";
          break;

        case 'user-not-found':
          msg = "No user found with this email.";
          break;

        case 'user-disabled':
          msg = "This account has been disabled.";
          break;

        case 'too-many-requests':
          msg = "Too many attempts. Try again later.";
          break;

        default:
          msg = e.message ?? "Authentication error.";
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailCtl.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email first.")),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Password reset email sent to $email"),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String msg = "Failed to send reset email.";

      switch (e.code) {
        case 'invalid-email':
          msg = "Invalid email format.";
          break;
        case 'user-not-found':
          msg = "No account found with this email.";
          break;
        default:
          msg = e.message ?? msg;
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFC82323);

    return Scaffold(
      backgroundColor: red,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo + Welcome text
                Image.asset(
                  'assets/whitelog.png',
                  height: 100,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Welcome back!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Log in to your ResQ Alert account',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // White card with form
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Title row inside card
                        Row(
                          children: const [
                            Icon(Icons.lock_outline, color: red),
                            SizedBox(width: 8),
                            Text(
                              'Log in to continue',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Email
                        TextFormField(
                          controller: _emailCtl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              !v!.contains("@") ? "Enter a valid email" : null,
                        ),
                        const SizedBox(height: 14),

                        // Password
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
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (v) =>
                              v!.isEmpty ? "Enter password" : null,
                        ),

                        const SizedBox(height: 8),

                        // Forgot password (right aligned)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _loading ? null : _sendPasswordReset,
                            child: const Text(
                              "Forgot password?",
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Log in button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: red,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 8),
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
                                    "Log In",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Register text
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/register'),
                          child: const Text(
                            "Don't have an account? Register here.",
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Bottom logo
                Image.asset(
                  'assets/wcc_logo.png',
                  height: 40,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
