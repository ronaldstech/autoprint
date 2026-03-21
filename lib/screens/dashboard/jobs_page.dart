import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
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
        final String token = (Random().nextInt(8999999) + 1000000).toString();
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
      if (mounted) setState(() => _isProcessing = false);
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('New Printing Job',
                            style: GoogleFonts.outfit(
                                fontSize: 24, fontWeight: FontWeight.bold)),
                        IconButton(
                            icon: const Icon(LucideIcons.x),
                            onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildUploadArea(setModalState),
                    if (_fileName != null) ...[
                      const SizedBox(height: 24),
                      Text('Job Name',
                          style: GoogleFonts.outfit(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _jobNameController,
                        onChanged: (val) => setModalState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Enter a name for this job',
                          prefixIcon: const Icon(LucideIcons.type),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('File Summary',
                          style: GoogleFonts.outfit(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      _buildFileDetails(setModalState),
                    ],
                    const SizedBox(height: 32),
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
          icon: const Icon(LucideIcons.plus),
          label: const Text('New Job'),
          backgroundColor: AppTheme.primaryColor,
          elevation: 4,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: _buildHeader(),
              ),
              Expanded(
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
                    if (snapshot.hasError)
                      return Center(child: Text('Error: ${snapshot.error}'));
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return const Center(child: CircularProgressIndicator());

                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) return _buildEmptyState();

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        return _buildJobCard(data, docs[index].id);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _selectedStatus == 'All'
                    ? LucideIcons.printer
                    : LucideIcons.searchX,
                size: 80,
                color: AppTheme.primaryColor.withOpacity(0.2),
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
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(LucideIcons.plus, size: 20),
                label: const Text('Create New Job'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 56),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> data, String jobId) {
    final String status = data['status'] ?? 'pending';
    final String printStatus = data['print_status'] ?? status;
    final String paymentStatus = data['payment_status'] ?? 'pending';
    final String jobName = data['job_name'] ?? 'Untitled Job';
    final DateTime createdAt =
        (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();

    final bool isProcessing = printStatus == 'processing';

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
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            if (isProcessing)
              const LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.transparent,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _getStatusColor(printStatus).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _getFileIcon(data['file_name'] ?? ''),
                          color: _getStatusColor(printStatus),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              jobName,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${data['file_name'] ?? 'Unknown File'} • ${DateFormat('MMM dd, HH:mm').format(createdAt)}',
                              style: GoogleFonts.inter(
                                color: AppTheme.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _currencyFormat.format(data['cost'] ?? 0),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
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
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildEnhancedStatusBadge(
                        'Print: ${printStatus.toUpperCase()}',
                        _getStatusColor(printStatus),
                        _getStatusIcon(printStatus),
                      ),
                      const SizedBox(width: 8),
                      _buildEnhancedStatusBadge(
                        'Payment: ${paymentStatus.toUpperCase()}',
                        _getPaymentStatusColor(paymentStatus),
                        _getPaymentStatusIcon(paymentStatus),
                      ),
                      const Spacer(),
                      if (data['print_token'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            'Token: ${data['print_token']}',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      if (paymentStatus != 'success' && paymentStatus != 'paid')
                        ElevatedButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () => _handlePayment(
                                  jobId, (data['cost'] as num).toDouble()),
                          icon: _isProcessing
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(LucideIcons.creditCard, size: 14),
                          label: const Text('Pay Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                            textStyle: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold, fontSize: 13),
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

  IconData _getFileIcon(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    switch (ext) {
      case 'pdf':
        return LucideIcons.fileText;
      case 'doc':
      case 'docx':
        return LucideIcons.fileEdit;
      case 'pptx':
        return LucideIcons.presentation;
      default:
        return LucideIcons.file;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return LucideIcons.checkCircle2;
      case 'pending':
        return LucideIcons.clock;
      case 'processing':
        return LucideIcons.refreshCw;
      default:
        return LucideIcons.helpCircle;
    }
  }

  IconData _getPaymentStatusIcon(String status) {
    switch (status) {
      case 'success':
      case 'paid':
        return LucideIcons.shieldCheck;
      case 'pending':
        return LucideIcons.alertCircle;
      case 'failed':
        return LucideIcons.xCircle;
      default:
        return LucideIcons.creditCard;
    }
  }

  Widget _buildEnhancedStatusBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'success':
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Jobs',
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.headlineMedium?.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Track and manage your existing printing jobs.',
          style: GoogleFonts.inter(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 15),
        ),
        const SizedBox(height: 24),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _statuses.map((status) {
              final isSelected = _selectedStatus == status;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(status),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedStatus = status);
                    }
                  },
                  backgroundColor: Theme.of(context).cardColor,
                  selectedColor: AppTheme.primaryColor,
                  labelStyle: GoogleFonts.inter(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Theme.of(context).dividerColor.withOpacity(0.1),
                    ),
                  ),
                  showCheckmark: false,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadArea(StateSetter setModalState) {
    return GestureDetector(
      onTap: !_isProcessing ? () => _pickFileInModal(setModalState) : null,
      child: CustomPaint(
        painter: _fileName == null
            ? DashedBorderPainter(color: AppTheme.primaryColor.withOpacity(0.3))
            : null,
        child: Container(
          width: double.infinity,
          height: 240,
          decoration: BoxDecoration(
            color: _fileName != null
                ? AppTheme.primaryColor.withOpacity(0.1)
                : Theme.of(context).cardColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isProcessing)
                const CircularProgressIndicator()
              else ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _fileName == null
                        ? LucideIcons.uploadCloud
                        : LucideIcons.fileCheck,
                    size: 48,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _fileName ?? 'Drag & drop or Click to browse',
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
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.fileText,
                    color: Colors.red, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fileName!,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _pageCount != null
                          ? '$_pageCount Pages • Document'
                          : 'Document • Estimating price...',
                      style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.xCircle,
                    color: Colors.red, size: 20),
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
          _buildSummaryRow('Base Price',
              _pageCount != null ? 'K 150.00 / pg' : 'K 150.00 (Flat)'),
          const SizedBox(height: 12),
          _buildSummaryRow('Estimated Total', _currencyFormat.format(_cost),
              isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
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
        ElevatedButton(
          onPressed: (_isProcessing || _fileName == null)
              ? null
              : () => _submitJob(setModalState),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppTheme.primaryColor,
            disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.3),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isProcessing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _fileName == null ? 'Choose Document' : 'Submit Printing Job',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
        ),
      ],
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
      const Radius.circular(AppTheme.borderRadius),
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
