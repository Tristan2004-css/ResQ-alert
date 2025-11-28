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
  String? selected;
  String? floor;
  final detailsCtl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    detailsCtl.dispose();
    super.dispose();
  }

  Future<void> _sendEmergency() async {
    if (selected == null) return;

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
        'floor': floor ?? '',
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

    // Emergency types
    final types = [
      {'label': 'Medical Emergency', 'image': 'assets/medical.png'},
      {'label': 'Fire Emergency', 'image': 'assets/fire.png'},
      {'label': 'Security Threat', 'image': 'assets/security.png'},
      {'label': 'Accident', 'image': 'assets/accident.png'},
      {'label': 'Natural Disaster', 'image': 'assets/natural.png'},
      {'label': 'Other Emergency', 'image': 'assets/other.png'},
    ];

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
                  Image.asset(
                    'assets/logo.png',
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
              const SizedBox(height: 16),

              // Emergency type buttons
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: types.map((t) {
                  final isSelected = selected == t['label'];
                  return GestureDetector(
                    onTap: () => setState(() => selected = t['label']),
                    child: Container(
                      width: (MediaQuery.of(context).size.width - 52) / 2,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.red[50] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? red : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            t['image']!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image_not_supported,
                                    size: 40, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t['label']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: floor,
                hint: const Text('Floor'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  'Ground Floor',
                  '1st Floor',
                  '2nd Floor',
                  '3rd Floor',
                  '4th Floor',
                ]
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) => setState(() => floor = v),
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
