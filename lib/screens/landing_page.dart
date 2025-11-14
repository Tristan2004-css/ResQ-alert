import 'package:flutter/material.dart';
import 'login_page.dart';

class LandingPage extends StatelessWidget {
  static const routeName = '/';
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFC82323);
    return Scaffold(
      backgroundColor: red,
      body: SafeArea(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Image.asset('assets/whitelog.png',
                width: 150, height: 150, fit: BoxFit.contain),
            const SizedBox(height: 20),
            const Text('ResQ',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold)),
            const Text('Alert',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, LoginPage.routeName),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: red,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 36, vertical: 12)),
              child: const Text('Continue',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
      ),
    );
  }
}
