// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
// This import becomes valid AFTER you run: dart run secure_localizations
import 'package:secure_localizations_example/utils/secure_encryption_helper.dart';

void main() {
  group('Secure Localizations Logic Tests', () {
    // The key from your example/pubspec.yaml
    const int testKey = 72929798;
    const int byteKey = testKey & 0xFF;

    test('Full Cycle: Manual Encryption vs Helper Decryption', () {
      const String originalText = "Welcome to Tmcell, Dowran!";

      // 1. Simulate the Tool's Encryption logic (what happens to ARB)
      final List<int> utf8Bytes = utf8.encode(originalText);
      final List<int> xorBytes = utf8Bytes.map((int b) => b ^ byteKey).toList();
      final String base64Encrypted =
          base64.encode(Uint8List.fromList(xorBytes));

      print("Original: $originalText");
      print("Encrypted (Base64): $base64Encrypted");

      // 2. Use the ACTUAL generated helper to decode
      final String decrypted = SecureEncryption.decode(base64Encrypted);

      // 3. Assert they match
      expect(decrypted, originalText,
          reason: "The decrypted string must match the original plain text.");
    });

    test('Edge Case: Empty String', () {
      final String encryptedEmpty = base64.encode(Uint8List.fromList(<int>[]));
      expect(SecureEncryption.decode(encryptedEmpty), "");
    });

    test('Fallback Case: Non-encrypted string', () {
      // If a string isn't base64 or isn't our format, the helper should return it as-is
      // without crashing the app.
      const String plainText = "Normal String";
      expect(SecureEncryption.decode(plainText), plainText);
    });
  });
}
