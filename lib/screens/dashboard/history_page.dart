import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
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
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('print_jobs')
                    .where('user_id', isEqualTo: user?.uid)
                    .orderBy('created_at', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildErrorState(context);
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final date = (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();

                      return _buildHistoryCard(context, data, date, currencyFormat);
                    },
                  );
                },
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
          'Print History',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 28,
                color: AppTheme.primaryColor,
              ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Track and manage all your previous print orders.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    Map<String, dynamic> data,
    DateTime date,
    NumberFormat currencyFormat,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.fileText, color: AppTheme.primaryColor, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['file_name'] ?? 'Unknown File',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat.yMMMd().format(date)} • ${data['page_count']} pages',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(data['cost']),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                _buildStatusChip(data['status'] ?? 'pending'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        icon = LucideIcons.checkCircle;
        break;
      case 'processing':
        color = Colors.blue;
        icon = LucideIcons.loader;
        break;
      default:
        color = Colors.orange;
        icon = LucideIcons.clock;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.history,
              size: 64,
              color: Color(0xFFE2E8F0),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No print history yet.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload your first document to see it here.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.alertCircle, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Unable to load history'),
          TextButton(onPressed: () {}, child: const Text('Try Again')),
        ],
      ),
    );
  }
}
