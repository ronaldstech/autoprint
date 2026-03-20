import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../upload/upload_page.dart';
import 'history_page.dart';
import 'tasks_page.dart';
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
    const UploadPage(), // New Job
    const HistoryPage(),
    const TasksPage(),
    const TransactionsPage(),
    const SettingsPage(),
    const ProfilePage(),
  ];

  final List<({IconData icon, String label})> _destinations = [
    (icon: Icons.add_circle_outline, label: 'New Job'),
    (icon: LucideIcons.history, label: 'History'),
    (icon: LucideIcons.list, label: 'Tasks'),
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
              if (!isMobile)
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() => _selectedIndex = index);
                  },
                  extended: constraints.maxWidth > 900,
                  labelType: constraints.maxWidth > 900
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Icon(
                          LucideIcons.printer,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        if (constraints.maxWidth > 900) ...[
                          const SizedBox(height: 8),
                          Text(
                            'AutoPrint',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  destinations: _destinations
                      .map((d) => NavigationRailDestination(
                            icon: Icon(d.icon),
                            label: Text(d.label),
                          ))
                      .toList(),
                ),
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
                Icon(
                  LucideIcons.printer,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
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
            onTap: () {
              // Add logout logic
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
