import 'package:flutter/material.dart';

class RegisterPage extends StatelessWidget {
  static const routeName = '/register';
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFC82323);
    return Scaffold(
      backgroundColor: red,
      appBar: AppBar(title: const Text('Register - USER')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(16))),
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              const Text('Create your Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 8),
              TextFormField(decoration: const InputDecoration(labelText: 'ID Number')),
              const SizedBox(height: 8),
              TextFormField(decoration: const InputDecoration(labelText: 'Contact Number')),
              const SizedBox(height: 8),
              TextFormField(decoration: const InputDecoration(labelText: 'Year Level')),
              const SizedBox(height: 8),
              TextFormField(decoration: const InputDecoration(labelText: 'Role')),
              const SizedBox(height: 8),
              TextFormField(obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
              const SizedBox(height: 8),
              TextFormField(obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password')),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: red), child: const Text('Register'))),
            ]),
          ),
        ),
      ),
    );
  }
}
