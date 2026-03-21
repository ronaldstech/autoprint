import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

class SummaryPage extends StatelessWidget {
  final VoidCallback? onNavigateToJobs;
  final VoidCallback? onNavigateToWallet;

  const SummaryPage({
    super.key,
    this.onNavigateToJobs,
    this.onNavigateToWallet,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeHeader(user),
                const SizedBox(height: 20),
                _buildStatsGrid(context),
                const SizedBox(height: 20),
                _buildQuickActions(context),
                const SizedBox(height: 20),
                _buildRecentActivity(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(User? user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              LucideIcons.printer,
              size: 140,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.displayName ?? 'Valued Printer',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Your printer is ready for new jobs.',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final balance = data?['balance'] ?? 0;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('print_jobs')
              .where('user_id', isEqualTo: user.uid)
              .snapshots(),
          builder: (context, jobsSnapshot) {
            int activeJobs = 0;
            int completedJobs = 0;

            if (jobsSnapshot.hasData) {
              for (var doc in jobsSnapshot.data!.docs) {
                final status =
                    (doc.data() as Map<String, dynamic>)['print_status'] ??
                        'pending';
                if (status == 'completed') {
                  completedJobs++;
                } else if (status == 'pending' || status == 'processing') {
                  activeJobs++;
                }
              }
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900
                    ? 3
                    : (constraints.maxWidth > 500 ? 2 : 1);
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 2.2,
                  children: [
                    _buildStatCard(
                      context,
                      'Account Balance',
                      'K ${NumberFormat('#,###').format(balance)}',
                      LucideIcons.wallet,
                      AppTheme.primaryColor,
                    ),
                    _buildStatCard(
                      context,
                      'Active Jobs',
                      activeJobs.toString(),
                      LucideIcons.activity,
                      AppTheme.secondaryColor,
                    ),
                    _buildStatCard(
                      context,
                      'Completed',
                      completedJobs.toString(),
                      LucideIcons.checkCircle,
                      const Color(0xFF8B5CF6),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: color.withOpacity(0.20)),
        boxShadow: AppTheme.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        child: Stack(
          children: [
            // Subtle color wash background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.14),
                      color.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            // Big background icon
            Positioned(
              right: -14,
              top: -14,
              child: Icon(
                icon,
                size: 90,
                color: color.withOpacity(0.08),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
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
        Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildActionButton(
              context,
              'New Print Job',
              LucideIcons.plusCircle,
              AppTheme.primaryColor,
              onTap: onNavigateToJobs ?? () {},
            ),
            const SizedBox(width: 16),
            _buildActionButton(
              context,
              'Top Up Wallet',
              LucideIcons.creditCard,
              AppTheme.secondaryColor,
              onTap: onNavigateToWallet ?? () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
      BuildContext context, String label, IconData icon, Color color,
      {required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            border: Border.all(color: color.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Print Jobs',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            TextButton(
              onPressed: onNavigateToJobs,
              child: Text(
                'View All',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        StreamBuilder<QuerySnapshot>(
          stream: user != null
              ? FirebaseFirestore.instance
                  .collection('print_jobs')
                  .where('user_id', isEqualTo: user.uid)
                  .orderBy('created_at', descending: true)
                  .limit(3) // Smaller list for summary overview
                  .snapshots()
              : const Stream.empty(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator()));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.08)),
                ),
                child: Column(
                  children: [
                    Icon(LucideIcons.printer,
                        size: 48, color: AppTheme.textMuted.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text(
                      'No recent print jobs found',
                      style: GoogleFonts.inter(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              );
            }

            final docs = snapshot.data!.docs;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                return _buildRecentJobCard(context, docs[index].id, data);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentJobCard(
      BuildContext context, String jobId, Map<String, dynamic> data) {
    final fileName = data['file_name'] ?? 'Document.pdf';
    final pages = data['page_count'] ?? 1;
    final displayId = jobId.length > 6
        ? jobId.substring(0, 6).toUpperCase()
        : jobId.toUpperCase();
    final printStatus = data['print_status'] ?? data['status'] ?? 'pending';
    final rawToken = data['print_token'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border:
            Border.all(color: Theme.of(context).dividerColor.withOpacity(0.08)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.fileText,
                      color: AppTheme.primaryColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '#$displayId',
                            style: GoogleFonts.inter(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• $pages Pages',
                            style: GoogleFonts.inter(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (rawToken != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppTheme.secondaryColor.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.ticket,
                      size: 14, color: AppTheme.secondaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'TOKEN:',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryColor.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    rawToken.toString(),
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusChip(printStatus),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.eye,
                          size: 18, color: AppTheme.primaryColor),
                      onPressed: () =>
                          _previewDocument(context, data['file_url']),
                      tooltip: 'Preview Document',
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 32,
                      width: 1,
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: AppTheme.textMuted.withOpacity(0.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _previewDocument(BuildContext context, String? url) async {
    debugPrint('--- Summary Preview URL ---');
    debugPrint('URL: $url');

    if (url == null || url.isEmpty) {
      debugPrint('Error: Summary Preview URL is null or empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No preview available for this document')),
      );
      return;
    }

    final uri = Uri.parse(url);
    try {
      final canLaunch = await canLaunchUrl(uri);
      debugPrint('Summary Preview - Can launch: $canLaunch');

      if (canLaunch) {
        debugPrint('Summary Preview - Launching...');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Summary Preview - Error: canLaunchUrl returned false');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the document')),
        );
      }
    } catch (e) {
      debugPrint('Summary Preview - Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildStatusChip(String status) {
    final isCompleted = status == 'Completed';
    const emeraldColor = Color(0xFF10B981);
    const amberColor = Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isCompleted
            ? emeraldColor.withOpacity(0.1)
            : amberColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isCompleted ? emeraldColor : amberColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
