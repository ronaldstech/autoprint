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
      appBar: AppBar(title: const Text('New Print Job')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_fileName == null) ...[
                  const Icon(Icons.picture_as_pdf, size: 80, color: Colors.blueGrey),
                  const SizedBox(height: 24),
                  const Text(
                    'Select a PDF to Print',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Text('Rate: 100 per page', style: TextStyle(color: Colors.grey)),
                ] else ...[
                  const Icon(Icons.check_circle, size: 80, color: Colors.green),
                  const SizedBox(height: 24),
                  Text(
                    _fileName!,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildInfoRow('Number of Pages', '$_pageCount'),
                          const Divider(),
                          _buildInfoRow('Total Cost', _currencyFormat.format(_cost)),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
                if (_isProcessing)
                  const CircularProgressIndicator()
                else ...[
                  ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.file_upload),
                    label: Text(_fileName == null ? 'Select PDF' : 'Change PDF'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 50),
                    ),
                  ),
                  if (_fileName != null) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submitJob,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(200, 50),
                      ),
                      child: const Text('Confirm & Print'),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
