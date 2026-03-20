import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  File? _selectedFile;

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
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        
        // Use syncfusion_flutter_pdf to count pages
        final PdfDocument document = PdfDocument(inputBytes: bytes);
        final int pages = document.pages.count;
        document.dispose();

        setState(() {
          _selectedFile = file;
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
    if (_selectedFile == null) return;

    setState(() => _isProcessing = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // 1. Upload file to Firebase Storage
      final String storagePath = 'documents/user_${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$_fileName';
      final ref = FirebaseStorage.instance.ref().child(storagePath);
      await ref.putFile(_selectedFile!);
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
          _selectedFile = null;
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
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Upload Document',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 28,
                    color: const Color(0xFF0D47A1),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a PDF file to calculate printing costs.',
                  style: TextStyle(color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 32),
                if (_fileName == null)
                  _buildUploadArea()
                else
                  _buildFilePreview(),
                const SizedBox(height: 32),
                if (_isProcessing)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton.icon(
                    onPressed: _fileName == null ? _pickFile : _submitJob,
                    icon: Icon(_fileName == null ? Icons.upload_file : Icons.print_rounded),
                    label: Text(_fileName == null ? 'Select PDF' : 'Confirm & Print'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: _fileName == null 
                          ? Theme.of(context).colorScheme.primary 
                          : Colors.green.shade700,
                    ),
                  ),
                if (_fileName != null && !_isProcessing)
                  TextButton(
                    onPressed: _pickFile,
                    child: const Text('Change Document'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadArea() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 2,
            style: BorderStyle.solid, // Dash effect not built-in, using solid for now
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_upload_outlined,
                size: 48,
                color: Color(0xFF0D47A1),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Click to browse files',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'PDF files only • Max 50MB',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
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
