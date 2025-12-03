// lib/screens/notifications_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:torch_light/torch_light.dart';
import 'package:audioplayers/audioplayers.dart';

class NotificationsPage extends StatefulWidget {
  static const routeName = '/notifications';
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tc;
  final AudioPlayer _audio = AudioPlayer();
  bool _online = true;
  int _loadLimit = 30;

  // track latest alert we've handled (for feedback)
  int? _lastSeenMillis;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 3, vsync: this)
      ..addListener(() => setState(() {}));

    // realtime connection indicator
    FirebaseDatabase.instance.ref(".info/connected").onValue.listen((e) {
      setState(() => _online = e.snapshot.value == true);
    });
  }

  @override
  void dispose() {
    _tc.dispose();
    _audio.dispose();
    super.dispose();
  }

  // ---------- Helpers ----------
  Color statusColor(String s) {
    s = s.toLowerCase();
    if (s == 'critical' || s == 'active') return Colors.red;
    if (s.contains('progress')) return Colors.orange;
    if (s == 'monitoring') return Colors.blue;
    if (s == 'resolved' || s == 'closed') return Colors.green;
    return Colors.grey;
  }

  IconData iconForType(String t) {
    t = t.toLowerCase();
    if (t.contains("fire")) return Icons.local_fire_department;
    if (t.contains("medical")) return Icons.local_hospital;
    if (t.contains("security")) return Icons.security;
    if (t.contains("accident")) return Icons.car_crash;
    if (t.contains("broadcast")) return Icons.campaign;
    return Icons.warning_amber;
  }

  // Play alert sound (AssetSource path must match pubspec assets entry)
  Future<void> playSound() async {
    try {
      await _audio.play(AssetSource("sounds/alert.mp3"));
    } catch (e) {
      // non-fatal
    }
  }

  Future<void> blinkFlash() async {
    try {
      await TorchLight.enableTorch();
      await Future.delayed(const Duration(milliseconds: 140));
      await TorchLight.disableTorch();
    } catch (_) {
      // ignore if device has no flashlight or permission denied
    }
  }

  Widget collapsible(String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    if (text.length <= 120) return Text(text);
    return StatefulBuilder(builder: (context, setSB) {
      bool open = false;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${text.substring(0, 120)}..."),
          InkWell(
            onTap: () => setSB(() => open = !open),
            child:
                Text("Read more ▼", style: const TextStyle(color: Colors.blue)),
          )
        ],
      );
    });
  }

  // Parse RTDB snapshot into list (most recent first). Uses _loadLimit for paging.
  List<Map<String, dynamic>> parse(DatabaseEvent e) {
    if (e.snapshot.value == null) return [];
    final raw = Map<dynamic, dynamic>.from(e.snapshot.value as Map);
    final list = <Map<String, dynamic>>[];

    raw.forEach((key, value) {
      final m = Map<String, dynamic>.from(value);
      m["key"] = key;
      final ts = (m["timestamp"] is double)
          ? (m["timestamp"] as double).toInt()
          : (m["timestamp"] ?? 0);
      final dt = DateTime.fromMillisecondsSinceEpoch(ts);
      m["dt"] = dt;
      m["time"] =
          "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
          "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      m["type"] = (m["type"] ?? m["emergency"] ?? "Alert").toString();
      m["desc"] = (m["desc"] ?? m["details"] ?? m["message"] ?? "").toString();
      m["status"] = (m["status"] ?? "active").toString();
      list.add(m);
    });

    list.sort((a, b) => b["dt"].compareTo(a["dt"]));
    return list.take(_loadLimit).toList();
  }

  Map<String, List<Map<String, dynamic>>> groupItems(List items) {
    final now = DateTime.now();
    final map = {
      "Today": <Map<String, dynamic>>[],
      "Recent": <Map<String, dynamic>>[],
      "Older": <Map<String, dynamic>>[],
    };
    for (var it in items) {
      final d = it["dt"] as DateTime;
      final diff = now.difference(d).inDays;
      if (diff == 0)
        map["Today"]!.add(it);
      else if (diff <= 7)
        map["Recent"]!.add(it);
      else
        map["Older"]!.add(it);
    }
    return map;
  }

  // DETAILS DIALOG (read-only)
  void showDetails(Map it) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(it["type"]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((it["desc"] ?? "").toString().isNotEmpty) Text(it["desc"]),
              const SizedBox(height: 8),
              Text("Status: ${it["status"]}"),
              Text("Time: ${it["time"]}"),
              if (it["building"] != null) Text("Building: ${it["building"]}"),
              if (it["floor"] != null) Text("Floor: ${it["floor"]}"),
              if (it["room"] != null) Text("Room: ${it["room"]}"),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"))
        ],
      ),
    );
  }

  // TILE (read-only) — tap to open details
  Widget notificationTile(Map it) {
    final sc = statusColor(it["status"]);
    return InkWell(
      onTap: () => showDetails(it),
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: sc.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sc.withOpacity(0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(iconForType(it["type"]), color: sc, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(it["type"],
                      style: TextStyle(color: sc, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  collapsible(it["desc"]),
                  const SizedBox(height: 8),
                  Text(it["time"],
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black45)),
                  if (it["building"] != null) const SizedBox(height: 6),
                  if (it["building"] != null)
                    Text(
                        "📍 ${it["building"]} • ${it["floor"] ?? ''} • ${it["room"] ?? ''}",
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: sc.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(it["status"].toString().toUpperCase(),
                  style: TextStyle(
                      color: sc, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildGrouped(List items) {
    if (items.isEmpty) return const Center(child: Text("No notifications"));
    final g = groupItems(items);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (g["Today"]!.isNotEmpty) ...[
          const Text("Today",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...g["Today"]!.map(notificationTile).toList(),
        ],
        if (g["Recent"]!.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text("Recent",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...g["Recent"]!.map(notificationTile).toList(),
        ],
        if (g["Older"]!.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text("Older",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...g["Older"]!.map(notificationTile).toList(),
        ],
        if (items.length >= _loadLimit)
          TextButton(
              onPressed: () => setState(() => _loadLimit += 20),
              child: const Text("Load more")),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFC82323);
    final ref =
        FirebaseDatabase.instance.ref("alerts").orderByChild("timestamp");

    return Scaffold(
      appBar: AppBar(
        backgroundColor: red,
        title: Row(
          children: [
            const Text("Notifications"),
            const SizedBox(width: 10),
            Icon(_online ? Icons.circle : Icons.circle_outlined,
                size: 12, color: _online ? Colors.green : Colors.red),
          ],
        ),
        bottom:
            TabBar(controller: _tc, indicatorColor: Colors.white, tabs: const [
          Tab(text: "All"),
          Tab(text: "Active"),
          Tab(text: "History"),
        ]),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: ref.onValue,
        builder: (context, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());

          final items = parse(snap.data!);

          // alert feedback only when new alert arrives
          int? latestMillis;
          if (items.isNotEmpty) {
            try {
              latestMillis =
                  (items.first['dt'] as DateTime).millisecondsSinceEpoch;
            } catch (_) {
              latestMillis = null;
            }
          }

          if (_lastSeenMillis == null) {
            _lastSeenMillis =
                latestMillis; // initialize on first load (no sound)
          } else if (latestMillis != null &&
              latestMillis > (_lastSeenMillis ?? 0)) {
            _lastSeenMillis = latestMillis;
            if (mounted) {
              Future.microtask(() async {
                await playSound();
                // vibration handled by local notification channel (no vibration plugin)
                await blinkFlash();
              });
            }
          }

          final active = items.where((m) {
            final s = m["status"].toString().toLowerCase();
            return s == "active" ||
                s == "critical" ||
                s.contains("progress") ||
                s == "monitoring";
          }).toList();

          final history = items.where((m) {
            final s = m["status"].toString().toLowerCase();
            return s == "resolved" || s == "closed";
          }).toList();

          return TabBarView(controller: _tc, children: [
            buildGrouped(items),
            buildGrouped(active),
            buildGrouped(history),
          ]);
        },
      ),
    );
  }
}
