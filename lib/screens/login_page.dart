import 'package:flutter/material.dart';
import 'user_login_page.dart';
import '../screens_admin/login_screen.dart';

class LoginPage extends StatelessWidget {
  static const String routeName = '/login';

  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFC82323);

    return Scaffold(
      backgroundColor: Colors.white,

      // 👇 Entire screen clickable → Go to USER LOGIN
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
          Navigator.pushNamed(context, UserLoginPage.routeName);
        },
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),

                  // 🔒 Hidden Admin Login (long press only)
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onLongPress: () {
                      Navigator.pushNamed(context, LoginScreen.routeName);
                    },
                    child: Image.asset(
                      'assets/RQ.png',
                      width: 120,
                      height: 120,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.image_not_supported,
                        size: 100,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'ResQ Alert',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Welcome! Tap anywhere to continue.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 60),

                  // USER Button (kept for UI, but screen tap also works)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, UserLoginPage.routeName);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'WELCOME',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  Image.asset(
                    'assets/wcc_logo.png',
                    width: 120,
                    height: 50,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.school, size: 60, color: Colors.grey),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
