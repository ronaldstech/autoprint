import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:iconsax/iconsax.dart';
import 'google_sign_in_button.dart';
import 'verification_screen.dart';
import '../../theme/app_theme.dart';
import '../../services/otp_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _googleSignIn = GoogleSignIn();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged
        .listen((GoogleSignInAccount? account) async {
      if (account != null) {
        setState(() => _isLoading = true);
        try {
          final GoogleSignInAuthentication googleAuth =
              await account.authentication;
          final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          await FirebaseAuth.instance.signInWithCredential(credential);
        } catch (e) {
          if (mounted) _showError('Google Sign-In failed: $e');
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
      _phoneController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Update user's display name
      await userCredential.user?.updateDisplayName(_nameController.text.trim());
      final phoneNumber = _phoneController.text.trim();
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': phoneNumber,
        'phoneVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await OtpService.sendCode(
        uid: userCredential.user!.uid,
        phoneNumber: phoneNumber,
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VerificationScreen(phoneNumber: phoneNumber),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError(e.message ?? 'Sign Up failed');
    } catch (e) {
      if (mounted) _showError('An unexpected error occurred');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        width: 340,
      ),
    );
  }

  Future<void> _signUpWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await _googleSignIn.signIn();
    } catch (e) {
      if (mounted) _showError('Google Sign-Up failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 760;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF0B1020), Color(0xFF151D38)]
                : const [Color(0xFFF4F6FF), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: SelectionArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(isWide ? 48 : 20, 20, isWide ? 48 : 20, 36),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Iconsax.arrow_left_2),
                            tooltip: 'Back',
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Already have an account? Sign in'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _buildBrandHeader(theme),
                      const SizedBox(height: 30),
                      Card(
                        elevation: 0,
                        color: theme.cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                          side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(isWide ? 44 : 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Create your workspace', style: theme.textTheme.headlineMedium),
                              const SizedBox(height: 8),
                              Text('Set up your AutoPrint account and start managing every order in one place.', style: theme.textTheme.bodyMedium),
                              const SizedBox(height: 28),
                              if (isWide)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildIdentityFields(theme)),
                                    const SizedBox(width: 20),
                                    Expanded(child: _buildSecurityFields(theme)),
                                  ],
                                )
                              else ...[
                                _buildIdentityFields(theme),
                                const SizedBox(height: 16),
                                _buildSecurityFields(theme),
                              ],
                              const SizedBox(height: 28),
                              FilledButton(
                                onPressed: _isLoading ? null : _signUp,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(56),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                        Text('Create account'),
                                        SizedBox(width: 10),
                                        Icon(Iconsax.arrow_right_3, size: 18),
                                      ]),
                              ),
                              const SizedBox(height: 22),
                              Row(children: [
                                Expanded(child: Divider(color: theme.dividerColor)),
                                Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('OR CONTINUE WITH', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.8))),
                                Expanded(child: Divider(color: theme.dividerColor)),
                              ]),
                              const SizedBox(height: 18),
                              GoogleSignInButton(
                                googleSignIn: _googleSignIn,
                                onPressed: _isLoading ? null : _signUpWithGoogle,
                                isLoading: _isLoading,
                              ),
                              const SizedBox(height: 18),
                              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                const Icon(Iconsax.shield_tick, size: 16, color: AppTheme.secondaryColor),
                                const SizedBox(width: 7),
                                Text('Your information is encrypted and secure', style: theme.textTheme.labelMedium),
                              ]),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Hero(
          tag: 'logo',
          child: Container(
            height: 62,
            width: 62,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.premiumShadow,
            ),
            child: Image.asset('assets/images/logo.png', errorBuilder: (context, error, stackTrace) => const Icon(Iconsax.printer, color: AppTheme.primaryColor, size: 32)),
          ),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('AutoPrint', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          Text('Print smarter. Work faster.', style: theme.textTheme.bodySmall),
        ]),
      ],
    );
  }

  Widget _buildIdentityFields(ThemeData theme) {
    return Column(children: [
      _buildField(controller: _nameController, label: 'Full name', hint: 'Alex Morgan', icon: Iconsax.user, capitalization: TextCapitalization.words),
      const SizedBox(height: 16),
      _buildField(controller: _emailController, label: 'Work email', hint: 'alex@company.com', icon: Iconsax.sms, keyboardType: TextInputType.emailAddress),
      const SizedBox(height: 16),
      _buildField(controller: _phoneController, label: 'Phone number', hint: '+233 88 411 3450', icon: Iconsax.call, keyboardType: TextInputType.phone),
    ]);
  }

  Widget _buildSecurityFields(ThemeData theme) {
    return Column(children: [
      _buildField(controller: _passwordController, label: 'Password', hint: 'At least 6 characters', icon: Iconsax.lock_1, obscureText: !_showPassword, suffixIcon: IconButton(onPressed: () => setState(() => _showPassword = !_showPassword), icon: Icon(_showPassword ? Iconsax.eye_slash : Iconsax.eye), tooltip: _showPassword ? 'Hide password' : 'Show password')),
      const SizedBox(height: 16),
      _buildField(controller: _confirmPasswordController, label: 'Confirm password', hint: 'Repeat your password', icon: Iconsax.lock_1, obscureText: !_showConfirmPassword, suffixIcon: IconButton(onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword), icon: Icon(_showConfirmPassword ? Iconsax.eye_slash : Iconsax.eye), tooltip: _showConfirmPassword ? 'Hide password' : 'Show password')),
    ]);
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.none,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      obscureText: obscureText,
      decoration: InputDecoration(labelText: label, hintText: hint, prefixIcon: Icon(icon, size: 20), suffixIcon: suffixIcon),
    );
  }
}
