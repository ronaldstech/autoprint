import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 28,
                    color: const Color(0xFF0D47A1),
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage your preferences and app settings.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 32),
            _buildSettingsSection(context, [
              _buildSettingsItem(Icons.palette_outlined, 'Theme Mode', 'Light / Dark'),
              _buildSettingsItem(Icons.notifications_none_rounded, 'Notifications', 'Enabled'),
              _buildSettingsItem(Icons.language_rounded, 'Language', 'English'),
            ]),
            const SizedBox(height: 24),
            _buildSettingsSection(context, [
              _buildSettingsItem(Icons.security_rounded, 'Security', 'Password & Biometrics'),
              _buildSettingsItem(Icons.help_outline_rounded, 'Help & Support', ''),
              _buildSettingsItem(Icons.info_outline_rounded, 'About AutoPrint', 'v1.0.0'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, List<Widget> items) {
    return Card(
      child: Column(
        children: items,
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0D47A1), size: 22),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value.isNotEmpty)
            Text(
              value,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFE2E8F0)),
        ],
      ),
      onTap: () {},
    );
  }
}
