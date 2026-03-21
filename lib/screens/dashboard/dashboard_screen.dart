import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'jobs_page.dart';
// import 'history_page.dart'; // Removed
import 'summary_page.dart';
import 'settings_page.dart';
import 'profile_page.dart';
import 'transactions_page.dart';
import '../../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;

  late final Stream<int> _pendingJobsCountStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _pendingJobsCountStream = FirebaseFirestore.instance
          .collection('print_jobs')
          .where('user_id', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .where('payment_status', isEqualTo: 'paid')
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } else {
      _pendingJobsCountStream = Stream.value(0);
    }
  }

  final List<({IconData icon, String label})> _destinations = [
    (icon: LucideIcons.layoutDashboard, label: 'Dashboard'),
    (icon: LucideIcons.files, label: 'Jobs'),
    (icon: LucideIcons.wallet, label: 'Payments'),
    (icon: LucideIcons.settings, label: 'Settings'),
    (icon: LucideIcons.user, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 900;

        return SelectionArea(
          child: Scaffold(
            extendBody: true,
            body: Row(
              children: [
                if (!isMobile) _buildDesktopSidebar(context, constraints),
                Expanded(
                  child: Column(
                    children: [
                      _buildHeader(context, isMobile),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: KeyedSubtree(
                            key: ValueKey(_selectedIndex),
                            child: [
                              SummaryPage(
                                onNavigateToJobs: () =>
                                    setState(() => _selectedIndex = 1),
                                onNavigateToWallet: () =>
                                    setState(() => _selectedIndex = 2),
                              ),
                              const JobsPage(),
                              const TransactionsPage(),
                              const SettingsPage(),
                              const ProfilePage(),
                            ][_selectedIndex],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: isMobile ? _buildPremiumBottomNav() : null,
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.8),
        border: Border(
            bottom: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.1))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  // App logo
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _destinations[_selectedIndex].label,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  _buildProfileChip(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL;
    final displayName = user?.displayName ?? 'User';

    return InkWell(
      onTap: () {
        showMenu(
          context: context,
          position: const RelativeRect.fromLTRB(100, 80, 24, 0),
          items: [
            PopupMenuItem(
              onTap: () {
                themeNotifier.value = themeNotifier.value == ThemeMode.light
                    ? ThemeMode.dark
                    : ThemeMode.light;
              },
              child: Row(
                children: [
                  Icon(
                      themeNotifier.value == ThemeMode.light
                          ? LucideIcons.moon
                          : LucideIcons.sun,
                      size: 20),
                  const SizedBox(width: 12),
                  Text(themeNotifier.value == ThemeMode.light
                      ? 'Turn on Dark'
                      : 'Turn off Dark'),
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () => setState(() => _selectedIndex = 3),
              child: const Row(
                children: [
                  Icon(LucideIcons.settings, size: 20),
                  SizedBox(width: 12),
                  Text('Settings')
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () => setState(() => _selectedIndex = 4),
              child: const Row(
                children: [
                  Icon(LucideIcons.user, size: 20),
                  SizedBox(width: 12),
                  Text('Profile')
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () => FirebaseAuth.instance.signOut(),
              child: const Row(
                children: [
                  Icon(LucideIcons.logOut, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Logout', style: TextStyle(color: Colors.red))
                ],
              ),
            ),
          ],
        );
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        clipBehavior: Clip.antiAlias,
        child: photoUrl != null
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildAvatarFallback(displayName),
              )
            : _buildAvatarFallback(displayName),
      ),
    );
  }

  Widget _buildProfileChip() {
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL;
    final displayName = user?.displayName ?? 'User';
    // First 3 letters of the display name, capitalised
    final shortName = displayName.length > 3
        ? displayName.substring(0, 3).toUpperCase()
        : displayName.toUpperCase();

    return InkWell(
      onTap: () {
        showMenu(
          context: context,
          position: const RelativeRect.fromLTRB(100, 80, 24, 0),
          items: [
            PopupMenuItem(
              onTap: () {
                themeNotifier.value = themeNotifier.value == ThemeMode.light
                    ? ThemeMode.dark
                    : ThemeMode.light;
              },
              child: Row(
                children: [
                  Icon(
                    themeNotifier.value == ThemeMode.light
                        ? LucideIcons.moon
                        : LucideIcons.sun,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(themeNotifier.value == ThemeMode.light
                      ? 'Turn on Dark'
                      : 'Turn off Dark'),
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () => setState(() => _selectedIndex = 3),
              child: const Row(
                children: [
                  Icon(LucideIcons.settings, size: 20),
                  SizedBox(width: 12),
                  Text('Settings')
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () => setState(() => _selectedIndex = 4),
              child: const Row(
                children: [
                  Icon(LucideIcons.user, size: 20),
                  SizedBox(width: 12),
                  Text('Profile')
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () => FirebaseAuth.instance.signOut(),
              child: const Row(
                children: [
                  Icon(LucideIcons.logOut, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Logout', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: photoUrl != null
                  ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildAvatarFallback(displayName),
                    )
                  : _buildAvatarFallback(displayName),
            ),
            const SizedBox(width: 6),
            Text(
              shortName,
              style: GoogleFonts.outfit(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronDown,
                size: 12, color: AppTheme.primaryColor.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: GoogleFonts.outfit(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar(
      BuildContext context, BoxConstraints constraints) {
    final bool isCollapsed = constraints.maxWidth < 1100 || _isSidebarCollapsed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isCollapsed ? 88 : 260,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
            right: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.1))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // --- Sidebar Logo ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.printer,
                      color: Colors.white, size: 24),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Text(
                    'AutoPrint',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 40),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _destinations.length,
              itemBuilder: (context, index) {
                final d = _destinations[index];
                final isSelected = _selectedIndex == index;

                return _buildSidebarItem(
                    index, d.icon, d.label, isCollapsed, isSelected);
              },
            ),
          ),

          // --- Collapse Toggle ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: IconButton(
              onPressed: () =>
                  setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
              icon: Icon(
                isCollapsed
                    ? LucideIcons.chevronRight
                    : LucideIcons.chevronLeft,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label,
      bool isCollapsed, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: (() {
            Widget itemContent = Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Theme.of(context).textTheme.bodyMedium?.color,
                  size: 22,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            );

            if (index == 1) {
              // Jobs index
              return StreamBuilder<int>(
                stream: _pendingJobsCountStream,
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  if (count == 0) return itemContent;
                  return Badge(
                    label: Text(count.toString()),
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    offset: isCollapsed
                        ? const Offset(12, -12)
                        : const Offset(8, -8),
                    child: itemContent,
                  );
                },
              );
            }
            return itemContent;
          })(),
        ),
      ),
    );
  }

  Widget _buildPremiumBottomNav() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.85),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBottomNavItem(0, LucideIcons.layoutDashboard, 'Home'),
                  _buildBottomNavItem(1, LucideIcons.plusCircle, 'Jobs'),
                  _buildBottomNavItem(2, LucideIcons.wallet, 'Wallet'),
                  _buildBottomNavItem(4, LucideIcons.user, 'Profile'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    final color = isSelected
        ? AppTheme.primaryColor
        : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6) ??
            Colors.grey;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              (() {
                Widget iconWidget = AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.all(isSelected ? 6 : 0),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withOpacity(0.15)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 22,
                  ),
                );

                if (index == 1) {
                  // Jobs item
                  return StreamBuilder<int>(
                    stream: _pendingJobsCountStream,
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      if (count == 0) return iconWidget;
                      return Badge(
                        label: Text(count.toString()),
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        child: iconWidget,
                      );
                    },
                  );
                }
                return iconWidget;
              })(),
              const SizedBox(height: 2),
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
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
