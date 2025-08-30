import 'package:flutter_test/flutter_test.dart';
import 'package:tang0/src/top0.dart';
import 'dart:convert';

// Mock AES-like encryption for testing (simplified example)
String mockAESEncrypt(String data, String nonce) {
  // Simple Caesar cipher with nonce offset for demo purposes
  final offset = nonce.hashCode % 26;
  final encrypted = data.codeUnits.map((c) {
    if (c >= 65 && c <= 90) {
      // A-Z
      return ((c - 65 + offset) % 26) + 65;
    } else if (c >= 97 && c <= 122) {
      // a-z
      return ((c - 97 + offset) % 26) + 97;
    }
    return c;
  }).toList();
  return String.fromCharCodes(encrypted);
}

String mockAESDecrypt(String encryptedData, String nonce) {
  // Reverse the Caesar cipher
  final offset = nonce.hashCode % 26;
  final decrypted = encryptedData.codeUnits.map((c) {
    if (c >= 65 && c <= 90) {
      // A-Z
      return ((c - 65 - offset + 26) % 26) + 65;
    } else if (c >= 97 && c <= 122) {
      // a-z
      return ((c - 97 - offset + 26) % 26) + 97;
    }
    return c;
  }).toList();
  return String.fromCharCodes(decrypted);
}

// Base64 encryption for testing
String base64Encrypt(String data, String nonce) {
  final combined = data + nonce.substring(0, 4); // Use part of nonce as salt
  return base64.encode(utf8.encode(combined));
}

String base64Decrypt(String encryptedData, String nonce) {
  final decoded = utf8.decode(base64.decode(encryptedData));
  final saltLength = nonce.substring(0, 4).length;
  return decoded.substring(0, decoded.length - saltLength);
}

