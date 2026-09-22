import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class OtpService {
  static const _endpoint = 'https://telcomw.com/api-v2/send';
  static const _apiKey = 'yk43xA0oRLSmWMFrFKbR';
  static const _password = 'Lynx@9012';
  static const _senderName = 'KIOSK';
  static const _otpLifetime = Duration(minutes: 10);

  static Future<void> sendCode({
    required String uid,
    required String phoneNumber,
  }) async {
    final code = _generateCode();
    final request = http.MultipartRequest('POST', Uri.parse(_endpoint))
      ..fields.addAll({
        'api_key': _apiKey,
        'password': _password,
        'text': 'Your AutoPrint verification code is $code. It expires in 10 minutes.',
        'numbers': phoneNumber,
        'from': _senderName,
      });
    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('SMS provider rejected the request (${response.statusCode}).');
    }

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'phone': phoneNumber,
      'phoneVerified': false,
      'otpHash': _hash(code),
      'otpExpiresAt': Timestamp.fromDate(DateTime.now().add(_otpLifetime)),
      'otpAttempts': 0,
    }, SetOptions(merge: true));
  }

  static Future<bool> verifyCode({
    required String uid,
    required String code,
  }) async {
    final reference = FirebaseFirestore.instance.collection('users').doc(uid);
    final snapshot = await reference.get();
    final data = snapshot.data();
    if (data == null) return false;

    final expiresAt = (data['otpExpiresAt'] as Timestamp?)?.toDate();
    final isValid = expiresAt != null &&
        expiresAt.isAfter(DateTime.now()) &&
        data['otpHash'] == _hash(code.trim());
    if (!isValid) {
      await reference.set({
        'otpAttempts': FieldValue.increment(1),
      }, SetOptions(merge: true));
      return false;
    }

    await reference.set({
      'phoneVerified': true,
      'phoneVerifiedAt': FieldValue.serverTimestamp(),
      'otpHash': FieldValue.delete(),
      'otpExpiresAt': FieldValue.delete(),
      'otpAttempts': FieldValue.delete(),
    }, SetOptions(merge: true));
    return true;
  }

  static String _generateCode() =>
      (100000 + Random.secure().nextInt(900000)).toString();

  static String _hash(String code) =>
      sha256.convert(utf8.encode('$code:${FirebaseAuth.instance.currentUser?.uid}')).toString();
}