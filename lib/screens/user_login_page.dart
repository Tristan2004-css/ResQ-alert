import 'package:flutter/material.dart';

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

  @override
  void dispose() {
    _emailCtl.dispose();
    _passCtl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    // Demo delay; replace with real auth call
    Future.delayed(const Duration(seconds: 1), () {
      setState(() => _loading = false);
      // On success navigate to dashboard (replace with your route)
      Navigator.pushReplacementNamed(context, '/dashboard');
    });
  }

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFC82323);

    return Scaffold(
      backgroundColor: red,
      // Optional appbar (keeps top status bar style same as screenshot)
      appBar: AppBar(
        backgroundColor: red,
        elevation: 0,
        toolbarHeight: 56,
        title: const SizedBox.shrink(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // White rounded card container
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 0),
                // big top rounded corners & gentle bottom rounding like screenshot
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
                child: Column(
                  children: [
                    // logo (replace asset with your real file)
                    Image.asset(
                      'assets/984fd736-1c23-473e-b75e-dd2956269159(1).jpg',
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('Asset load error: $error');
                        return const Icon(Icons.broken_image, size: 80);
                      },
                    ),
                    const SizedBox(height: 10),

                    const Text('ResQ Alert',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const Text('Log In your Account',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 18),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email
                          TextFormField(
                            controller: _emailCtl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Please enter email';
                              if (!v.contains('@'))
                                return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Password
                          TextFormField(
                            controller: _passCtl,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Please enter password';
                              if (v.length < 4) return 'Password too short';
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),

                          // Log In button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Text('Log In',
                                      style: TextStyle(fontSize: 16)),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // register link
                          TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/register'),
                            child: const Text(
                                "Don't have an account? Register here."),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // WCC logo (placeholder)
                    Image.asset(
                      'assets/wcc_logo.png',
                      width: 120,
                      height: 48,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}
