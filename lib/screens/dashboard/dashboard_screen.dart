import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
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

  final List<Widget> _pages = [
    const SummaryPage(),
    const JobsPage(),
    const TransactionsPage(),
    const SettingsPage(),
    const ProfilePage(),
  ];

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
                            child: _pages[_selectedIndex],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: isMobile ? _buildBottomNav() : null,
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
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
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
                  Text(
                    _destinations[_selectedIndex].label,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(LucideIcons.bell, color: AppTheme.primaryColor, size: 20),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildProfileAvatar(),
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
                    size: 20
                  ),
                  const SizedBox(width: 12),
                  Text(themeNotifier.value == ThemeMode.light 
                    ? 'Turn on Dark Mode' 
                    : 'Turn on Light Mode'
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () => setState(() => _selectedIndex = 3),
              child: const Row(
                children: [Icon(LucideIcons.settings, size: 20), SizedBox(width: 12), Text('Settings')],
              ),
            ),
            PopupMenuItem(
              onTap: () => setState(() => _selectedIndex = 4),
              child: const Row(
                children: [Icon(LucideIcons.user, size: 20), SizedBox(width: 12), Text('Profile')],
              ),
            ),
            PopupMenuItem(
              onTap: () => FirebaseAuth.instance.signOut(),
              child: const Row(
                children: [Icon(LucideIcons.logOut, size: 20, color: Colors.red), SizedBox(width: 12), Text('Logout', style: TextStyle(color: Colors.red))],
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
                errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(displayName),
              )
            : _buildAvatarFallback(displayName),
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

  Widget _buildDesktopSidebar(BuildContext context, BoxConstraints constraints) {
    final bool isCollapsed = constraints.maxWidth < 1100 || _isSidebarCollapsed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isCollapsed ? 88 : 260,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(right: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
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
                  child: const Icon(LucideIcons.printer, color: Colors.white, size: 24),
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
                
                return _buildSidebarItem(index, d.icon, d.label, isCollapsed, isSelected);
              },
            ),
          ),
          
          // --- Collapse Toggle ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: IconButton(
              onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
              icon: Icon(
                isCollapsed ? LucideIcons.chevronRight : LucideIcons.chevronLeft,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label, bool isCollapsed, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.primaryColor : Theme.of(context).textTheme.bodyMedium?.color,
                size: 22,
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 16),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: isSelected ? AppTheme.primaryColor : Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: _selectedIndex > 2 ? 0 : _selectedIndex,
      onDestinationSelected: (i) => setState(() => _selectedIndex = i),
      destinations: const [
        NavigationDestination(icon: Icon(LucideIcons.layoutDashboard), label: 'Home'),
        NavigationDestination(icon: Icon(LucideIcons.plusCircle), label: 'Jobs'),
        NavigationDestination(icon: Icon(LucideIcons.wallet), label: 'Wallet'),
      ],
    );
  }
}
