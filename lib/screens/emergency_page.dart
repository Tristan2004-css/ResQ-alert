// lib/screens/emergency_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class EmergencyPage extends StatefulWidget {
  static const routeName = '/emergency';
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  String? selected; // emergency type label
  String? selectedBuilding;
  String? selectedFloor;
  String? selectedRoom;
  final detailsCtl = TextEditingController();
  bool _sending = false;

  // BUILDINGS / FLOORS / ROOMS data
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

  @override
  void dispose() {
    detailsCtl.dispose();
    super.dispose();
  }

  Future<void> _sendEmergency() async {
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the emergency type.')),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;

      String userId = user?.uid ?? '';
      String userName = user?.email ?? 'Unknown user';
      String idNumber = '';

      // Get extra user info from Firestore (name, idNumber)
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final data = doc.data();
        if (data != null) {
          userName = (data['name'] ?? userName).toString();
          idNumber = (data['idNumber'] ?? '').toString();
        }
      }

      final ref = FirebaseDatabase.instance.ref('userAlerts').push();

      await ref.set({
        'userId': userId,
        'userName': userName,
        'idNumber': idNumber,
        'type': selected,
        'building': selectedBuilding ?? '',
        'floor': selectedFloor ?? '',
        'room': selectedRoom ?? '',
        'details': detailsCtl.text.trim(),
        'timestamp': ServerValue.timestamp,
        'status':
            'active', // admin can update to in_progress / monitoring / resolved
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergency alert sent')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send emergency: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFC82323);

    // Emergency types (emoji + text only)
    final types = [
      '🚑 Medical Emergency',
      '🔥 Fire Emergency',
      '🛡 Security Threat',
      '💥 Accident',
      '🌪 Natural Disaster',
      '❗ Other Emergency',
    ];

    // helpers for dynamic dropdown choices
    final floorsForSelectedBuilding = selectedBuilding == null
        ? <String>[]
        : buildingFloorsRooms[selectedBuilding!]!.keys.toList();

    final roomsForSelectedFloor = (selectedBuilding != null &&
            selectedFloor != null &&
            buildingFloorsRooms[selectedBuilding!] != null)
        ? (buildingFloorsRooms[selectedBuilding!]![selectedFloor!] ??
            <String>[])
        : <String>[];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: red,
        title: const Text(
          'Emergency - User',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  // kept your logo Image.asset call (if you want removed, say so)
                  Image.asset(
                    'assets/logooo.png',
                    width: 35,
                    height: 35,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ResQ Alert',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Select the type of emergency:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              // ===== NEW: Grid of 6 EMOJI + TEXT ONLY buttons (NO IMAGES) =====
              LayoutBuilder(builder: (ctx, constraints) {
                final crossAxisCount = constraints.maxWidth > 700 ? 3 : 2;
                return GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.15,
                  children: types.map((label) {
                    final isSelected = selected == label;

                    // emoji is first unicode "word" (split by space)
                    final emoji = label.split(' ').first;
                    final textOnly = label.replaceFirst('$emoji ', '');

                    return Material(
                      color: isSelected ? Colors.red.shade50 : Colors.white,
                      elevation: isSelected ? 5 : 1,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => selected = label),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? red : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // EMOJI ONLY
                              Text(
                                emoji,
                                style: const TextStyle(fontSize: 38),
                              ),

                              const SizedBox(height: 10),

                              // TEXT ONLY
                              Text(
                                textOnly,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: isSelected ? red : Colors.black87,
                                ),
                              ),

                              if (isSelected) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: red.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'SELECTED',
                                    style: TextStyle(
                                      color: red,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),

              const SizedBox(height: 18),

              // Building dropdown (optional)
              DropdownButtonFormField<String>(
                value: selectedBuilding,
                decoration: const InputDecoration(
                  labelText: 'Building (optional)',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(
                      value: collegeBuilding, child: Text(collegeBuilding)),
                  DropdownMenuItem(
                      value: shsBuilding, child: Text(shsBuilding)),
                ],
                onChanged: (v) {
                  setState(() {
                    selectedBuilding = v;
                    // reset floor & room when building changes
                    selectedFloor = null;
                    selectedRoom = null;
                  });
                },
                hint: const Text('Select building (optional)'),
              ),

              const SizedBox(height: 12),

              // Floor dropdown (depends on building)
              DropdownButtonFormField<String>(
                value: selectedFloor,
                decoration: const InputDecoration(
                  labelText: 'Floor (optional)',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: floorsForSelectedBuilding
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    selectedFloor = v;
                    // reset room when floor changes
                    selectedRoom = null;
                  });
                },
                hint: const Text('Select floor (optional)'),
                disabledHint: selectedBuilding == null
                    ? const Text('Select building first')
                    : null,
              ),

              const SizedBox(height: 12),

              // Room dropdown (depends on floor)
              DropdownButtonFormField<String>(
                value: selectedRoom,
                decoration: const InputDecoration(
                  labelText: 'Room / Area (optional)',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: roomsForSelectedFloor
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => selectedRoom = v),
                hint: const Text('Select room (optional)'),
                disabledHint: selectedFloor == null
                    ? const Text('Select floor first')
                    : null,
              ),

              const SizedBox(height: 12),

              TextField(
                controller: detailsCtl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Additional Details (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Send Emergency Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (selected == null || _sending) ? null : _sendEmergency,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _sending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Send Emergency Alert',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _sending ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
