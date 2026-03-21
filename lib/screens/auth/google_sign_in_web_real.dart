import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';

Widget renderGoogleSignInButton({
  required GoogleSignIn googleSignIn,
}) {
  // Use the web-specific renderButton method from the GoogleSignInPlugin
  return (GoogleSignInPlatform.instance as GoogleSignInPlugin).renderButton();
}
