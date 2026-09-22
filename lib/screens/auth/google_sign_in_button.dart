import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'google_sign_in_web_stub.dart'
    if (dart.library.js_util) 'google_sign_in_web_real.dart'
    if (dart.library.html) 'google_sign_in_web_real.dart';

class GoogleSignInButton extends StatelessWidget {
  final GoogleSignIn googleSignIn;
  final VoidCallback? onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    required this.googleSignIn,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: SizedBox(
            height: 44,
            child: renderGoogleSignInButton(googleSignIn: googleSignIn),
          ),
        ),
      );
    }

    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Theme.of(context).cardColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/google_g.svg',
            height: 21,
            width: 21,
          ),
          const SizedBox(width: 12),
          Text(
            'Continue with Google',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
