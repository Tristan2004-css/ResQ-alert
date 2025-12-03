// lib/services/token_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';

/// Configuration - set these to your server location & API key.
const String SERVER_BASE =
    'http://<YOUR_SERVER_HOST>:3000'; // e.g. http://192.168.1.100:3000 or https://your-deploy.example
const String API_KEY = 'change_this_immediately_to_a_strong_key';

/// Registers a single token with your server.
Future<bool> registerTokenWithServer(String token,
    {Map<String, dynamic>? meta}) async {
  final url = Uri.parse('$SERVER_BASE/register');
  try {
    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': API_KEY,
      },
      body: jsonEncode({
        'token': token,
        'meta': meta ?? {'platform': 'android'},
      }),
    );

    if (res.statusCode == 200) {
      // success
      print('✅ Registered token with server');
      return true;
    } else {
      print('❌ Failed to register token: ${res.statusCode} ${res.body}');
      return false;
    }
  } catch (e) {
    print('❌ registerToken error: $e');
    return false;
  }
}

/// Unregister token (use on logout or token invalidation)
Future<bool> unregisterTokenFromServer(String token) async {
  final url = Uri.parse('$SERVER_BASE/unregister');
  try {
    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': API_KEY,
      },
      body: jsonEncode({'token': token}),
    );

    if (res.statusCode == 200) {
      print('✅ Unregistered token from server');
      return true;
    } else {
      print('❌ Failed to unregister token: ${res.statusCode} ${res.body}');
      return false;
    }
  } catch (e) {
    print('❌ unregisterToken error: $e');
    return false;
  }
}

/// Call this once at startup (after Firebase initialization).
/// It registers the current token and listens for refreshes to re-register.
Future<void> setupTokenRegistration() async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await registerTokenWithServer(token, meta: {'platform': 'android'});
    } else {
      print('⚠️ FCM token was null at startup');
    }
  } catch (e) {
    print('⚠️ Error getting initial FCM token: $e');
  }

  // listen for token refreshes (will fire when token rotates)
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    try {
      print('🔁 FCM token refreshed: $newToken');
      await registerTokenWithServer(newToken, meta: {'platform': 'android'});
    } catch (e) {
      print('⚠️ Error registering refreshed token: $e');
    }
  });
}
