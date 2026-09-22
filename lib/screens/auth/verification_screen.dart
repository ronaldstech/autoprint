import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../services/otp_service.dart';
import '../../theme/app_theme.dart';

class VerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const VerificationScreen({super.key, required this.phoneNumber});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  Timer? _resendTimer;
  int _resendCount = 0;
  int _resendSecondsRemaining = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startResendCooldown(30);
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  bool get _canResend =>
      !_isLoading && !_isResending && _resendSecondsRemaining == 0;

  void _startResendCooldown(int seconds) {
    _resendTimer?.cancel();
    setState(() => _resendSecondsRemaining = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSecondsRemaining <= 1) {
        timer.cancel();
        setState(() => _resendSecondsRemaining = 0);
      } else {
        setState(() => _resendSecondsRemaining--);
      }
    });
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      _showMessage('Enter the 6-digit code sent to your phone.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isLoading = true);
    try {
      final verified = await OtpService.verifyCode(uid: user.uid, code: code);
      if (!mounted) return;
      if (verified) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      } else {
        _showMessage('That code is invalid or has expired.');
      }
    } catch (_) {
      if (mounted) _showMessage('Could not verify the code. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isResending = true);
    try {
      await OtpService.sendCode(uid: user.uid, phoneNumber: widget.phoneNumber);
      if (mounted) {
        _resendCount++;
        final cooldown = (30 * (1 << _resendCount)).clamp(60, 900);
        _startResendCooldown(cooldown);
        _showMessage('A new verification code has been sent.');
      }
    } catch (_) {
      if (mounted) _showMessage('Could not send a new code. Please try again.');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), width: 360));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark ? const [Color(0xFF0B1020), Color(0xFF151D38)] : const [Color(0xFFF4F6FF), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  elevation: 0,
                  color: theme.cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          height: 76,
                          width: 76,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(24)),
                          child: const Icon(Iconsax.mobile, color: AppTheme.primaryColor, size: 34),
                        ),
                        const SizedBox(height: 28),
                        Text('Verify your phone', style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 10),
                        Text('We sent a 6-digit code to ${_maskedPhone(widget.phoneNumber)}. Enter it below to secure your account.', style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 28),
                        TextField(
                          controller: _codeController,
                          autofocus: true,
                          maxLength: 6,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(letterSpacing: 10, fontWeight: FontWeight.w700),
                          decoration: const InputDecoration(counterText: '', labelText: 'Verification code', prefixIcon: Icon(Iconsax.key_square)),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _isLoading ? null : _verify,
                          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          child: _isLoading ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Verify and continue'),
                        ),
                        const SizedBox(height: 22),
                        Center(
                          child: TextButton.icon(
                            onPressed: _canResend ? _resend : null,
                            icon: Icon(
                              _canResend ? Iconsax.refresh : Iconsax.clock,
                              size: 18,
                            ),
                            label: Text(_isResending
                                ? 'Sending...'
                                : _resendSecondsRemaining > 0
                                    ? 'Resend in ${_formatCooldown()}'
                                    : 'Resend code'),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Iconsax.shield_tick, size: 16, color: AppTheme.secondaryColor),
                          const SizedBox(width: 7),
                          Text('Your account stays protected', style: theme.textTheme.labelMedium),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _maskedPhone(String phone) {
    if (phone.length < 5) return phone;
    return '${phone.substring(0, 3)}${'*' * (phone.length - 5)}${phone.substring(phone.length - 2)}';
  }

  String _formatCooldown() {
    final minutes = _resendSecondsRemaining ~/ 60;
    final seconds = _resendSecondsRemaining % 60;
    return minutes > 0
        ? '$minutes:${seconds.toString().padLeft(2, '0')}'
        : '${seconds}s';
  }
}