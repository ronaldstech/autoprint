import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/upload_service.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  String? _fileName;
  int? _pageCount;
  double? _cost;
  bool _isProcessing = false;
  Uint8List? _fileBytes;
  final TextEditingController _jobNameController = TextEditingController();

  final NumberFormat _currencyFormat =
      NumberFormat.currency(symbol: 'K ', decimalDigits: 0);

  String _selectedStatus = 'All';
  final List<String> _statuses = ['All', 'Pending', 'Processing', 'Completed'];

  static const Color _amber = Color(0xFFF59E0B);
  static const Color _blue = Color(0xFF3B82F6);
  static const Color _emerald = Color(0xFF10B981);
  static const Color _rose = Color(0xFFF43F5E);
  static const Color _violet = Color(0xFF8B5CF6);

  Future<void> _pickFile() async {
    setState(() {
      _isProcessing = true;
      _fileName = null;
      _pageCount = null;
      _cost = null;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'pptx'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final bytes = result.files.single.bytes!;

        setState(() {
          _fileBytes = bytes;
          _fileName = result.files.single.name;
          _jobNameController.text = _fileName!.split('.').first;

          if (_fileName!.toLowerCase().endsWith('.pdf')) {
            try {
              final PdfDocument document = PdfDocument(inputBytes: bytes);
              _pageCount = document.pages.count;
              document.dispose();
              _cost = _pageCount! * 150.0;
            } catch (e) {
              _pageCount = 1;
              _cost = 150.0;
            }
          } else {
            _pageCount = null;
            _cost = 50.0; // Flat fee for non-PDF documents
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            width: 340,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _submitJob(StateSetter? setModalState) async {
    if (_fileBytes == null) return;

    if (setModalState != null) {
      setModalState(() => _isProcessing = true);
    }
    setState(() => _isProcessing = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final String downloadUrl = await UploadService.uploadFile(
        fileName: _fileName!,
        fileBytes: _fileBytes!,
      );

      await FirebaseFirestore.instance.collection('print_jobs').add({
        'user_id': user.uid,
        'job_name': _jobNameController.text.trim().isEmpty
            ? _fileName
            : _jobNameController.text.trim(),
        'file_name': _fileName,
        'file_url': downloadUrl,
        'page_count': _pageCount,
        'cost': _cost,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
        'print_status': 'pending',
        'payment_status': 'pending',
      });

      if (mounted) {
        _resetUpload();
        Navigator.pop(context); // Close modal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Print job submitted successfully!'),
            backgroundColor: Colors.green,
            width: 340,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            width: 340,
          ),
        );
      }
    } finally {
      if (mounted) {
        if (setModalState != null) {
          setModalState(() => _isProcessing = false);
        }
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handlePayment(String jobId, double cost) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isProcessing = true);

    try {
      // 1. Fetch user's PIN from Firestore
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final String? savedPin = userDoc.data()?['payment_pin'];

      if (savedPin == null) {
        setState(() => _isProcessing = false);
        if (mounted) {
          _showNoPinDialog();
        }
        return;
      }

      // 2. Check for Biometrics
      final bool biometricEnabled =
          userDoc.data()?['biometric_enabled'] ?? false;
      bool authenticated = false;

      if (biometricEnabled) {
        final LocalAuthentication auth = LocalAuthentication();
        try {
          authenticated = await auth.authenticate(
            localizedReason:
                'Authorize payment of MK ${cost.toStringAsFixed(2)}',
            options: const AuthenticationOptions(
              stickyAuth: true,
              biometricOnly: true,
            ),
          );
        } catch (e) {
          debugPrint('Biometric Error: $e');
          // If biometric fails (no hardware, etc.), fall back to PIN
        }
      }

      // 3. Show PIN confirmation dialog if not authenticated via biometrics
      if (!authenticated) {
        final bool? pinCorrect = await _showPinConfirmationDialog(savedPin);
        if (pinCorrect != true) {
          setState(() => _isProcessing = false);
          return;
        }
      }

      // 4. Proceed with transaction
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        debugPrint('Starting payment transaction for jobId: $jobId');
        final userDocRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        final jobDocRef =
            FirebaseFirestore.instance.collection('print_jobs').doc(jobId);

        debugPrint('Fetching user document...');
        final userSnapshot = await transaction.get(userDocRef);

        double currentBalance = 0;
        if (userSnapshot.exists) {
          final data = userSnapshot.data();
          currentBalance = (data?['balance'] ?? 0).toDouble();
          debugPrint('User found. Current balance: $currentBalance');
        } else {
          debugPrint('User document not found. Initializing with balance 0.');
          transaction.set(userDocRef, {'balance': 0});
          currentBalance = 0;
        }

        if (currentBalance < cost) {
          debugPrint('Insufficient balance: $currentBalance < $cost');
          throw Exception(
              'Insufficient balance. Your balance is K $currentBalance but the cost is K $cost.');
        }

        // 1. Deduct balance
        transaction.update(userDocRef, {'balance': currentBalance - cost});

        // 2. Update job payment status
        final String token =
            DateTime.now().millisecondsSinceEpoch.toString().substring(7) +
                (Random().nextInt(899999) + 100000).toString();
        transaction.update(
            jobDocRef, {'payment_status': 'paid', 'print_token': token});

        // 3. Record transaction
        final txRef = 'JOB_${DateTime.now().millisecondsSinceEpoch}';
        final transactionRef =
            FirebaseFirestore.instance.collection('transactions').doc();
        transaction.set(transactionRef, {
          'userId': user.uid,
          'amount': -cost,
          'type': 'print',
          'status': 'success',
          'description': 'Job Payment (Token: $token)',
          'timestamp': FieldValue.serverTimestamp(),
          'txRef': txRef,
          'job_id': jobId,
        });
        debugPrint('Transaction writes successfully queued.');
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful!'),
            backgroundColor: Colors.green,
            width: 340,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        debugPrint('Payment Error: $e');
        String errorMessage = e.toString();

        // Handle JS-wrapped errors on Web
        if (errorMessage.contains('Dart exception thrown')) {
          errorMessage =
              'Transaction failed. Please ensure your balance is sufficient and try again.';
        } else if (errorMessage.contains('Exception: ')) {
          errorMessage = errorMessage.split('Exception: ').last;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $errorMessage'),
            backgroundColor: Colors.red,
            width: 340,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _copyToken(String token) async {
    await Clipboard.setData(ClipboardData(text: token));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Print token copied to clipboard'),
          width: 340,
        ),
      );
    }
  }

  void _showNoPinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Security PIN Required',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          'For your security, you must set a 4-digit payment PIN before you can pay for jobs.',
          style: GoogleFonts.inter(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to Profile tab or show instructions
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Go to Profile > Account > Set Payment PIN')),
              );
            },
            child: const Text('Go to Profile'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showPinConfirmationDialog(String savedPin) async {
    final controller = TextEditingController();

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Confirm PIN',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your 4-digit PIN to authorize this payment.',
              style: GoogleFonts.inter(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              textAlign: TextAlign.center,
              autofocus: true,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 10,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: AppTheme.primaryColor.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                if (val.length == 4) {
                  if (val == savedPin) {
                    Navigator.pop(dialogContext, true);
                  } else {
                    controller.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Incorrect PIN. Please try again.'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppTheme.textMuted)),
          ),
        ],
      ),
    );
  }

  Future<void> _previewDocument(String? url) async {
    debugPrint('--- Preview Document ---');
    debugPrint('URL: $url');

    if (url == null || url.isEmpty) {
      debugPrint('Error: URL is null or empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No preview available for this document')),
      );
      return;
    }

    final uri = Uri.parse(url);
    try {
      final canLaunch = await canLaunchUrl(uri);
      debugPrint('Can launch URL: $canLaunch');

      if (canLaunch) {
        debugPrint('Launching URL...');
        final launched =
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('Launch status: $launched');
      } else {
        debugPrint('Error: Could not launch URL (canLaunchUrl returned false)');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open the document')),
          );
        }
      }
    } catch (e) {
      debugPrint('Exception during preview: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _resetUpload() {
    setState(() {
      _fileName = null;
      _pageCount = null;
      _cost = null;
      _fileBytes = null;
      _jobNameController.clear();
    });
  }

  void _showUploadModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.only(
                    left: 24, right: 24, top: 12, bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDragHandle(),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('New Printing Job',
                                style: GoogleFonts.outfit(
                                    fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              'Upload a document and we\'ll handle the rest',
                              style: GoogleFonts.inter(
                                  color: AppTheme.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Theme.of(context)
                                    .dividerColor
                                    .withOpacity(0.1)),
                          ),
                          child: IconButton(
                              icon: const Icon(Iconsax.close_circle),
                              color: AppTheme.textMuted,
                              onPressed: () => Navigator.pop(context)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildStepIndicator(),
                    const SizedBox(height: 20),
                    _buildUploadArea(setModalState),
                    if (_fileName != null) ...[
                      const SizedBox(height: 22),
                      _buildModalSection(
                        icon: Iconsax.text,
                        title: 'Job Name',
                        child: TextField(
                          controller: _jobNameController,
                          onChanged: (val) => setModalState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Enter a name for this job',
                            prefixIcon: const Icon(Iconsax.text),
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _buildModalSection(
                        icon: Iconsax.calculator,
                        title: 'File Summary',
                        child: _buildFileDetails(setModalState),
                      ),
                    ],
                    const SizedBox(height: 28),
                    _buildActionButtons(setModalState),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor.withOpacity(0.35),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final hasFile = _fileName != null;
    final steps = [
      (label: 'Choose File', icon: Iconsax.document_upload, active: true),
      (label: 'Job Details', icon: Iconsax.edit_2, active: hasFile),
    ];
    return Row(
      children: List.generate(steps.length, (index) {
        final isLast = index == steps.length - 1;
        final isActive = steps[index].active;
        return Expanded(
          child: isLast
              ? _StepPill(icon: steps[index].icon, label: steps[index].label,
                  active: isActive)
              : Row(
                  children: [
                    Expanded(
                        child: _StepPill(
                            icon: steps[index].icon,
                            label: steps[index].label,
                            active: isActive)),
                    Container(
                      width: 28,
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      color: isActive
                          ? AppTheme.primaryColor.withOpacity(0.4)
                          : Theme.of(context).dividerColor.withOpacity(0.2),
                    ),
                  ],
                ),
        );
      }),
    );
  }

  Widget _buildModalSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(title,
                style: GoogleFonts.outfit(
                    fontSize: 17, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  void _pickFileInModal(StateSetter setModalState) async {
    await _pickFile();
    setModalState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton.extended(
          onPressed: _showUploadModal,
          icon: const Icon(Iconsax.add),
          label: const Text('New Job'),
          backgroundColor: AppTheme.primaryColor,
          elevation: 4,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: StreamBuilder<QuerySnapshot>(
            stream: user != null
                ? (_selectedStatus == 'All'
                    ? FirebaseFirestore.instance
                        .collection('print_jobs')
                        .where('user_id', isEqualTo: user.uid)
                        .orderBy('created_at', descending: true)
                        .snapshots()
                    : FirebaseFirestore.instance
                        .collection('print_jobs')
                        .where('user_id', isEqualTo: user.uid)
                        .where('print_status',
                            isEqualTo: _selectedStatus.toLowerCase())
                        .orderBy('created_at', descending: true)
                        .snapshots())
                : const Stream.empty(),
            builder: (context, snapshot) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.only(
                        top: 24.0, left: 24.0, right: 24.0),
                    sliver: SliverToBoxAdapter(
                      child: _buildHeader(snapshot),
                    ),
                  ),
                  _buildSliverContent(snapshot),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSliverContent(AsyncSnapshot<QuerySnapshot> snapshot) {
    if (snapshot.hasError) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('Error: ${snapshot.error}')),
      );
    }

    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final docs = snapshot.data?.docs ?? [];
    if (docs.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 110),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildJobCard(data, docs[index].id);
          },
          childCount: docs.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 168,
            height: 168,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.14),
                  AppTheme.primaryColor.withOpacity(0.02),
                ],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.15),
                        width: 2),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.premiumShadow,
                  ),
                  child: Icon(
                    _selectedStatus == 'All'
                        ? Iconsax.printer
                        : Iconsax.search_status,
                    size: 48,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _selectedStatus == 'All'
                ? 'No printing jobs yet'
                : 'No matches found',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _selectedStatus == 'All'
                ? 'Ready to print? Select a file and start your first job.'
                : 'Try adjusting your filters to find what you\'re looking for.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppTheme.textMuted,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          if (_selectedStatus == 'All') ...[
            const SizedBox(height: 32),
            _buildGradientButton(
              onPressed: _pickFile,
              icon: Iconsax.add,
              label: 'Create New Job',
              size: const Size(220, 56),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> data, String jobId) {
    final String status = data['status'] ?? 'pending';
    final String printStatus =
        data['print_status'] ?? data['status'] ?? status;
    final String paymentStatus = data['payment_status'] ?? 'pending';
    final String jobName = data['job_name'] ?? 'Untitled Job';
    final DateTime createdAt =
        (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();

    final bool isProcessing = printStatus == 'processing';
    final Color statusColor = _getStatusColor(printStatus);
    final Color paymentColor = _getPaymentStatusColor(paymentStatus);
    final String displayId = jobId.length > 6
        ? jobId.substring(0, 6).toUpperCase()
        : jobId.toUpperCase();
    final bool showPayButton =
        paymentStatus != 'success' && paymentStatus != 'paid';
    final double? cost = (data['cost'] as num?)?.toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            if (isProcessing)
              LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: Colors.transparent,
                valueColor:
                    AlwaysStoppedAnimation<Color>(statusColor),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFileIcon(data['file_name'] ?? ''),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    jobName,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.color,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isProcessing) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor
                                        .withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '#$displayId',
                                    style: GoogleFonts.inter(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    '• ${DateFormat('MMM dd, HH:mm').format(createdAt)}',
                                    style: GoogleFonts.inter(
                                      color: AppTheme.textMuted,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.primaryDark,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: AppTheme.premiumShadow,
                            ),
                            child: Text(
                              _currencyFormat.format(data['cost'] ?? 0),
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            data['page_count'] != null
                                ? '${data['page_count']} Pages'
                                : 'Document',
                            style: GoogleFonts.inter(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    data['file_name'] ?? 'Unknown File',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (data['print_token'] != null) ...[
                    const SizedBox(height: 14),
                    _buildTokenCard(data['print_token'].toString()),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildStatusBadge(
                        label: 'Printing',
                        value: printStatus,
                        color: statusColor,
                        icon: _getStatusIcon(printStatus),
                      ),
                      _buildStatusBadge(
                        label: 'Payment',
                        value: paymentStatus,
                        color: paymentColor,
                        icon: _getPaymentStatusIcon(paymentStatus),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      if (showPayButton && cost != null) ...[
                        Expanded(
                          child: _buildGradientButton(
                            onPressed: _isProcessing
                                ? null
                                : () => _handlePayment(jobId, cost),
                            icon: _isProcessing
                                ? null
                                : Iconsax.card_tick,
                            label: _isProcessing
                                ? 'Processing...'
                                : 'Pay Now',
                            size: const Size(double.infinity, 46),
                            showSpinner: _isProcessing,
                          ),
                        ),
                        if (data['file_url'] != null) const SizedBox(width: 12),
                      ],
                      if (data['file_url'] != null)
                        Expanded(
                          child: _buildTonalButton(
                            onPressed: () =>
                                _previewDocument(data['file_url']),
                            icon: Iconsax.eye,
                            label: 'Preview',
                            size: const Size(double.infinity, 46),
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
    );
  }

  Widget _buildFileIcon(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    Color color;
    IconData icon;

    switch (ext) {
      case 'pdf':
        color = _rose;
        icon = Iconsax.document_text_1;
        break;
      case 'doc':
      case 'docx':
        color = _blue;
        icon = Iconsax.document_text_1;
        break;
      case 'pptx':
        color = _amber;
        icon = Iconsax.presention_chart;
        break;
      default:
        color = _violet;
        icon = Iconsax.document;
    }

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.16), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.14), width: 1),
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }

  Widget _buildTokenCard(String token) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.secondaryColor.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Iconsax.ticket,
                  size: 18, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PRINT TOKEN',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor.withOpacity(0.7),
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    token,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                      letterSpacing: 4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () => _copyToken(token),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Iconsax.copy,
                    size: 16, color: AppTheme.primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Material(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.16), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$label: ',
              style: GoogleFonts.inter(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 11,
              ),
            ),
            Text(
              value.toUpperCase(),
              style: GoogleFonts.inter(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Iconsax.tick_circle;
      case 'pending':
        return Iconsax.clock;
      case 'processing':
        return Iconsax.refresh;
      default:
        return Iconsax.info_circle;
    }
  }

  IconData _getPaymentStatusIcon(String status) {
    switch (status) {
      case 'success':
      case 'paid':
        return Iconsax.shield_tick;
      case 'pending':
        return Iconsax.warning_2;
      case 'failed':
        return Iconsax.close_circle;
      default:
        return Iconsax.card;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return _emerald;
      case 'pending':
        return _amber;
      case 'processing':
        return _blue;
      default:
        return Colors.grey;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'success':
      case 'paid':
        return _emerald;
      case 'pending':
        return _amber;
      case 'failed':
        return _rose;
      default:
        return Colors.grey;
    }
  }

  Widget _buildHeader(AsyncSnapshot<QuerySnapshot> snapshot) {
    final theme = Theme.of(context);

    final docs = snapshot.hasData ? snapshot.data!.docs : <QueryDocumentSnapshot>[];
    int activeCount = 0;
    double totalSpent = 0;
    for (final doc in docs) {
      final d = doc.data() as Map<String, dynamic>;
      final st = d['print_status'] ?? d['status'] ?? 'pending';
      if (st == 'pending' || st == 'processing') {
        activeCount++;
      }
      final payment = d['payment_status'];
      if ((payment == 'paid' || payment == 'success') && d['cost'] != null) {
        totalSpent += (d['cost'] as num).toDouble();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppTheme.premiumShadow,
          ),
          child: Stack(
            children: [
              // Decorative blobs
              Positioned(
                right: -40,
                top: -60,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.07),
                  ),
                ),
              ),
              Positioned(
                right: 60,
                bottom: 30,
                child: Icon(Iconsax.document_copy,
                    size: 130, color: Colors.white.withOpacity(0.06)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Iconsax.receipt_item,
                                      color: Colors.white, size: 14),
                                  const SizedBox(width: 8),
                                  Text(
                                    'PRINT QUEUE',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'My Jobs',
                              style: GoogleFonts.outfit(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Track and manage your printing work from one place.',
                              style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.78),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.18)),
                        ),
                        child: const Icon(Iconsax.document_copy,
                            color: Colors.white, size: 30),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      _buildHeroStat(
                        icon: Iconsax.document,
                        value: docs.length.toString(),
                        label: 'Total Jobs',
                      ),
                      const SizedBox(width: 12),
                      _buildHeroStat(
                        icon: Iconsax.timer_1,
                        value: activeCount.toString(),
                        label: 'Active',
                      ),
                      const SizedBox(width: 12),
                      _buildHeroStat(
                        icon: Iconsax.dollar_circle,
                        value: _currencyFormat.format(totalSpent),
                        label: 'Spent',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Filter jobs',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              docs.length.toString() + (docs.length == 1 ? ' job' : ' jobs'),
              style: GoogleFonts.inter(
                color: AppTheme.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _statuses.map((status) {
              final isSelected = _selectedStatus == status;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : theme.dividerColor.withOpacity(0.14),
                    ),
                    boxShadow: isSelected ? AppTheme.premiumShadow : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() => _selectedStatus = status),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getFilterIcon(status),
                              size: 15,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textMuted,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              status,
                              style: GoogleFonts.inter(
                                color: isSelected
                                    ? Colors.white
                                    : theme.textTheme.bodyMedium?.color,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  IconData _getFilterIcon(String status) {
    switch (status) {
      case 'All':
        return Iconsax.category_2;
      case 'Pending':
        return Iconsax.clock;
      case 'Processing':
        return Iconsax.refresh;
      case 'Completed':
        return Iconsax.tick_circle;
      default:
        return Iconsax.category;
    }
  }

  Widget _buildHeroStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.9), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
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

  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required IconData? icon,
    required String label,
    required Size size,
    bool showSpinner = false,
  }) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        gradient: onPressed == null
            ? LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.4),
                  AppTheme.primaryDark.withOpacity(0.4),
                ],
              )
            : const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: onPressed == null ? null : AppTheme.premiumShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showSpinner)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                else if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTonalButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Size size,
  }) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.16)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadArea(StateSetter setModalState) {
    return GestureDetector(
      onTap: !_isProcessing ? () => _pickFileInModal(setModalState) : null,
      child: CustomPaint(
        painter: _fileName == null
            ? DashedBorderPainter(color: AppTheme.primaryColor.withOpacity(0.35))
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          height: 240,
          decoration: BoxDecoration(
            color: _fileName != null
                ? AppTheme.primaryColor.withOpacity(0.1)
                : Theme.of(context).cardColor.withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
            boxShadow: _fileName != null ? AppTheme.premiumShadow : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isProcessing)
                const SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(strokeWidth: 3))
              else ...[
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryColor.withOpacity(0.08),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.premiumShadow,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Icon(
                          _fileName == null
                              ? Iconsax.cloud_add
                              : Iconsax.document_text_1,
                          key: ValueKey(_fileName == null),
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  _fileName ?? 'Drag & drop or click to browse',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _fileName == null
                      ? 'Supports PDF, Word, PPTX'
                      : 'Document successfully loaded',
                  style: GoogleFonts.inter(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 13),
                ),
                if (_fileName == null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Iconsax.folder_add,
                            size: 16, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Browse Files',
                          style: GoogleFonts.inter(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileDetails(StateSetter setModalState) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border:
            Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_rose.withOpacity(0.14), _rose.withOpacity(0.04)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _rose.withOpacity(0.15)),
                ),
                child: const Icon(Iconsax.document_text_1,
                    color: _rose, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fileName!,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _pageCount != null
                          ? '$_pageCount pages • print-ready'
                          : 'Document • estimating price...',
                      style: GoogleFonts.inter(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Iconsax.trash,
                    color: _rose, size: 20),
                tooltip: 'Remove file',
                onPressed: () => setModalState(() {
                  _fileName = null;
                  _fileBytes = null;
                }),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1),
          ),
          _buildSummaryRow(
            'Price per page',
            _pageCount != null ? 'K 150.00' : 'K 150.00 (Flat)',
            icon: Iconsax.coin,
          ),
          const SizedBox(height: 12),
          if (_pageCount != null) ...[
            _buildSummaryRow('Total pages', '$_pageCount',
                icon: Iconsax.document_1),
            const SizedBox(height: 12),
          ],
          _buildSummaryRow('Estimated Total', _currencyFormat.format(_cost),
              isTotal: true, icon: Iconsax.wallet_2),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isTotal = false, IconData? icon}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 15,
                  color: isTotal
                      ? AppTheme.primaryColor
                      : Theme.of(context).textTheme.bodySmall?.color),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal
                    ? Theme.of(context).textTheme.bodyLarge?.color
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: isTotal ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: isTotal
                ? AppTheme.primaryColor
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildGradientButton(
          onPressed: (_isProcessing || _fileName == null)
              ? null
              : () => _submitJob(setModalState),
          icon: Iconsax.document_upload,
          label: _fileName == null ? 'Choose Document' : 'Submit Printing Job',
          size: const Size(double.infinity, 56),
          showSpinner: _isProcessing,
        ),
      ],
    );
  }
}

class _StepPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _StepPill({
    required this.icon,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? AppTheme.primaryColor.withOpacity(0.1)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active
              ? AppTheme.primaryColor.withOpacity(0.3)
              : Theme.of(context).dividerColor.withOpacity(0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14,
              color: active ? AppTheme.primaryColor : AppTheme.textMuted),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active ? AppTheme.primaryColor : AppTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.dashWidth = 8.0,
    this.dashSpace = 6.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(24),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashPath = Path();

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}