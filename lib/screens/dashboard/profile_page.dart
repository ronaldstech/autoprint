import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SingleChildScrollView(
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
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.headlineMedium?.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage your personal information and account settings.',
          style: GoogleFonts.inter(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context, User? user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1), width: 2),
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.05),
              backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child: user?.photoURL == null
                  ? Text(
                      (user?.displayName ?? 'U').isNotEmpty ? (user?.displayName ?? 'U')[0].toUpperCase() : 'U',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'AutoPrint User',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'No email',
                  style: GoogleFonts.inter(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(LucideIcons.edit3, color: AppTheme.primaryColor, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
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
            'K 15,200',
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
            const Color(0xFF10B981),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: AppTheme.softShadow,
      ),
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
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActions(BuildContext context) {
    return Column(
      children: [
        _buildActionButton(
          context: context,
          label: 'Change Password',
          icon: LucideIcons.lock,
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context: context,
          label: 'Notification Settings',
          icon: LucideIcons.bell,
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context: context,
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
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? const Color(0xFFEF4444) : AppTheme.primaryColor;
    
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      trailing: Icon(LucideIcons.chevronRight, color: color.withOpacity(0.3), size: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.borderRadius)),
      tileColor: isDestructive ? color.withOpacity(0.05) : Theme.of(context).primaryColor.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }
}
