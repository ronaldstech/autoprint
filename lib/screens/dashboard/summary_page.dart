import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';

class SummaryPage extends StatelessWidget {
  const SummaryPage({super.key});

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
            _buildStatsGrid(context),
            const SizedBox(height: 32),
            _buildQuickActions(context),
            const SizedBox(height: 32),
            _buildRecentActivity(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard Overview',
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 28,
                      color: AppTheme.primaryColor,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Welcome back! Here\'s what\'s happening today.',
                style: const TextStyle(color: Color(0xFF475569), fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Image.asset(
          'assets/images/logo.png',
          height: 50,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.printer, color: AppTheme.primaryColor),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 500 ? 2 : 1);
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              context,
              title: 'Active Jobs',
              value: '3',
              icon: LucideIcons.printer,
              color: AppTheme.primaryColor,
            ),
            _buildStatCard(
              context,
              title: 'Total Prints',
              value: '128',
              icon: LucideIcons.checkCircle,
              color: Colors.green.shade600,
            ),
            _buildStatCard(
              context,
              title: 'Account Balance',
              value: 'UGX 15,200',
              icon: LucideIcons.wallet,
              color: Colors.orange.shade700,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Icon(LucideIcons.moreHorizontal, color: const Color(0xFF94A3B8), size: 20),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildActionChip(
              context,
              label: 'New Print',
              icon: LucideIcons.plus,
              onTap: () {},
            ),
            const SizedBox(width: 12),
            _buildActionChip(
              context,
              label: 'Add Credit',
              icon: LucideIcons.creditCard,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 20),
            _buildActivityItem(
              'Document_124.pdf',
              'Printed successfully',
              '2 hours ago',
              statusColor: Colors.green,
            ),
            const Divider(height: 32),
            _buildActivityItem(
              'Report_Final.pdf',
              'Processing...',
              '5 hours ago',
              statusColor: Colors.blue,
            ),
            const Divider(height: 32),
            _buildActivityItem(
              'Balance Deposit',
              '+ UGX 10,000',
              'Yesterday',
              statusColor: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time, {required Color statusColor}) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
      ],
    );
  }
}
