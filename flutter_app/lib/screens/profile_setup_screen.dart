import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _aboutController = TextEditingController(text: 'Hey there! I am using DuoChat.');
  File? _avatarFile;
  bool _saving = false;

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _avatarFile = File(picked.path));
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _saving = true);

    String? avatarUrl;
    if (_avatarFile != null) {
      final uploadRes = await ApiService().uploadFile(_avatarFile!.path, 'avatars');
      avatarUrl = uploadRes.data['url'];
    }

    await ApiService().updateMe({
      'name': _nameController.text.trim(),
      'about': _aboutController.text.trim(),
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    });

    setState(() => _saving = false);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set up your profile')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _avatarFile == null ? DuoColors.brandGradient : null,
                      image: _avatarFile != null ? DecorationImage(image: FileImage(_avatarFile!), fit: BoxFit.cover) : null,
                    ),
                    child: _avatarFile == null
                        ? const Icon(Icons.person_rounded, size: 56, color: Colors.white)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: DuoColors.cyan, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Your name', prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _aboutController,
              maxLength: 150,
              decoration: const InputDecoration(hintText: 'About', prefixIcon: Icon(Icons.info_outline)),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: DuoColors.brandGradient, borderRadius: BorderRadius.circular(16)),
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
