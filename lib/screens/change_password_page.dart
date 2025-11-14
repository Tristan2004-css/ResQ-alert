import 'package:flutter/material.dart';

class ChangePasswordPage extends StatefulWidget {
  static const routeName = '/change_password';
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _curr = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _curr.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _change() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    Future.delayed(const Duration(seconds: 1), () {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed (demo)')));
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFC82323);
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(children: [
                    const Text('Password Security Tips', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Use unique passwords and enable 2FA where possible.'),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              Form(
                key: _formKey,
                child: Column(children: [
                  TextFormField(controller: _curr, decoration: const InputDecoration(labelText: 'Current Password'), obscureText: true, validator: (v) => (v==null || v.isEmpty) ? 'Enter current password' : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: _new, decoration: const InputDecoration(labelText: 'New Password'), obscureText: true, validator: (v) => (v==null || v.length<6) ? 'Minimum 6 characters' : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: _confirm, decoration: const InputDecoration(labelText: 'Confirm New Password'), obscureText: true, validator: (v) => v != _new.text ? 'Passwords do not match' : null),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(onPressed: _loading ? null : _change, style: ElevatedButton.styleFrom(backgroundColor: red), child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Change Password')),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
