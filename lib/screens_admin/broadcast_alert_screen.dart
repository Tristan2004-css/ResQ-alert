// lib/screens_admin/broadcast_alert_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:resq_alert/widgets/admin_scaffold.dart';

class BroadcastAlertScreen extends StatefulWidget {
  const BroadcastAlertScreen({super.key});

  @override
  State<BroadcastAlertScreen> createState() => _BroadcastAlertScreenState();
}

class _BroadcastAlertScreenState extends State<BroadcastAlertScreen> {
  final TextEditingController message = TextEditingController();

  // Realtime Database ref for alerts
  final DatabaseReference _alertsRef = FirebaseDatabase.instance.ref('alerts');

  // ==== Configure these with values from your OneSignal dashboard ====
  // Replace with your actual OneSignal App ID and REST API Key
  static const String oneSignalAppId = 'cf36124d-02de-47d4-a0be-6753b33bb28c';
  static const String oneSignalRestKey = 'm2y3c3dibuh4eladafmgxajdx';
  // ==================================================================

  // ===== EMERGENCY CATEGORIES & TYPES =====
  static const Map<String, List<String>> emergencyMap = {
    '🔐 Security Emergencies': [
      'Intruder / unauthorized person',
      'Bomb threat',
      'Weapon threat',
    ],
    '🛡️ Safety Emergencies': [
      'Fire',
      'Gas leak',
      'Chemical spill (science labs)',
      'Power outage',
      'Structural damage',
      'Medical emergencies',
    ],
    '🌪️ Natural Disaster Emergencies': [
      'Earthquake',
      'Typhoon',
      'Flood',
      'Storm surge',
      'Volcanic ashfall',
    ],
  };

  // ===== BUILDINGS / FLOORS / ROOMS =====
  static const String collegeBuilding = 'College Building';
  static const String shsBuilding = 'SHS Building';

  static const Map<String, Map<String, List<String>>> buildingFloorsRooms = {
    collegeBuilding: {
      'GROUND FLOOR – Main Rooms': [
        'PT Laboratory',
        'Career Center',
        'Registrar',
        'School Main Lobby',
        'Cashier’s Office',
        'Dean’s Office (Room 104)',
        'Office of the VPAA (Room 102)',
        'Cashier & Supply (Room 101)',
        'Testing Room',
        'Guidance Counselor Office',
        'Counseling Room',
        'Psychometrician Office',
        'Dental & Medical Clinic',
        'Cafeteria',
        'Engineering & Maintenance Office',
        'Community Extension & Services Office',
      ],
      'SECOND FLOOR – Main Rooms': [
        'Mock Hotel',
        'Housekeeping',
        'Laundry Room',
        'Demonstration Room',
        'Kitchen Laboratory',
        'SIHM Function Room',
        'SIHM Kitchen',
        'Classroom Room 200',
        'Classroom Room 201',
        'Classroom Room 202',
        'Classroom Room 203',
        'Classroom Room 206',
        'Classroom Room 213',
        'Office of the VP for Business Operation',
        'DSA Office',
        'Scale Office',
        'Reception Area',
      ],
      'THIRD FLOOR – Main Rooms': [
        'Classroom Room 300',
        'Classroom Room 301',
        'Classroom Room 302',
        'Classroom Room 303',
        'Classroom Room 304',
        'CCAC',
        'Psychology Laboratory',
        'TESDA Room',
        'Health Center',
        'Operating Room',
        'Delivery Room',
        'Control Room',
        'Incubation Room',
        'Nursery Room',
        'ICU Room',
      ],
      'FOURTH FLOOR – Main Rooms': [
        'Library',
        'Library Stock Room',
        'Staff Room',
        'Baggage Depository',
        'Audio Visual Room',
        'Discussion Room 1',
        'Discussion Room 2',
        'Computer Lab',
        'Computer Rooms',
        'IT Office',
        'Classrooms',
      ],
      'FIFTH FLOOR – Main Rooms': [
        'Pharmaceutic Manufacturing Laboratory',
        'Chem Lab 2 (Room 510-A)',
        'Roentgen Laboratory',
        'Med Tech Laboratory',
        'Science / Laboratory Room 500',
        'Science / Laboratory Room 502',
        'Science / Laboratory Room 503',
        'Science / Laboratory Room 504',
        'Science / Laboratory Room 505',
        'Science / Laboratory Room 506',
        'Science / Laboratory Room 507',
        'Science / Laboratory Room 511',
        'Science / Laboratory Room 512',
        'Dark Room',
      ],
      'SIXTH FLOOR – Main Rooms': [
        'Audio/Visual Room',
        'Male Locker Room',
        'Female Locker Room',
        'Control Room',
        'Electrical Room',
        'Gymnasium',
      ],
      'MEZZANINE LEVEL – Main Rooms': [
        'Open Lobby',
        'Research Laboratory',
        'Experimental Room',
        'Feed & Bedding Storage',
        'Main Storage Room',
      ],
    },
    shsBuilding: {
      'LOWER BASEMENT – Main Rooms': [
        'Room 100',
        'Room 101',
        'Room 102',
        'Room 103',
        'Room 104',
        'Room 105',
        'Room 106',
        'Room 107',
        'Room 108',
        'Students Club Room',
        'Principal’s Office',
        'Dining Hall',
        'Pump Room',
      ],
      'UPPER BASEMENT – Main Rooms': [
        'Room 200',
        'Room 201',
        'Room 202',
        'Room 203',
        'Room 204',
        'Room 205',
        'Room 206',
        'Room 207',
        'Room 208 (Laboratory)',
        'Student Lounge',
        'Students Council Room',
        'General Storage',
        'Principal’s Office',
        'Utility Room',
        'Pantry',
        'Dining Hall',
      ],
      'GROUND FLOOR – Main Rooms': [
        'Accounting / Cashier',
        'Students General Auditorium',
        'Student Lounge',
        'Faculty Room',
        'Room 300',
        'Room 301',
        'Room 302',
        'Room 303',
        'Room 304',
        'Room 305',
      ],
      'SECOND FLOOR – Main Rooms': [
        'Ticket Office',
        'Security Room',
        'Surgery Department',
        'Pantry',
        'Working Area (F/T M/T)',
        'Medical Department',
        'Breastfeeding Room',
        'Pedia Department',
        'OB Department',
        'Records',
        'Wound Care',
        'TB DOTS',
        'Animal Bite Treatment Area',
        'Operating Room',
        'Room C',
        'Room D',
        'Room E',
        'Second Floor Lobby / Reception',
      ],
    },
  };

