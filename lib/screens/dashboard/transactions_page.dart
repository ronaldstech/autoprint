import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTransactionItem(
            'Deposit',
            'March 20, 2026',
            50000.0,
            Icons.add_circle,
            Colors.green,
            currencyFormat,
          ),
          _buildTransactionItem(
            'Print Job - assignment.pdf',
            'March 19, 2026',
            -1500.0,
            Icons.print,
            Colors.blue,
            currencyFormat,
          ),
          _buildTransactionItem(
            'Print Job - report_v2.pdf',
            'March 18, 2026',
            -200.0,
            Icons.print,
            Colors.blue,
            currencyFormat,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(String title, String date, double amount, IconData icon, Color color, NumberFormat format) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(date),
      trailing: Text(
        format.format(amount),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: amount >= 0 ? Colors.green : Colors.red,
        ),
      ),
    );
  }
}
