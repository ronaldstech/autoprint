import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  String? _fileName;
  int? _pageCount;
  double? _cost;
  bool _isProcessing = false;
  Uint8List? _fileBytes;

  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0);

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
        allowedExtensions: ['pdf'],
        withData: true, // Required for web to get bytes
      );

      if (result != null && result.files.single.bytes != null) {
        final bytes = result.files.single.bytes!;
        
        // Use syncfusion_flutter_pdf to count pages
        final PdfDocument document = PdfDocument(inputBytes: bytes);
        final int pages = document.pages.count;
        document.dispose();

        setState(() {
          _fileBytes = bytes;
          _fileName = result.files.single.name;
          _pageCount = pages;
          _cost = pages * 100.0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _submitJob() async {
    if (_fileBytes == null) return;

    setState(() => _isProcessing = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // 1. Upload file to Firebase Storage
      final String storagePath = 'documents/user_${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$_fileName';
      final ref = FirebaseStorage.instance.ref().child(storagePath);
      
      // Use putData for web compatibility
      await ref.putData(_fileBytes!);
      final String downloadUrl = await ref.getDownloadURL();
      
      // 2. Save metadata to Cloud Firestore
      await FirebaseFirestore.instance.collection('print_jobs').add({
        'user_id': user.uid,
        'file_name': _fileName,
        'file_url': downloadUrl,
        'page_count': _pageCount,
        'cost': _cost,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Print job submitted successfully!'), backgroundColor: Colors.green),
        );
        // Reset
        setState(() {
          _fileName = null;
          _pageCount = null;
          _cost = null;
          _fileBytes = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),
              _buildUploadCard(context),
              if (_fileName != null) ...[
                const SizedBox(height: 24),
                _buildFileDetailsCard(context),
              ],
              const SizedBox(height: 32),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'New Print Job',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 28,
                color: AppTheme.primaryColor,
              ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Upload your PDF and we\'ll handle the rest.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildUploadCard(BuildContext context) {
    return GestureDetector(
      onTap: _fileName == null ? _pickFile : null,
      child: Card(
        child: Container(
          width: double.infinity,
          height: 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: _fileName == null
                ? Border.all(color: AppTheme.primaryColor.withOpacity(0.2), width: 2)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _fileName == null ? LucideIcons.uploadCloud : LucideIcons.fileText,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _fileName ?? 'Click to browse files',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _fileName == null ? 'PDF files only • Max 50MB' : 'Document selected',
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileDetailsCard(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildDetailRow('Page Count', '$_pageCount pages', LucideIcons.layers),
            const Divider(height: 32),
            _buildDetailRow('Estimated Cost', _currencyFormat.format(_cost), LucideIcons.creditCard),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF64748B)),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Color(0xFF64748B))),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (_isProcessing) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _fileName == null ? _pickFile : _submitJob,
          icon: Icon(_fileName == null ? LucideIcons.plus : LucideIcons.printer),
          label: Text(_fileName == null ? 'Select Document' : 'Submit Job'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            backgroundColor: AppTheme.primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        if (_fileName != null) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: _pickFile,
            child: const Text('Cancel & Select Different File', style: TextStyle(color: Colors.red)),
          ),
        ],
      ],
    );
  }

  Widget _buildFilePreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
                  child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fileName!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${_pageCount} pages',
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(),
            ),
            _buildInfoRow('Price per page', 'UGX 100'),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Total Printing Cost',
              _currencyFormat.format(_cost),
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? const Color(0xFF1E293B) : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: isTotal ? const Color(0xFF0D47A1) : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
