import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../services/theme_provider.dart';
import '../services/api_service.dart';
import 'otp_login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const CircleAvatar(radius: 30, backgroundColor: DuoColors.surfaceDark2, child: Icon(Icons.person_rounded, size: 28)),
            title: const Text('Your name', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
            subtitle: const Text('Hey there! I am using DuoChat.'),
            trailing: const Icon(Icons.qr_code_rounded),
          ),
          const Divider(),
          _sectionLabel('Appearance'),
          RadioListTile<ThemeMode>(
            title: const Text('Dark (Premium default)'),
            value: ThemeMode.dark,
            groupValue: themeProvider.themeMode,
            onChanged: (mode) => themeProvider.setThemeMode(mode!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light'),
            value: ThemeMode.light,
            groupValue: themeProvider.themeMode,
            onChanged: (mode) => themeProvider.setThemeMode(mode!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('System default'),
            value: ThemeMode.system,
            groupValue: themeProvider.themeMode,
            onChanged: (mode) => themeProvider.setThemeMode(mode!),
          ),
          const Divider(),
          _sectionLabel('Privacy'),
          SwitchListTile(title: const Text('Last seen & online'), value: true, onChanged: (_) {}),
          SwitchListTile(title: const Text('Read receipts'), value: true, onChanged: (_) {}),
          const Divider(),
          _sectionLabel('Chats'),
          ListTile(leading: const Icon(Icons.backup_rounded), title: const Text('Chat backup'), subtitle: const Text('Last backup: never'), onTap: () {}),
          ListTile(leading: const Icon(Icons.devices_rounded), title: const Text('Linked devices'), subtitle: const Text('Multi-device login'), onTap: () {}),
          ListTile(leading: const Icon(Icons.qr_code_scanner_rounded), title: const Text('Login with QR code'), onTap: () {}),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text('Log out', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              await ApiService().clearToken();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const OtpLoginScreen()), (_) => false);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(label, style: const TextStyle(color: DuoColors.textDimDark, fontSize: 13, fontWeight: FontWeight.w600)),
      );
}
