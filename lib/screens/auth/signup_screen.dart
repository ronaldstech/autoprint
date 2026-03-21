import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'google_sign_in_button.dart';
import '../../theme/app_theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _googleSignIn = GoogleSignIn();
  bool _isLoading = false;

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

  Future<void> _signUp() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) Navigator.pop(context);
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
    return Scaffold(
      body: Stack(
        children: [
          // --- Premium Background Gradient ---
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomRight,
                end: Alignment.topLeft,
                colors: [
                  AppTheme.primaryLight,
                  Colors.white,
                  AppTheme.primaryLight.withOpacity(0.5),
                ],
              ),
            ),
          ),

          // --- Decorative Blobs ---
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: IconButton.filledTonal(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 450),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // --- Logo Section ---
                            Hero(
                              tag: 'logo',
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: AppTheme.softShadow,
                                ),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  height: 50,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                    Icons.print_rounded,
                                    color: AppTheme.primaryColor,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // --- Main Card ---
                            Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                                side: const BorderSide(
                                    color: Colors.white, width: 2),
                              ),
                              color: Colors.white.withOpacity(0.8),
                              child: Padding(
                                padding: const EdgeInsets.all(40.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Create Account',
                                      style: Theme.of(context)
                                          .textTheme
                                          .displayLarge
                                          ?.copyWith(
                                            fontSize: 28,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Join AutoPrint today!',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 32),
                                    TextField(
                                      controller: _emailController,
                                      decoration: const InputDecoration(
                                        labelText: 'Email Address',
                                        prefixIcon: Icon(Icons.email_outlined),
                                        hintText: 'name@example.com',
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 20),
                                    TextField(
                                      controller: _passwordController,
                                      decoration: const InputDecoration(
                                        labelText: 'Password',
                                        prefixIcon:
                                            Icon(Icons.lock_outline_rounded),
                                      ),
                                      obscureText: true,
                                    ),
                                    const SizedBox(height: 20),
                                    TextField(
                                      controller: _confirmPasswordController,
                                      decoration: const InputDecoration(
                                        labelText: 'Confirm Password',
                                        prefixIcon:
                                            Icon(Icons.lock_reset_rounded),
                                      ),
                                      obscureText: true,
                                    ),
                                    const SizedBox(height: 32),
                                    ElevatedButton(
                                      onPressed: _isLoading ? null : _signUp,
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text('Sign Up'),
                                    ),
                                    const SizedBox(height: 24),
                                    const Row(
                                      children: [
                                        Expanded(child: Divider()),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child: Text('OR',
                                              style: TextStyle(
                                                  color: AppTheme.textMuted)),
                                        ),
                                        Expanded(child: Divider()),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    GoogleSignInButton(
                                      googleSignIn: _googleSignIn,
                                      onPressed:
                                          _isLoading ? null : _signUpWithGoogle,
                                      isLoading: _isLoading,
                                    ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
