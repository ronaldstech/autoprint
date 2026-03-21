import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import '../../theme/app_theme.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  bool _isProcessing = false;
  String _processingMessage = "Processing...";

  // USER: Update this with your actual backend URL
  static const String _backendBaseUrl = "https://unimarket-mw.com/autoprint";

  @override
  void dispose() {
    _amountController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  String? _getNetwork(String mobile) {
    final cleanStr = mobile.replaceAll(RegExp(r'\D'), '');
    if (cleanStr.isEmpty) return null;

    if (cleanStr.startsWith('26599') ||
        cleanStr.startsWith('26598') ||
        cleanStr.startsWith('099') ||
        cleanStr.startsWith('098') ||
        cleanStr.startsWith('99') ||
        cleanStr.startsWith('98')) {
      return 'Airtel';
    } else if (cleanStr.startsWith('26588') ||
        cleanStr.startsWith('26589') ||
        cleanStr.startsWith('088') ||
        cleanStr.startsWith('089') ||
        cleanStr.startsWith('88') ||
        cleanStr.startsWith('89')) {
      return 'TNM';
    }
    return null;
  }

  void _showTopUpDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          final network = _getNetwork(_mobileController.text);

          Widget? suffixIcon;
          if (network == 'Airtel') {
            suffixIcon = Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Airtel',
                    style: GoogleFonts.inter(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          } else if (network == 'TNM') {
            suffixIcon = Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'TNM',
                    style: GoogleFonts.inter(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }

          return AlertDialog(
            title: Text('Top Up Account',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Enter amount to deposit (MWK):',
                    style: GoogleFonts.inter()),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'e.g. 500',
                    prefixText: 'K ',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Mobile Money Number:', style: GoogleFonts.inter()),
                const SizedBox(height: 12),
                TextField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  onChanged: (value) {
                    setModalState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: 'e.g. 0991234567',
                    prefixIcon: const Icon(LucideIcons.phone, size: 18),
                    suffixIcon: suffixIcon,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(_amountController.text);
                  if (amount != null && amount > 0) {
                    final network = _getNetwork(_mobileController.text);
                    if (network == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Please enter a valid Airtel or TNM number')),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    _startPaychanguPayment(amount, network);
                  }
                },
                child: const Text('Proceed to Payment'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _startPaychanguPayment(double amount, String network) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final mobile = _mobileController.text.trim();
      if (mobile.isEmpty) {
        throw Exception('Please enter your mobile number');
      }

      setState(() {
        _isProcessing = true;
        _processingMessage = "Fetching operators...";
      });

      // Fetch operators
      final operatorsUrl = Uri.parse('$_backendBaseUrl/get_operators.php');
      final operatorsResponse = await http.get(operatorsUrl);

      if (operatorsResponse.statusCode != 200) {
        throw Exception(
            'Failed to fetch operators (Status: ${operatorsResponse.statusCode})');
      }

      final operatorsData = jsonDecode(operatorsResponse.body);
      if (operatorsData['status'] != 'success') {
        throw Exception(
            'Failed to fetch operators: ${operatorsData['message']}');
      }

      final List<dynamic> operators = operatorsData['data'];
      String? operatorId;

      for (var op in operators) {
        final shortCode = (op['short_code'] as String).toLowerCase();
        if (network.toLowerCase() == shortCode) {
          operatorId = op['ref_id'];
          break;
        }
      }

      if (operatorId == null) {
        throw Exception('Could not find operator ID for $network');
      }

      setState(() {
        _processingMessage = "Initiating payment...";
      });

      // 1. Generate numeric txRef
      final randomStr = Random().nextInt(999).toString().padLeft(3, '0');
      final txRef = '${DateTime.now().millisecondsSinceEpoch}$randomStr';

      // 2. Save Pending Transaction Record
      await FirebaseFirestore.instance.collection('transactions').add({
        'userId': user.uid,
        'amount': amount,
        'type': 'deposit',
        'status': 'pending',
        'description': 'Top Up via Mobile Money',
        'timestamp': FieldValue.serverTimestamp(),
        'txRef': txRef,
        'mobile': mobile,
      });

      // 3. Initiate Payment via Backend
      final initUrl = Uri.parse('$_backendBaseUrl/initialize_payment.php');
      final body = jsonEncode({
        'amount': amount,
        'mobile': mobile,
        'txRef': txRef,
        'email': user.email ?? 'customer@example.com',
        'operator_id': operatorId,
      });

      print('--- Payment Initiation ---');
      print('URL: $initUrl');
      print('Payload: $body');

      final response = await http.post(
        initUrl,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
            'Failed to communicate with payment server (${response.statusCode})');
      }

      final initData = jsonDecode(response.body);
      if (initData['status'] != 'success') {
        throw Exception(initData['message'] ?? 'Payment initiation failed');
      }

      // 4. Payment Initiated Successfully
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment initiated. Please complete the transaction on your phone.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('!!! Payment Error: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), width: 340),
        );
      }
    }
  }

  Future<void> _updateTransactionError(String txRef, String error) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('txRef', isEqualTo: txRef)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({
          'lastError': error,
          'status': 'failed', // Mark as failed if there's an error
        });
      }
    } catch (e) {
      print('Failed to update transaction error: $e');
    }
  }

  Future<void> _verifyPendingTransaction(String txRef, double amount) async {
    try {
      setState(() {
        _isProcessing = true;
        _processingMessage = "Verifying transaction...";
      });

      final verifyUrl =
          Uri.parse('$_backendBaseUrl/verify_payment.php?txRef=$txRef');

      print('--- Manual Verification ---');
      print('URL: $verifyUrl');

      final verifyResponse = await http.get(verifyUrl);

      print('Verification Status: ${verifyResponse.statusCode}');
      print('Verification Body: ${verifyResponse.body}');

      if (verifyResponse.statusCode == 200) {
        final verifyData = jsonDecode(verifyResponse.body);
        if (verifyData['status'] == 'success') {
          await _handlePaymentSuccess(amount, txRef);
        } else {
          final errorMsg =
              verifyData['message'] ?? 'Payment verification failed';
          await _updateTransactionError(txRef, errorMsg);
          throw Exception(errorMsg);
        }
      } else {
        final errorMsg =
            'Failed to verify payment (${verifyResponse.statusCode})';
        await _updateTransactionError(txRef, errorMsg);
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('!!! Verification Error: $e');
      await _updateTransactionError(txRef, e.toString());
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e'), width: 340),
        );
      }
    }
  }

  Future<void> _handlePaymentSuccess(double amount, String txRef) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // 1. Update User Balance
      final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDoc);
        double currentBalance = 0;
        if (snapshot.exists) {
          currentBalance = (snapshot.data()?['balance'] ?? 0).toDouble();
        }
        transaction.set(userDoc, {'balance': currentBalance + amount},
            SetOptions(merge: true));
      });

      // 2. Update Transaction Status (Find the pending one)
      final txQuery = await FirebaseFirestore.instance
          .collection('transactions')
          .where('txRef', isEqualTo: txRef)
          .limit(1)
          .get();

      if (txQuery.docs.isNotEmpty) {
        await txQuery.docs.first.reference.update({'status': 'success'});
      }

      if (mounted) {
        setState(() => _isProcessing = false);
        _amountController.clear();
        _mobileController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Account successfully topped up!'), width: 340),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating balance: $e'), width: 340),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(symbol: 'K ', decimalDigits: 0);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
          body: Center(child: Text('Please log in to view transactions')));
    }

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
                _buildHeader(context, uid: user.uid),
                const SizedBox(height: 32),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    double balance = 0;
                    if (snapshot.hasData && snapshot.data!.exists) {
                      balance = (snapshot.data!.data()
                                  as Map<String, dynamic>?)?['balance']
                              ?.toDouble() ??
                          0.0;
                    }
                    return _buildBalanceCard(context, currencyFormat, balance);
                  },
                ),
                if (_isProcessing) ...[
                  const SizedBox(height: 24),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  Center(
                      child: Text(_processingMessage,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppTheme.textMuted))),
                ],
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Activity',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('transactions')
                      .where('userId', isEqualTo: user.uid)
                      .orderBy('timestamp', descending: true)
                      .limit(20)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                              'Error loading activity: ${snapshot.error}',
                              style:
                                  GoogleFonts.inter(color: Colors.redAccent)),
                        ),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyActivity(context);
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final tx = snapshot.data!.docs[index].data()
                            as Map<String, dynamic>;
                        final DateTime? timestamp =
                            (tx['timestamp'] as Timestamp?)?.toDate();
                        final String dateStr = timestamp != null
                            ? DateFormat('MMM dd, HH:mm').format(timestamp)
                            : 'Pending...';

                        return _buildTransactionItem(
                            context,
                            tx['description'] ?? 'Transaction',
                            dateStr,
                            (tx['amount'] ?? 0).toDouble(),
                            tx['type'] == 'deposit'
                                ? LucideIcons.arrowDownLeft
                                : LucideIcons.printer,
                            tx['type'] == 'deposit'
                                ? const Color(0xFF10B981)
                                : AppTheme.primaryColor,
                            currencyFormat,
                            tx['status'] ?? 'success',
                            tx['txRef'],
                            tx['lastError']);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyActivity(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(LucideIcons.activity,
                size: 48, color: AppTheme.textMuted.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('No recent activity found',
                style: GoogleFonts.inter(color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required String uid}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmall = constraints.maxWidth < 600;
        return Flex(
          direction: isSmall ? Axis.vertical : Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment:
              isSmall ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Printing Balance',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.headlineMedium?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your credits and top up your account',
                  style: GoogleFonts.inter(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 14),
                ),
              ],
            ),
            if (isSmall) const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .where('userId', isEqualTo: uid)
                  .where('type', isEqualTo: 'print')
                  .snapshots(),
              builder: (context, snapshot) {
                double spent = 0;
                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    spent +=
                        (doc.data() as Map<String, dynamic>)['amount']?.abs() ??
                            0;
                  }
                }
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.trendingDown,
                          size: 16, color: AppTheme.secondaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Total Spent: K ${NumberFormat('#,###').format(spent)}',
                        style: GoogleFonts.inter(
                          color: AppTheme.secondaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildBalanceCard(
      BuildContext context, NumberFormat format, double balance) {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF818CF8).withOpacity(0.4),
                      const Color(0xFF818CF8).withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available Credits',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                format.format(balance),
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.creditCard,
                                color: Colors.white, size: 24),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildCardAction(
                              context, LucideIcons.plus, 'Top Up Account',
                              onTap: _showTopUpDialog),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardAction(BuildContext context, IconData icon, String label,
      {required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    String title,
    String date,
    double amount,
    IconData icon,
    Color categoryColor,
    NumberFormat formatRow,
    String status,
    String? txRef,
    String? lastError,
  ) {
    final bool isPositive = amount >= 0;
    final color = Theme.of(context).brightness == Brightness.dark
        ? categoryColor.withOpacity(0.8)
        : categoryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: GoogleFonts.inter(
                      color: AppTheme.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : ''}${formatRow.format(amount)}',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: isPositive
                      ? const Color(0xFF10B981)
                      : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                status[0].toUpperCase() + status.substring(1),
                style: GoogleFonts.inter(
                  color: status == 'success'
                      ? const Color(0xFF10B981)
                      : (status == 'pending'
                          ? Colors.orange
                          : Colors.redAccent),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (lastError != null &&
                  (status == 'pending' || status == 'failed'))
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    lastError.replaceAll('Exception: ', '').trim(),
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(
                      color: Colors.redAccent.withOpacity(0.8),
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              if (status == 'pending' && title.contains('Top Up'))
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: SizedBox(
                    height: 28,
                    child: TextButton(
                      onPressed: txRef != null
                          ? () => _verifyPendingTransaction(txRef, amount)
                          : null,
                      style: TextButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'Verify',
                        style: GoogleFonts.inter(
                          color: AppTheme.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
