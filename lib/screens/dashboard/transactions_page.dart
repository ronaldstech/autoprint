import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
            Text(
              'Transactions',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 28,
                    color: const Color(0xFF0D47A1),
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your recent payment and deposit activity.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView(
                children: [
                  _buildTransactionItem(
                    'Deposit via Mobile Money',
                    'March 20, 2026',
                    50000.0,
                    Icons.add_circle_outline,
                    Colors.green,
                    currencyFormat,
                  ),
                  _buildTransactionItem(
                    'Print Job - assignment.pdf',
                    'March 19, 2026',
                    -1500.0,
                    Icons.print_outlined,
                    Colors.blue,
                    currencyFormat,
                  ),
                  _buildTransactionItem(
                    'Print Job - report_v2.pdf',
                    'March 18, 2026',
                    -200.0,
                    Icons.print_outlined,
                    Colors.blue,
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

  Widget _buildTransactionItem(String title, String date, double amount, 
      IconData icon, Color color, NumberFormat format) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          date,
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
        trailing: Text(
          format.format(amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: amount >= 0 ? Colors.green.shade700 : Colors.red.shade700,
          ),
        ),
      ),
    );
  }
}
