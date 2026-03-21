import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';

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
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 32),
                _buildProfileCard(context, user),
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
          style: GoogleFonts.inter(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context, User? user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayName = user?.displayName ?? 'AutoPrint User';
    final initials =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        child: Column(
          children: [
            // Gradient banner
            Container(
              height: 100,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(
                      LucideIcons.user,
                      size: 120,
                      color: Colors.white.withOpacity(0.07),
                    ),
                  ),
                ],
              ),
            ),

            // Avatar + Info
            Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Avatar with card-colored border (adapts to theme)
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).cardColor,
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor:
                                AppTheme.primaryColor.withOpacity(0.1),
                            backgroundImage: user?.photoURL != null
                                ? NetworkImage(user!.photoURL!)
                                : null,
                            child: user?.photoURL == null
                                ? Text(
                                    initials,
                                    style: GoogleFonts.outfit(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Name + email
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 48),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.color,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user?.email ?? 'No email',
                                  style: GoogleFonts.inter(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Status badge row
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.04)
                            : Colors.black.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.shieldCheck,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            user?.emailVerified == true
                                ? 'Verified Account'
                                : 'Unverified Account',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Active',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.1)),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseAuth.instance.currentUser != null
                    ? FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .snapshots()
                    : const Stream.empty(),
                builder: (context, snapshot) {
                  final userData = snapshot.data?.data() as Map<String, dynamic>?;
                  final String? savedPin = userData?['payment_pin'];
                  final bool hasPin = savedPin != null && savedPin.isNotEmpty;

                  return Column(
                    children: [
                      _buildActionTile(
                        context: context,
                        label: hasPin ? 'Change Payment PIN' : 'Set Payment PIN',
                        icon: LucideIcons.key,
                        onTap: () => _showSetPinDialog(context, savedPin: savedPin),
                      ),
                      Divider(
                          height: 1,
                          color: Theme.of(context).dividerColor.withOpacity(0.08)),
                      _buildBiometricToggle(context, userData),
                      Divider(
                          height: 1,
                          color: Theme.of(context).dividerColor.withOpacity(0.08)),
                    ],
                  );
                },
              ),
              _buildActionTile(
                context: context,
                label: 'Change Password',
                icon: LucideIcons.lock,
                onTap: () {},
              ),
              Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.08)),
              _buildActionTile(
                context: context,
                label: 'Notification Settings',
                icon: LucideIcons.bell,
                onTap: () {},
              ),
              Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.08)),
              _buildActionTile(
                context: context,
                label: 'Sign Out',
                icon: LucideIcons.logOut,
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                },
                isDestructive: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color =
        isDestructive ? const Color(0xFFEF4444) : AppTheme.primaryColor;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(LucideIcons.chevronRight,
                color: color.withOpacity(0.3), size: 18),
          ],
        ),
      ),
    );
  }
  Widget _buildBiometricToggle(
      BuildContext context, Map<String, dynamic>? userData) {
    final LocalAuthentication auth = LocalAuthentication();
    final bool isEnabled = userData?['biometric_enabled'] ?? false;

    return FutureBuilder<bool>(
      future: () async {
        final bool canCheck = await auth.canCheckBiometrics;
        final bool isSupported = await auth.isDeviceSupported();
        return canCheck || isSupported;
      }(),
      builder: (context, snapshot) {
        final bool isSupported = snapshot.data == true;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSupported
                      ? AppTheme.primaryColor.withOpacity(0.08)
                      : Colors.grey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.fingerprint,
                  color: isSupported ? AppTheme.primaryColor : Colors.grey,
                  size: 18,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Biometric Payment',
                      style: GoogleFonts.inter(
                        color: isSupported ? AppTheme.primaryColor : Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (!isSupported)
                      Text(
                        'Not supported on this device',
                        style: GoogleFonts.inter(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isEnabled,
                activeColor: AppTheme.primaryColor,
                onChanged: isSupported
                    ? (bool value) async {
                        if (value) {
                          // Authenticate before enabling
                          try {
                            final bool didAuthenticate = await auth.authenticate(
                              localizedReason:
                                  'Please authenticate to enable biometric payments',
                              options: const AuthenticationOptions(
                                stickyAuth: true,
                                biometricOnly: true,
                              ),
                            );

                            if (didAuthenticate) {
                              _updateBiometricSetting(true);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Biometric error: $e')),
                              );
                            }
                          }
                        } else {
                          _updateBiometricSetting(false);
                        }
                      }
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateBiometricSetting(bool enabled) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({'biometric_enabled': enabled}, SetOptions(merge: true));
  }

  void _showSetPinDialog(BuildContext context, {String? savedPin}) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final controller = TextEditingController();
    bool isLoading = false;
    bool isVerifyingOldPin = savedPin != null;
    String? newPin;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final String title = isVerifyingOldPin
              ? 'Confirm Current PIN'
              : (newPin == null ? 'Set New PIN' : 'Confirm New PIN');
          final String instruction = isVerifyingOldPin
              ? 'Enter your current 4-digit PIN to continue.'
              : (newPin == null
                  ? 'Enter a 4-digit PIN to secure your payments.'
                  : 'Re-enter your new 4-digit PIN to confirm.');

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Theme.of(context).cardColor,
            title: Text(title,
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  instruction,
                  style: GoogleFonts.inter(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 14),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  autofocus: true,
                  style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 10,
                      color: Theme.of(context).textTheme.titleLarge?.color),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: AppTheme.primaryColor.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) async {
                    if (val.length == 4) {
                      if (isVerifyingOldPin) {
                        if (val == savedPin) {
                          setDialogState(() {
                            isVerifyingOldPin = false;
                            controller.clear();
                          });
                        } else {
                          controller.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Incorrect current PIN'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } else if (newPin == null) {
                        setDialogState(() {
                          newPin = val;
                          controller.clear();
                        });
                      } else {
                        if (val == newPin) {
                          // Save to Firestore
                          setDialogState(() => isLoading = true);
                          try {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .set({
                              'payment_pin': val
                            }, SetOptions(merge: true));

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Payment PIN updated successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isLoading = false);
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to update PIN: $e')),
                              );
                            }
                          }
                        } else {
                          controller.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('PINs do not match. Start over.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          setDialogState(() {
                            newPin = null;
                          });
                        }
                      }
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                child: Text('Cancel',
                    style: GoogleFonts.inter(color: AppTheme.textMuted)),
              ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.primaryColor)),
                ),
            ],
          );
        },
      ),
    );
  }
}
