import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';

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
            _buildHeader(context),
            const SizedBox(height: 32),
            _buildSettingsCategory(context, 'General', [
              _buildSettingsItem(context, LucideIcons.palette, 'Theme Mode', 'Light / Dark'),
              _buildSettingsItem(context, LucideIcons.bell, 'Notifications', 'Enabled'),
              _buildSettingsItem(context, LucideIcons.globe, 'Language', 'English'),
            ]),
            const SizedBox(height: 32),
            _buildSettingsCategory(context, 'Privacy & Security', [
              _buildSettingsItem(context, LucideIcons.shield, 'Security', 'Password & Biometrics'),
              _buildSettingsItem(context, LucideIcons.eye, 'Privacy Policy', ''),
            ]),
            const SizedBox(height: 32),
            _buildSettingsCategory(context, 'Support', [
              _buildSettingsItem(context, LucideIcons.helpCircle, 'Help & Support', ''),
              _buildSettingsItem(context, LucideIcons.info, 'About AutoPrint', 'v1.0.0'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 28,
                color: AppTheme.primaryColor,
              ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Manage your preferences and app configurations.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildSettingsCategory(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 1.2,
            ),
          ),
        ),
        Card(
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(BuildContext context, IconData icon, String title, String value) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.textColor,
          fontSize: 15,
        ),
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
          const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFFE2E8F0)),
        ],
      ),
      onTap: () {},
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
