// lib/screens/sms_otp_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dashboard_page.dart';

class SmsOtpPage extends StatefulWidget {
  static const routeName = '/sms_otp';

  const SmsOtpPage({super.key});

  @override
  State<SmsOtpPage> createState() => _SmsOtpPageState();
}

class _SmsOtpPageState extends State<SmsOtpPage> {
  final TextEditingController _otpCtl = TextEditingController();

  bool _sending = false;
  bool _verifying = false;
  String? _verificationId;
  String? _phoneNumber; // normalized E.164 (+639XXXXXXXXX)

  // countdown
  static const int _cooldownSeconds = 60;
  int _secondsRemaining = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initAndSendCode();
  }

  @override
  void dispose() {
    _otpCtl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ----------------- COUNTDOWN -----------------
  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsRemaining = _cooldownSeconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsRemaining <= 1) {
        t.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining -= 1);
      }
    });
  }

  // ----------------- INIT: READ PHONE FROM FIRESTORE + SEND OTP -----------------
  Future<void> _initAndSendCode() async {
    if (_sending) return;
    setState(() => _sending = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _show('No signed-in user. Please log in again.');
        if (mounted) Navigator.pop(context);
        return;
      }

      final uid = user.uid;

      final snap =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!snap.exists) {
        _show('User profile not found in Firestore.');
        if (mounted) Navigator.pop(context);
        return;
      }

      final data = snap.data() as Map<String, dynamic>;
      String phone = (data['contactNumber'] ?? '').toString().trim();

      if (phone.isEmpty) {
        _show('No phone number found. Please update your profile.');
        if (mounted) Navigator.pop(context);
        return;
      }

      // normalize to E.164 (we expect +639..., but just in case)
      phone = phone.replaceAll(RegExp(r'\s+'), '');
      if (phone.startsWith('09')) {
        phone = '+63${phone.substring(1)}';
      } else if (!phone.startsWith('+')) {
        phone = '+$phone';
      }

      _phoneNumber = phone;

      await _sendCode();
    } catch (e) {
      _show('Error preparing SMS verification: $e');
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ----------------- SEND OTP -----------------
  Future<void> _sendCode() async {
    if (_phoneNumber == null) {
      _show('No phone number available.');
      return;
    }

    setState(() => _sending = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phoneNumber!,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Some Android devices can auto-verify
          await _handleCredential(credential, fromAuto: true);
        },
        verificationFailed: (FirebaseAuthException e) {
          String msg = 'SMS failed: ${e.message}';
          if (e.code == 'too-many-requests') {
            msg =
                'Too many OTP requests. Please wait a while before trying again.';
          }
          _show(msg);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
          });
          _show('OTP sent to $_phoneNumber');
          _startCountdown();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      _show('Error sending OTP: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ----------------- HANDLE CREDENTIAL (AUTO OR MANUAL) -----------------
  Future<void> _handleCredential(
    PhoneAuthCredential credential, {
    bool fromAuto = false,
  }) async {
    setState(() => _verifying = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('No signed-in user.');

      try {
        await currentUser.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'provider-already-linked') {
          // phone provider already linked; it's okay to continue
        } else if (e.code == 'credential-already-in-use') {
          throw Exception(
              'This phone number is already linked to another account.');
        } else if (e.code == 'invalid-verification-code') {
          throw Exception('Invalid or expired code. Please request a new OTP.');
        } else if (e.code == 'session-expired') {
          throw Exception(
              'Verification session expired. Please request a new OTP.');
        } else {
          rethrow;
        }
      }

      // Mark phoneVerified in Firestore
      final uid = currentUser.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'phoneVerified': true}, SetOptions(merge: true));

      if (!mounted) return;
      _show(fromAuto
          ? 'Phone automatically verified!'
          : 'Phone verified successfully.');
      Navigator.pushReplacementNamed(context, DashboardPage.routeName);
    } catch (e) {
      _show('Failed to verify phone: $e');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  // ----------------- VERIFY BUTTON (MANUAL) -----------------
  Future<void> _verifyCodeManually() async {
    if (_verificationId == null) {
      _show('No OTP session. Please resend the code.');
      return;
    }

    final code = _otpCtl.text.trim();
    if (code.length != 6) {
      _show('Enter the 6-digit OTP code.');
      return;
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: code,
    );

    await _handleCredential(credential, fromAuto: false);
  }

  // ----------------- UI -----------------
  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFC82323);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Verification'),
        backgroundColor: red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _sending && _verificationId == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'We sent a verification code to your registered contact number.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  if (_phoneNumber != null)
                    Text(
                      'Number: $_phoneNumber',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _otpCtl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Enter OTP',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _verifying ? null : _verifyCodeManually,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: _verifying
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Verify Code'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_secondsRemaining > 0)
                    Text(
                      'Resend code in $_secondsRemaining s',
                      style: const TextStyle(color: Colors.grey),
                    )
                  else
                    TextButton(
                      onPressed: _sending ? null : _sendCode,
                      child: const Text('Resend OTP'),
                    ),
                ],
              ),
      ),
    );
  }
}
