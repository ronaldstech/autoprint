import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'jobs_page.dart';
// import 'history_page.dart'; // Removed
import 'summary_page.dart';
import 'settings_page.dart';
import 'profile_page.dart';
import 'transactions_page.dart';
import '../../theme/app_theme.dart';
import 'widgets/premium_bottom_nav.dart';

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
    (icon: Iconsax.home_2, label: 'Dashboard'),
    (icon: Iconsax.receipt_item, label: 'Jobs'),
    (icon: Iconsax.wallet_2, label: 'Payments'),
    (icon: Iconsax.setting_2, label: 'Settings'),
    (icon: Iconsax.profile_circle, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 900;

        return SelectionArea(
          child: Scaffold(
            extendBody: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            bottomNavigationBar: isMobile
              ? PremiumBottomNav(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) =>
                  setState(() => _selectedIndex = index),
                pendingJobsCountStream: _pendingJobsCountStream,
                )
              : null,
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    final theme = Theme.of(context);
    final currentPage = _destinations[_selectedIndex].label;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.92),
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withOpacity(0.12)),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  if (isMobile)
                    Container(
                      width: 38,
                      height: 38,
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset('assets/images/logo.png'),
                    ),
                  if (isMobile) const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentPage,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!isMobile)
                        Text(
                          _selectedIndex == 0
                              ? 'Your workspace at a glance'
                              : 'Manage your AutoPrint workspace',
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                  const Spacer(),
                  if (!isMobile) ...[
                    _buildHeaderStatus(theme),
                    const SizedBox(width: 14),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Iconsax.notification),
                      tooltip: 'Notifications',
                    ),
                  ],
                  _buildProfileChip(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStatus(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppTheme.secondaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            'All systems ready',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppTheme.secondaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
                          ? Iconsax.moon
                          : Iconsax.sun_1,
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
                  Icon(Iconsax.setting_2, size: 20),
                  SizedBox(width: 12),
                  Text('Settings')
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () => setState(() => _selectedIndex = 4),
              child: const Row(
                children: [
                  Icon(Iconsax.profile_circle, size: 20),
                  SizedBox(width: 12),
                  Text('Profile')
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () => FirebaseAuth.instance.signOut(),
              child: const Row(
                children: [
                  Icon(Iconsax.logout, size: 20, color: Colors.red),
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
                        ? Iconsax.moon
                        : Iconsax.sun_1,
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
                  Icon(Iconsax.setting_2, size: 20),
                  SizedBox(width: 12),
                  Text('Settings')
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () => setState(() => _selectedIndex = 4),
              child: const Row(
                children: [
                  Icon(Iconsax.profile_circle, size: 20),
                  SizedBox(width: 12),
                  Text('Profile')
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () => FirebaseAuth.instance.signOut(),
              child: const Row(
                children: [
                  Icon(Iconsax.logout, size: 20, color: Colors.red),
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
            Icon(Iconsax.arrow_down_1,
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
        color: Theme.of(context).cardColor.withOpacity(0.96),
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
                  child: const Icon(Iconsax.printer,
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
          const SizedBox(height: 36),
          if (!isCollapsed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'WORKSPACE',
                  style: GoogleFonts.inter(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),

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
                    ? Iconsax.arrow_right_3
                    : Iconsax.arrow_left_2,
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
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor.withOpacity(0.12)
                  : Colors.transparent,
            ),
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

}
