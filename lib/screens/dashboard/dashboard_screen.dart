import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../upload/upload_page.dart';
import 'history_page.dart';
import 'summary_page.dart';
import 'settings_page.dart';
import 'profile_page.dart';
import 'transactions_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const SummaryPage(), // Dashboard
    const UploadPage(), // New Job
    const HistoryPage(),
    const TransactionsPage(),
    const SettingsPage(),
    const ProfilePage(),
  ];

  final List<({IconData icon, String label})> _destinations = [
    (icon: LucideIcons.layoutDashboard, label: 'Dashboard'),
    (icon: Icons.add_circle_outline, label: 'New Job'),
    (icon: LucideIcons.history, label: 'History'),
    (icon: LucideIcons.wallet, label: 'Payments'),
    (icon: LucideIcons.settings, label: 'Settings'),
    (icon: LucideIcons.user, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 600;

        return Scaffold(
          appBar: isMobile
              ? AppBar(
                  title: Text(
                    'AutoPrint',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(LucideIcons.bell),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 8),
                  ],
                )
              : null,
          drawer: isMobile ? _buildDrawer(context) : null,
          body: Row(
            children: [
              if (!isMobile) _buildDesktopSidebar(context, constraints),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(
                child: _pages[_selectedIndex],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopSidebar(BuildContext context, BoxConstraints constraints) {
    final bool isExpanded = constraints.maxWidth > 900;

    return Container(
      width: isExpanded ? 240 : 80,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 48,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(LucideIcons.printer, color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 12),
                  Text(
                    'AutoPrint',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _destinations.length,
              itemBuilder: (context, index) {
                final d = _destinations[index];
                final isSelected = _selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedIndex = index),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                        children: [
                          Icon(
                            d.icon,
                            size: 24,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : const Color(0xFF64748B),
                          ),
                          if (isExpanded) ...[
                            const SizedBox(width: 16),
                            Text(
                              d.label,
                              style: TextStyle(
                                fontWeight:
                                    isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : const Color(0xFF1E293B),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ListTile(
              leading: const Icon(LucideIcons.power, color: Colors.red),
              title: isExpanded
                  ? const Text('Logout', style: TextStyle(color: Colors.red))
                  : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 48,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(LucideIcons.printer, color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'AutoPrint',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _destinations.length,
              itemBuilder: (context, index) {
                final d = _destinations[index];
                final isSelected = _selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    selected: isSelected,
                    leading: Icon(
                      d.icon,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : const Color(0xFF64748B),
                    ),
                    title: Text(
                      d.label,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    onTap: () {
                      setState(() => _selectedIndex = index);
                      Navigator.pop(context); // Close drawer
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(LucideIcons.power, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
