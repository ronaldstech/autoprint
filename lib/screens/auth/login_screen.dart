import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:iconsax/iconsax.dart';
import 'signup_screen.dart';
import 'google_sign_in_button.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _googleSignIn = GoogleSignIn();
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Firebase Sign-In failed: $e'),
                width: 340,
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    });
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          width: 340,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showError(e.message ?? 'Auth failed');
      }
    } catch (e) {
      if (mounted) {
        _showError('An unexpected error occurred');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Please enter your email to reset your password');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent! Check your inbox.'),
            backgroundColor: Colors.green,
            width: 340,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError(e.message ?? 'Reset failed');
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

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      if (mounted) {
        _showError('Google Sign-In failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.sizeOf(context).width >= 820;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF0B1020), Color(0xFF151D38)]
                : const [Color(0xFFF4F6FF), Colors.white],
          ),
        ),
        child: SafeArea(
          child: SelectionArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isWide ? 48 : 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: _buildWelcomePanel(theme)),
                            const SizedBox(width: 56),
                            Expanded(child: _buildLoginCard(theme)),
                          ],
                        )
                      : _buildLoginCard(theme),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomePanel(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBrandMark(),
          const SizedBox(height: 42),
          Text('Your print business,\nbeautifully organized.', style: theme.textTheme.displayMedium?.copyWith(fontSize: 42, height: 1.08)),
          const SizedBox(height: 18),
          Text('Manage jobs, payments, and customers from one calm, powerful workspace built for getting work done.', style: theme.textTheme.bodyLarge?.copyWith(height: 1.6)),
          const SizedBox(height: 30),
          _buildBenefit(Iconsax.flash_1, 'Move from quote to print faster'),
          _buildBenefit(Iconsax.chart_2, 'See your business clearly at a glance'),
          _buildBenefit(Iconsax.shield_tick, 'Keep every customer detail protected'),
        ],
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 18, color: AppTheme.primaryColor)),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildBrandMark() {
    return Row(children: [
      Hero(
        tag: 'logo',
        child: Container(
          height: 60,
          width: 60,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(20), boxShadow: AppTheme.premiumShadow),
          child: Image.asset('assets/images/logo.png', errorBuilder: (context, error, stackTrace) => const Icon(Iconsax.printer, color: AppTheme.primaryColor, size: 32)),
        ),
      ),
      const SizedBox(width: 14),
      const Text('AutoPrint', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
    ]);
  }

  Widget _buildLoginCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (MediaQuery.sizeOf(context).width < 820) ...[
            Center(child: _buildBrandMark()),
            const SizedBox(height: 28),
          ],
          Text('Welcome back', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Sign in to continue to your AutoPrint workspace.', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 28),
          TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email address', hintText: 'name@example.com', prefixIcon: Icon(Iconsax.sms, size: 20))),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: !_showPassword,
            decoration: InputDecoration(labelText: 'Password', hintText: 'Enter your password', prefixIcon: const Icon(Iconsax.lock_1, size: 20), suffixIcon: IconButton(onPressed: () => setState(() => _showPassword = !_showPassword), icon: Icon(_showPassword ? Iconsax.eye_slash : Iconsax.eye), tooltip: _showPassword ? 'Hide password' : 'Show password')),
          ),
          Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _isLoading ? null : _resetPassword, child: const Text('Forgot password?'))),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _isLoading ? null : _signIn,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: _isLoading ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Sign in'), SizedBox(width: 10), Icon(Iconsax.arrow_right_3, size: 18)]),
          ),
          const SizedBox(height: 22),
          Row(children: [Expanded(child: Divider(color: theme.dividerColor)), Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('OR CONTINUE WITH', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.8))), Expanded(child: Divider(color: theme.dividerColor))]),
          const SizedBox(height: 18),
          GoogleSignInButton(googleSignIn: _googleSignIn, onPressed: _isLoading ? null : _signInWithGoogle, isLoading: _isLoading),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('New to AutoPrint?', style: theme.textTheme.bodyMedium), TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen())), child: const Text('Create account'))]),
        ]),
      ),
    );
  }
}
