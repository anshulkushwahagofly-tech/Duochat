import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:uuid/uuid.dart';
import 'dart:io' show Platform;

import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'profile_setup_screen.dart';
import 'home_screen.dart';

class OtpLoginScreen extends StatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  String _countryCode = '+91';
  String? _verificationId;
  bool _otpSent = false;
  bool _loading = false;
  int _resendSeconds = 0;

  Future<void> _sendOtp() async {
    if (_phoneController.text.trim().length < 7) return;
    setState(() => _loading = true);
    final fullPhone = '$_countryCode${_phoneController.text.trim()}';

    await _auth.verifyPhoneNumber(
      phoneNumber: fullPhone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        // Auto-retrieval on some Android devices
        await _signInWithCredential(credential);
      },
      verificationFailed: (e) {
        setState(() => _loading = false);
        _showError(e.message ?? 'Verification failed');
      },
      codeSent: (verificationId, resendToken) {
        setState(() {
          _verificationId = verificationId;
          _otpSent = true;
          _loading = false;
          _resendSeconds = 30;
        });
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null || _otpController.text.length != 6) return;
    setState(() => _loading = true);
    try {
      final credential = PhoneAuthProvider.credential(verificationId: _verificationId!, smsCode: _otpController.text);
      await _signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      setState(() => _loading = false);
      _showError(e.message ?? 'Invalid OTP');
    }
  }

  Future<void> _signInWithCredential(AuthCredential credential) async {
    final userCredential = await _auth.signInWithCredential(credential);
    final idToken = await userCredential.user!.getIdToken();

    final response = await ApiService().verifyOtp(
      idToken: idToken!,
      deviceId: const Uuid().v4(),
      deviceName: 'DuoChat Device',
      platform: Platform.isIOS ? 'ios' : 'android',
    );

    await ApiService().saveToken(response.data['token']);
    setState(() => _loading = false);

    if (!mounted) return;
    final profileComplete = response.data['user']['profileComplete'] == true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => profileComplete ? const HomeScreen() : const ProfileSetupScreen()),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(gradient: DuoColors.brandGradient, borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.bolt_rounded, color: Colors.white),
              ),
              const SizedBox(height: 28),
              Text(
                _otpSent ? 'Enter verification code' : 'Enter your phone number',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                _otpSent
                    ? 'We sent a 6-digit code via SMS to $_countryCode${_phoneController.text}'
                    : 'DuoChat will send a one-time password to verify your number.',
                style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 14),
              ),
              const SizedBox(height: 32),
              if (!_otpSent) ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      decoration: BoxDecoration(color: DuoColors.surfaceDark2, borderRadius: BorderRadius.circular(16)),
                      child: Text(_countryCode, style: const TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(fontSize: 16),
                        decoration: const InputDecoration(hintText: 'Phone number'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _buildPrimaryButton('Send OTP', _loading ? null : _sendOtp),
              ] else ...[
                PinCodeTextField(
                  appContext: context,
                  length: 6,
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  animationType: AnimationType.fade,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(14),
                    fieldHeight: 52,
                    fieldWidth: 44,
                    activeColor: DuoColors.violet,
                    selectedColor: DuoColors.cyan,
                    inactiveColor: DuoColors.surfaceDark2,
                    activeFillColor: DuoColors.surfaceDark2,
                    selectedFillColor: DuoColors.surfaceDark2,
                    inactiveFillColor: DuoColors.surfaceDark2,
                  ),
                  onChanged: (_) {},
                ),
                const SizedBox(height: 28),
                _buildPrimaryButton('Verify & Continue', _loading ? null : _verifyOtp),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _resendSeconds == 0 ? _sendOtp : null,
                  child: Text(_resendSeconds == 0 ? 'Resend code' : 'Resend in ${_resendSeconds}s'),
                ),
              ],
              if (_loading) const Padding(padding: EdgeInsets.only(top: 20), child: LinearProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(String label, VoidCallback? onTap) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: DuoColors.brandGradient, borderRadius: BorderRadius.circular(16)),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      ),
    );
  }
}
