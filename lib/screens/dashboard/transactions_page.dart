import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            _buildBalanceCard(context, currencyFormat),
            const SizedBox(height: 32),
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildTransactionItem(
                    context,
                    'Deposit via Mobile Money',
                    'March 20, 2026',
                    50000.0,
                    LucideIcons.arrowDownLeft,
                    Colors.green,
                    currencyFormat,
                  ),
                  _buildTransactionItem(
                    context,
                    'Print Job - assignment.pdf',
                    'March 19, 2026',
                    -1500.0,
                    LucideIcons.printer,
                    AppTheme.primaryColor,
                    currencyFormat,
                  ),
                  _buildTransactionItem(
                    context,
                    'Print Job - report_v2.pdf',
                    'March 18, 2026',
                    -200.0,
                    LucideIcons.printer,
                    AppTheme.primaryColor,
                    currencyFormat,
                  ),
                ],
              ),
            ),
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
          'Transactions',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 28,
                color: AppTheme.primaryColor,
              ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Manage your wallet and track your spending.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context, NumberFormat format) {
    return Card(
      color: AppTheme.primaryColor,
      child: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Balance',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              format.format(15200),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('Add Credit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.history, size: 16, color: Colors.white),
                  label: const Text('Bank Details', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    String title,
    String date,
    double amount,
    IconData icon,
    Color color,
    NumberFormat format,
  ) {
    final bool isPositive = amount >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColor),
                  ),
                  Text(
                    date,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                ],
              ),
            ),
            Text(
              '${isPositive ? '+' : ''}${format.format(amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