void main() {
  group('Optional Security Functions', () {
    setUp(() {
      // Reset optional functions before each test
      optionalSecurityEncrypt = null;
      optionalSecurityDecrypt = null;
    });

    test(
      'should use XOR encryption by default when no optional functions provided',
      () {
        const command = 'test_cmd';
        const data = 'Hello World';
        const signToken = 'test_sign_token_123';
        const xorToken = 'test_xor_token_456';

        // Sign with default XOR
        final signedString = signWithTokens(command, data, signToken, xorToken);

        // Verify it can be decoded with XOR
        final verifiedData = verifyDataWithTokens(
          signedString,
          signToken,
          xorToken,
        );
        expect(verifiedData, equals(data));
      },
    );

    test('should use custom encryption/decryption functions when provided', () {
      const command = 'secure_cmd';
      const data = 'Secret Message';
      const signToken = 'test_sign_token_123';
      const xorToken = 'test_xor_token_456';

      // Set up custom encryption functions
      optionalSecurityEncrypt = mockAESEncrypt;
      optionalSecurityDecrypt = mockAESDecrypt;

      // Sign with custom encryption
      final signedString = signWithTokens(command, data, signToken, xorToken);

      // Verify it can be decoded with custom decryption
      final verifiedData = verifyDataWithTokens(
        signedString,
        signToken,
        xorToken,
      );
      expect(verifiedData, equals(data));
    });

    test(
      'should still use XOR for command verification with custom data encryption',
      () {
        const command = 'test_command';
        const data = 'Encrypted Data';
        const signToken = 'test_sign_token_123';
        const xorToken = 'test_xor_token_456';

        // Set up custom encryption for data only
        optionalSecurityEncrypt = mockAESEncrypt;
        optionalSecurityDecrypt = mockAESDecrypt;

        final signedString = signWithTokens(command, data, signToken, xorToken);

        // Command verification should still work (uses XOR)
        expect(
          verifyCommandWithTokens(signedString, command, xorToken),
          isTrue,
        );
        expect(
          verifyCommandWithTokens(signedString, 'wrong_cmd', xorToken),
          isFalse,
        );

        // Data verification should work with custom functions
        final verifiedData = verifyDataWithTokens(
          signedString,
          signToken,
          xorToken,
        );
        expect(verifiedData, equals(data));
      },
    );

    test('should work with Base64 encryption example', () {
      const command = 'b64_test';
      const data = 'Base64 Test Data with special chars: !@#\$%^&*()';
      const signToken = 'test_sign_token_123';
      const xorToken = 'test_xor_token_456';

      // Use Base64 encoding as encryption
      optionalSecurityEncrypt = base64Encrypt;
      optionalSecurityDecrypt = base64Decrypt;

      final signedString = signWithTokens(command, data, signToken, xorToken);
      final verifiedData = verifyDataWithTokens(
        signedString,
        signToken,
        xorToken,
      );

      expect(verifiedData, equals(data));
    });

    test('should handle different data lengths with custom encryption', () {
      const command = 'length_test';
      const signToken = 'test_sign_token_123';
      const xorToken = 'test_xor_token_456';

      optionalSecurityEncrypt = mockAESEncrypt;
      optionalSecurityDecrypt = mockAESDecrypt;

      final testCases = [
        '', // Empty string
        'A', // Single character
        'Short', // Short string
        'This is a much longer string with many characters to test encryption', // Long string
        'Special chars: àáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ', // Unicode
      ];

      for (final data in testCases) {
        final signedString = signWithTokens(command, data, signToken, xorToken);
        final verifiedData = verifyDataWithTokens(
          signedString,
          signToken,
          xorToken,
        );
        expect(verifiedData, equals(data), reason: 'Failed for data: "$data"');
      }
    });

    test('should fail verification if wrong decryption function is used', () {
      const command = 'mismatch_test';
      const data = 'Test Data';
      const signToken = 'test_sign_token_123';
      const xorToken = 'test_xor_token_456';

      // Encrypt with Caesar cipher
      optionalSecurityEncrypt = mockAESEncrypt;
      final signedString = signWithTokens(command, data, signToken, xorToken);

      // Try to decrypt with Caesar cipher but wrong logic (double offset)
      optionalSecurityDecrypt = (String encryptedData, String nonce) {
        final offset = (nonce.hashCode % 26) * 2; // Wrong offset
        final decrypted = encryptedData.codeUnits.map((c) {
          if (c >= 65 && c <= 90) {
            return ((c - 65 - offset + 26) % 26) + 65;
          } else if (c >= 97 && c <= 122) {
            return ((c - 97 - offset + 26) % 26) + 97;
          }
          return c;
        }).toList();
        return String.fromCharCodes(decrypted);
      };

      final verifiedData = verifyDataWithTokens(
        signedString,
        signToken,
        xorToken,
      );

      expect(verifiedData, isNull); // Should fail signature verification
    });

    test('should work with global sign/verify functions', () {
      const command = 'global_test';
      const data = 'Global Function Test';

      // Set up custom encryption
      optionalSecurityEncrypt = mockAESEncrypt;
      optionalSecurityDecrypt = mockAESDecrypt;

      // Use global functions (these use the cached tokens)
      final signedString = sign(command, data);
      final verifiedData = verifyData(signedString);

      expect(verifiedData, equals(data));
    });

    test('should handle command matching with custom data encryption', () {
      const commands = ['cmd1', 'cmd2', 'secure_command'];
      const data = 'Command Match Test';
      const signToken = 'test_sign_token_123';
      const xorToken = 'test_xor_token_456';

      optionalSecurityEncrypt = mockAESEncrypt;
      optionalSecurityDecrypt = mockAESDecrypt;

      for (final command in commands) {
        final signedString = signWithTokens(command, data, signToken, xorToken);

        // Test command matching
        final matchedCommand = matchCommandWithTokens(
          signedString,
          commands,
          xorToken,
        );
        expect(matchedCommand, equals(command));

        // Test data verification
        final verifiedData = verifyDataWithTokens(
          signedString,
          signToken,
          xorToken,
        );
        expect(verifiedData, equals(data));
      }
    });
  });

  group('Optional Security Edge Cases', () {
    setUp(() {
      optionalSecurityEncrypt = null;
      optionalSecurityDecrypt = null;
    });

    test('should handle null data gracefully', () {
      const command = 'null_test';
      const data = '';
      const signToken = 'test_sign_token_123';
      const xorToken = 'test_xor_token_456';

      optionalSecurityEncrypt = (String d, String n) =>
          d.isEmpty ? 'EMPTY' : mockAESEncrypt(d, n);
      optionalSecurityDecrypt = (String d, String n) =>
          d == 'EMPTY' ? '' : mockAESDecrypt(d, n);

      final signedString = signWithTokens(command, data, signToken, xorToken);
      final verifiedData = verifyDataWithTokens(
        signedString,
        signToken,
        xorToken,
      );

      expect(verifiedData, equals(data));
    });

    test('should reset to XOR when optional functions are set to null', () {
      const command = 'reset_test';
      const data = 'Reset Test Data';
      const signToken = 'test_sign_token_123';
      const xorToken = 'test_xor_token_456';

      // First, use custom encryption
      optionalSecurityEncrypt = mockAESEncrypt;
      optionalSecurityDecrypt = mockAESDecrypt;

      final customSignedString = signWithTokens(
        command,
        data,
        signToken,
        xorToken,
      );
      final customVerified = verifyDataWithTokens(
        customSignedString,
        signToken,
        xorToken,
      );
      expect(customVerified, equals(data));

      // Reset to null (back to XOR)
      optionalSecurityEncrypt = null;
      optionalSecurityDecrypt = null;

      final xorSignedString = signWithTokens(
        command,
        data,
        signToken,
        xorToken,
      );
      final xorVerified = verifyDataWithTokens(
        xorSignedString,
        signToken,
        xorToken,
      );
      expect(xorVerified, equals(data));

      // The two signed strings should be different
      expect(customSignedString, isNot(equals(xorSignedString)));
    });
  });
}