  // ===== STATE =====
  String? selectedCategory;
  String? selectedEmergency;
  String? selectedBuilding;
  String? selectedFloor;
  String? selectedRoom;

  // NEW: target audience (where to broadcast)
  static const String targetAll = 'All Students';
  static const String targetSHS = 'SHS only';
  static const String targetCollege = 'College only';
  String? selectedTarget = targetAll; // default to All Students

  // Whether building dropdown is locked (auto-selected) because of target
  bool _isBuildingLocked = false;

  // ---------- SEND PUSH via OneSignal REST API ----------
  Future<void> sendPushNotification({
    required String title,
    required String body,
    String? segment, // if you want to target "All", "SHS", "College" later
  }) async {
    if (oneSignalAppId == 'YOUR_ONESIGNAL_APP_ID' ||
        oneSignalRestKey == 'YOUR_ONESIGNAL_REST_API_KEY') {
      debugPrint(
          'OneSignal keys not set. Skipping push send (set your keys first).');
      return;
    }

    final uri = Uri.parse('https://onesignal.com/api/v1/notifications');

    // By default we broadcast to All. If in future you tag users, you can
    // send to segments or filter by tags (see OneSignal docs).
    final payload = <String, dynamic>{
      'app_id': oneSignalAppId,
      // simple: send to all subscribers (change if you implement tags)
      'included_segments': ['All'],
      'headings': {'en': title},
      'contents': {'en': body},
      // optionally add data for deep linking inside app
      'data': {
        'category': selectedCategory ?? '',
        'emergency': selectedEmergency ?? '',
        'building': selectedBuilding ?? '',
        'floor': selectedFloor ?? '',
        'room': selectedRoom ?? '',
      },
      'android_channel_id': null, // optionally set channel id
    };

    try {
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $oneSignalRestKey',
        },
        body: jsonEncode(payload),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        debugPrint('OneSignal push sent (status ${res.statusCode})');
      } else {
        debugPrint(
            'Failed to send OneSignal push: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      debugPrint('Exception sending OneSignal push: $e');
    }
  }

  Future<void> _send() async {
    if (selectedCategory == null || selectedEmergency == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an emergency type.')),
      );
      return;
    }

