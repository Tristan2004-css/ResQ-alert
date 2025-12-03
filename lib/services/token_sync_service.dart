import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class TokenSyncService {
  static const String serverUrl = "https://YOUR_SERVER_URL_HERE";
  static const String apiKey = "change_this_immediately_to_a_strong_key";

  // Automatically send token if new or changed
  static Future<void> syncToken() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString("saved_fcm_token");

    final newToken = await FirebaseMessaging.instance.getToken();
    if (newToken == null) return;

    // If same token → no need to send again
    if (savedToken == newToken) return;

    final body = jsonEncode({
      "token": newToken,
    });

    try {
      final res = await http.post(
        Uri.parse("$serverUrl/register-token"),
        body: body,
        headers: {
          "Content-Type": "application/json",
          "x-api-key": apiKey,
        },
      );

      if (res.statusCode == 200) {
        // Save token locally
        prefs.setString("saved_fcm_token", newToken);
        print("✅ Token registered: $newToken");
      } else {
        print("❌ Token register failed: ${res.body}");
      }
    } catch (e) {
      print("❌ Error sending token: $e");
    }
  }
}
