// lib/notification_service.dart
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'notification_helper.dart' show showEmergencyNotification;

class NotificationService {
  StreamSubscription<DatabaseEvent>? _sub;
  int? _lastSeenMillis;

  void startListening() {
    final Query ref =
        FirebaseDatabase.instance.ref('alerts').orderByChild('timestamp');

    _sub = ref.onValue.listen((event) {
      if (event.snapshot.value == null) return;
      final children = event.snapshot.children.toList();
      if (children.isEmpty) return;

      children.sort((a, b) {
        final at = _extractMillis(a.child('timestamp').value);
        final bt = _extractMillis(b.child('timestamp').value);
        return bt.compareTo(at);
      });

      final newest = children.first;
      final status =
          (newest.child('status').value ?? '').toString().toLowerCase();
      if (status == 'resolved' || status == 'closed') return;

      final millis = _extractMillis(newest.child('timestamp').value);

      if (_lastSeenMillis == null) {
        _lastSeenMillis = millis;
        return;
      }

      if (millis > (_lastSeenMillis ?? 0)) {
        _lastSeenMillis = millis;
        final title =
            (newest.child('emergency').value ?? 'Emergency').toString();
        final body = (newest.child('message').value ?? '').toString();
        showEmergencyNotification(title: title, body: body, fullScreen: true);
      }
    });
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  static int _extractMillis(Object? ts) {
    if (ts == null) return 0;
    if (ts is int) return ts;
    if (ts is double) return ts.toInt();
    final s = ts.toString();
    final parsedInt = int.tryParse(s);
    if (parsedInt != null) return parsedInt;
    final parsedDouble = double.tryParse(s);
    if (parsedDouble != null) return parsedDouble.toInt();
    return 0;
  }
}
