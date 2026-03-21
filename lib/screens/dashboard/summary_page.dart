import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
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
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeHeader(user),
                const SizedBox(height: 32),
                _buildStatsGrid(context),
                const SizedBox(height: 32),
                _buildQuickActions(context),
                const SizedBox(height: 32),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
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
                final status = (doc.data() as Map<String, dynamic>)['print_status'] ?? 'pending';
                if (status == 'completed') {
                  completedJobs++;
                } else if (status == 'pending' || status == 'processing') {
                  activeJobs++;
                }
              }
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 500 ? 2 : 1);
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 2.2,
                  children: [
                    _buildStatCard(
                      context,
                      'Account Balance',
                      'K $balance',
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

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
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

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color color, {required VoidCallback onTap}) {
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
            TextButton(onPressed: () {}, child: const Text('View All')),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: user != null
                ? FirebaseFirestore.instance
                    .collection('print_jobs')
                    .where('user_id', isEqualTo: user.uid)
                    .orderBy('created_at', descending: true)
                    .limit(5)
                    .snapshots()
                : const Stream.empty(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No recent print jobs found',
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                  ),
                );
              }

              final docs = snapshot.data!.docs;
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final fileName = data['file_name'] ?? 'Document.pdf';
                  final pages = data['page_count'] ?? 1;
                  final jobId = docs[index].id;
                  final displayId = jobId.length > 6 ? jobId.substring(0, 6) : jobId;
                  final printStatus = data['print_status'] ?? data['status'] ?? 'pending';

                  String formattedStatus = printStatus;
                  if (formattedStatus.isNotEmpty) {
                    formattedStatus = formattedStatus[0].toUpperCase() + formattedStatus.substring(1).toLowerCase();
                  }

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(LucideIcons.fileText, color: AppTheme.primaryColor, size: 20),
                    ),
                    title: Text(
                      fileName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    subtitle: Text(
                      'ID: #PRN-$displayId • $pages pages',
                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                    ),
                    trailing: _buildStatusChip(formattedStatus),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    final isCompleted = status == 'Completed';
    const emeraldColor = Color(0xFF10B981);
    const amberColor = Color(0xFFF59E0B);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isCompleted ? emeraldColor.withOpacity(0.1) : amberColor.withOpacity(0.1),
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
