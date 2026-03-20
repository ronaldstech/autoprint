import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            _buildProfileCard(context, user),
            const SizedBox(height: 24),
            _buildStatGrid(context),
            const SizedBox(height: 32),
            _buildAccountActions(context),
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
          'My Profile',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 28,
                color: AppTheme.primaryColor,
              ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Manage your personal information and account settings.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context, User? user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1), width: 4),
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.05),
                child: const Icon(
                  LucideIcons.user,
                  size: 40,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? 'Print User',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'No email',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 15),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(LucideIcons.edit3, color: AppTheme.primaryColor),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.05),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatGrid(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Wallet Balance',
            'UGX 15,200',
            LucideIcons.wallet,
            AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            'Total Prints',
            '128',
            LucideIcons.printer,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountActions(BuildContext context) {
    return Column(
      children: [
        _buildActionButton(
          label: 'Change Password',
          icon: LucideIcons.lock,
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          label: 'Notification Settings',
          icon: LucideIcons.bell,
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          label: 'Sign Out',
          icon: LucideIcons.logOut,
          onTap: () async {
            await FirebaseAuth.instance.signOut();
          },
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : AppTheme.primaryColor;
    
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(LucideIcons.chevronRight, color: color.withOpacity(0.3), size: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: color.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