    if (selectedBuilding == null ||
        selectedFloor == null ||
        selectedRoom == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select building, floor and room.'),
        ),
      );
      return;
    }

    if (message.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a short alert message.')),
      );
      return;
    }

    try {
      // Save to RTDB
      final newRef = _alertsRef.push();
      await newRef.set({
        'category': selectedCategory,
        'emergency': selectedEmergency,
        'building': selectedBuilding,
        'floor': selectedFloor,
        'room': selectedRoom,
        'message': message.text.trim(),
        'status': 'active',
        'timestamp': ServerValue.timestamp,
        'target': selectedTarget, // <-- audience included here
      });

      // Fire push notification via OneSignal REST API
      final title = '🚨 ${selectedEmergency ?? 'Emergency'}';
      final body =
          '${message.text.trim()} • ${selectedBuilding ?? ''} ${selectedFloor != null ? "• $selectedFloor" : ""}';

      await sendPushNotification(title: title, body: body);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergency broadcast sent.')),
      );

      message.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send alert: $e')),
      );
    }
  }

  @override
  void dispose() {
    message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFE53935);

    // Helpers for location dropdowns
    final floorsForBuilding = selectedBuilding == null
        ? <String>[]
        : buildingFloorsRooms[selectedBuilding!]!.keys.toList();

    final roomsForFloor = (selectedBuilding != null && selectedFloor != null)
        ? (buildingFloorsRooms[selectedBuilding!]![selectedFloor!] ??
            <String>[])
        : <String>[];

    final emergenciesForCategory = selectedCategory == null
        ? <String>[]
        : emergencyMap[selectedCategory!] ?? <String>[];

    return AdminScaffold(
      title: 'Broadcast Alert',
      selected: AdminMenuItem.dashboard,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== INFO CARD =====
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: const [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFFFFEBEE),
                      child: Icon(Icons.campaign_rounded, color: red),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Broadcast alerts notify all active users.\n'
                        'Use only for high-priority emergencies.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ===== EMERGENCY SECTION =====
            const Text(
              'Emergency',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Category dropdown
            SizedBox(
              width: double.infinity,
              child: DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Emergency Category',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                items: emergencyMap.keys
                    .map(
                      (cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    selectedCategory = val;
                    selectedEmergency = null;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),

            // Emergency detail dropdown
            SizedBox(
              width: double.infinity,
              child: DropdownButtonFormField<String>(
                value: selectedEmergency,
                decoration: const InputDecoration(
                  labelText: 'Specific Emergency',
                  prefixIcon: Icon(Icons.warning_amber_outlined),
                  border: OutlineInputBorder(),
                ),
                items: emergenciesForCategory
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => selectedEmergency = val),
              ),
            ),

            const SizedBox(height: 16),

            // ===== TARGET AUDIENCE (NEW) =====
            const Text(
              'Target Audience',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: DropdownButtonFormField<String>(
                value: selectedTarget,
                decoration: const InputDecoration(
                  labelText: 'Send alert to',
                  prefixIcon: Icon(Icons.people_outline),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: targetAll, child: Text(targetAll)),
                  DropdownMenuItem(value: targetSHS, child: Text(targetSHS)),
                  DropdownMenuItem(
                      value: targetCollege, child: Text(targetCollege)),
                ],
                onChanged: (val) {
                  setState(() {
                    selectedTarget = val;
                    // enforce building selection/lock based on target
                    if (val == targetCollege) {
                      selectedBuilding = collegeBuilding;
                      selectedFloor = null;
                      selectedRoom = null;
                      _isBuildingLocked = true;
                    } else if (val == targetSHS) {
                      selectedBuilding = shsBuilding;
                      selectedFloor = null;
                      selectedRoom = null;
                      _isBuildingLocked = true;
                    } else {
                      // All Students: allow choosing building
                      selectedBuilding = null;
                      selectedFloor = null;
                      selectedRoom = null;
                      _isBuildingLocked = false;
                    }
                  });
                },
              ),
            ),

            const SizedBox(height: 24),

            // ===== LOCATION SECTION =====
            const Text(
              'Location',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Building
            SizedBox(
              width: double.infinity,
              child: DropdownButtonFormField<String>(
                value: selectedBuilding,
                decoration: InputDecoration(
                  labelText: 'Building',
                  prefixIcon: const Icon(Icons.apartment_outlined),
                  border: OutlineInputBorder(),
                  // show hint if locked
                  helperText: _isBuildingLocked
                      ? 'Building auto-selected by Target Audience'
                      : null,
                ),
                items: const [
                  DropdownMenuItem(
                    value: collegeBuilding,
                    child: Text(collegeBuilding),
                  ),
                  DropdownMenuItem(
                    value: shsBuilding,
                    child: Text(shsBuilding),
                  ),
                ],
                onChanged: _isBuildingLocked
                    ? null
                    : (val) {
                        setState(() {
                          selectedBuilding = val;
                          selectedFloor = null;
                          selectedRoom = null;
                        });
                      },
                disabledHint: selectedBuilding != null
                    ? Text(selectedBuilding!)
                    : const Text('Select building'),
              ),
            ),
            const SizedBox(height: 12),

            // Floor
            SizedBox(
              width: double.infinity,
              child: DropdownButtonFormField<String>(
                value: selectedFloor,
                decoration: const InputDecoration(
                  labelText: 'Floor',
                  prefixIcon: Icon(Icons.layers_outlined),
                  border: OutlineInputBorder(),
                ),
                items: floorsForBuilding
                    .map(
                      (f) => DropdownMenuItem(
                        value: f,
                        child: Text(f),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    selectedFloor = val;
                    selectedRoom = null;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),

            // Room
            SizedBox(
              width: double.infinity,
              child: DropdownButtonFormField<String>(
                value: selectedRoom,
                decoration: const InputDecoration(
                  labelText: 'Room / Area',
                  prefixIcon: Icon(Icons.meeting_room_outlined),
                  border: OutlineInputBorder(),
                ),
                items: roomsForFloor
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(r),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => selectedRoom = val),
              ),
            ),

            const SizedBox(height: 24),

            // ===== MESSAGE =====
            const Text(
              'Alert Message',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: TextField(
                controller: message,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  alignLabelWithHint: true,
                  hintText:
                      'Example:\nFire at Building B, 2nd floor lab.\nEvacuate now. Avoid elevators.',
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ===== SEND BUTTON =====
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                label: const Text(
                  'Send Emergency Broadcast',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                onPressed: _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
