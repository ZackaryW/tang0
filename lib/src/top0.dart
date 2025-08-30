import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Secure storage instance (only initialized if needed)
FlutterSecureStorage? _storage;

// Token storage keys
const String _signTokenKey = 'tang0_sign_token';
const String _xorTokenKey = 'tang0_xor_token';

// Fallback tokens for when secure storage is unavailable (less secure but functional)
const String _fallbackSignToken = 'tang0_fallback_sign_key_2025';
const String _fallbackXorToken = 'tang0_fallback_xor_key_2025';

// Cached tokens (will be loaded from secure storage or fallback)
String? _signToken;
String? _xorToken;
bool _isInitialized = false;

// Optional security functions for users who want true encryption beyond XOR for DATA only
// These functions handle data encryption/decryption, commands always use XOR
Function? optionalSecurityEncrypt; // (String data, String nonce) -> String
Function?
optionalSecurityDecrypt; // (String encryptedData, String nonce) -> String

/// Generates a random key using letters and numbers
String _generateRandomKey(int length) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
  final random = Random();
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ),
  );
}

/// Initialize tokens from secure storage
///
/// Attempts to load tokens from secure storage. If secure storage is unavailable
/// or fails, throws a StateError to alert the user of the security issue.
///
/// If this function is never called, Tang0 will automatically use predefined
/// fallback tokens (reduced security but maintained functionality).
///
/// Throws [StateError] if secure storage initialization fails.
Future<void> initializeTang0Tokens() async {
  _isInitialized = true;

  try {
    // Initialize secure storage only when needed
    _storage = const FlutterSecureStorage();

    _signToken = await _storage!.read(key: _signTokenKey);
    _xorToken = await _storage!.read(key: _xorTokenKey);

    // If tokens don't exist in secure storage, generate new ones and store them
    if (_signToken == null) {
      _signToken = _generateRandomKey(16);
      await _storage!.write(key: _signTokenKey, value: _signToken!);
    }

    if (_xorToken == null) {
      _xorToken = _generateRandomKey(16);
      await _storage!.write(key: _xorTokenKey, value: _xorToken!);
    }
  } catch (e) {
    // Throw error if secure storage fails during initialization
    // This ensures users are aware of security issues
    throw StateError(
      'Tang0: Failed to initialize secure storage. This may indicate '
      'browser security restrictions or storage issues. Error: $e',
    );
  }
}

/// Get the sign token (uses fallback if not initialized)
String _getSignToken() {
  if (!_isInitialized) {
    // Use fallback token if initializeTang0Tokens() was never called
    return _fallbackSignToken;
  }

  if (_signToken == null) {
    throw StateError(
      'Tang0 tokens failed to initialize. Check secure storage availability.',
    );
  }
  return _signToken!;
}

/// Get the XOR token (uses fallback if not initialized)
String _getXorToken() {
  if (!_isInitialized) {
    // Use fallback token if initializeTang0Tokens() was never called
    return _fallbackXorToken;
  }

  if (_xorToken == null) {
    throw StateError(
      'Tang0 tokens failed to initialize. Check secure storage availability.',
    );
  }
  return _xorToken!;
}

/// XOR two strings together
String _xorStrings(String str1, String str2) {
  final result = <int>[];

  for (int i = 0; i < str1.length; i++) {
    result.add(str1.codeUnitAt(i) ^ str2.codeUnitAt(i % str2.length));
  }

  return String.fromCharCodes(result);
}

/// Signs a string using HMAC-SHA256 with a nonce and XOR encoding
///
/// [command] - The command string (padded to 32 chars with "=")
/// [data] - The data string to sign
/// [signToken] - Token used for HMAC signing
/// [xorToken] - Token used for XOR encoding
///
/// Returns a concatenated string with the following format:
/// - Nonce: 19 characters (13 timestamp + 6 zero-padded random)
/// - Signature: 64 characters (HMAC-SHA256 hex string)
/// - XOR Command: 32 characters (command XORed with xorToken)
/// - XOR Data: variable length (data XORed with xorToken)
///
/// Total length: 115 + data.length characters
String signWithTokens(
  String command,
  String data,
  String signToken,
  String xorToken,
) {
  // Validate command length
  if (command.length > 32) {
    throw ArgumentError(
      'Command cannot exceed 32 characters. Got: ${command.length}',
    );
  }

  // Pad command to exactly 32 characters
  command = command.padRight(32, "=");

  // Generate a random nonce
  final nonce =
      DateTime.now().millisecondsSinceEpoch.toString() +
      Random().nextInt(1000000).toString().padLeft(6, '0');

  // Combine data with nonce
  final dataWithNonce = data + nonce;

  // Create HMAC-SHA256 signature using the sign token
  final key = utf8.encode(signToken);
  final bytes = utf8.encode(dataWithNonce);
  final hmacSha256 = Hmac(sha256, key);
  final digest = hmacSha256.convert(bytes);

  final xorcmd = _xorStrings(command, _xorStrings(xorToken, nonce));

  // Use optional encryption for data if provided, otherwise use XOR
  final xordata = optionalSecurityEncrypt != null
      ? optionalSecurityEncrypt!(data, nonce)
      : _xorStrings(data, _xorStrings(xorToken, nonce));

  return nonce + digest.toString() + xorcmd + xordata;
}

/// Signs a string using HMAC-SHA256 with a nonce and XOR encoding (using global tokens)
///
/// [command] - The command string (padded to 32 chars with "=")
/// [data] - The data string to sign
///
/// Uses the globally cached tokens from initializeTang0Tokens().
/// For testing, use signWithTokens() directly with test constants.
String sign(String command, String data) {
  return signWithTokens(command, data, _getSignToken(), _getXorToken());
}

/// Verifies the command portion of a signed string with provided tokens
///
/// [signedString] - The complete signed string returned by signWithTokens()
/// [expectedCommand] - The command to verify against
/// [xorToken] - Token used for XOR decoding
///
/// Returns true if the command matches
bool verifyCommandWithTokens(
  String signedString,
  String expectedCommand,
  String xorToken,
) {
  if (signedString.length < 115) return false;

  // Validate command length
  if (expectedCommand.length > 32) {
    throw ArgumentError(
      'Command cannot exceed 32 characters. Got: ${expectedCommand.length}',
    );
  }

  // Extract XOR command (characters 83-114)
  final xorCommand = signedString.substring(83, 115);

  // nonce extract
  final nonce = signedString.substring(0, 19);

  // Create expected XOR command - pad to 32 characters
  final paddedCommand = expectedCommand.padRight(32, "=");
  final expectedXorCommand = _xorStrings(
    paddedCommand,
    _xorStrings(xorToken, nonce),
  );

  return xorCommand == expectedXorCommand;
}

/// Verifies the command portion of a signed string (using global tokens)
///
/// [signedString] - The complete signed string returned by sign()
/// [expectedCommand] - The command to verify against
///
/// Uses globally cached tokens. For testing, use verifyCommandWithTokens().
bool verifyCommand(String signedString, String expectedCommand) {
  return verifyCommandWithTokens(signedString, expectedCommand, _getXorToken());
}

/// Matches the command portion of a signed string against a list with provided tokens
///
/// [signedString] - The complete signed string
/// [expectedCommands] - List of commands to match against
/// [xorToken] - Token used for XOR decoding
///
/// Returns the matched command string, or null if no match is found
String? matchCommandWithTokens(
  String signedString,
  List<String> expectedCommands,
  String xorToken,
) {
  if (signedString.length < 115) return null;

  // Validate command lengths
  for (var command in expectedCommands) {
    if (command.length > 32) {
      throw ArgumentError(
        'Command cannot exceed 32 characters. Got: ${command.length}',
      );
    }
  }

  // Extract XOR command (characters 83-114)
  final xorCommand = signedString.substring(83, 115);

  // Extract nonce
  final nonce = signedString.substring(0, 19);

  // Decrypt the command by XORing back with the same key
  final decryptedCommand = _xorStrings(
    xorCommand,
    _xorStrings(xorToken, nonce),
  );

  // Remove padding to get original command
  final originalCommand = decryptedCommand.replaceAll(RegExp(r'=+$'), '');

  // Check if the decrypted command matches any in the list
  for (var expectedCommand in expectedCommands) {
    if (originalCommand == expectedCommand) {
      return expectedCommand;
    }
  }

  return null; // No match found
}

/// Matches the command portion of a signed string against a list (using global tokens)
///
/// [signedString] - The complete signed string returned by sign()
/// [expectedCommands] - List of commands to match against
///
/// Uses globally cached tokens. For testing, use matchCommandWithTokens().
String? matchCommand(String signedString, List<String> expectedCommands) {
  return matchCommandWithTokens(signedString, expectedCommands, _getXorToken());
}

/// Extracts and returns the original data from a signed string with provided tokens
///
/// [signedString] - The complete signed string
/// [signToken] - Token used for HMAC verification
/// [xorToken] - Token used for XOR decoding
///
/// Returns the original data string, or null if verification fails
String? verifyDataWithTokens(
  String signedString,
  String signToken,
  String xorToken,
) {
  if (signedString.length < 115) return null;

  // Extract components
  final nonce = signedString.substring(0, 19);
  final signature = signedString.substring(19, 83);
  final xorData = signedString.substring(115);

  // Use optional decryption for data if provided, otherwise use XOR
  final originalData = optionalSecurityDecrypt != null
      ? optionalSecurityDecrypt!(xorData, nonce)
      : _xorStrings(xorData, _xorStrings(xorToken, nonce));

  // Verify the signature
  final dataWithNonce = originalData + nonce;
  final key = utf8.encode(signToken);
  final bytes = utf8.encode(dataWithNonce);
  final hmacSha256 = Hmac(sha256, key);
  final digest = hmacSha256.convert(bytes);

  if (digest.toString() != signature) {
    return null; // Signature verification failed
  }

  return originalData;
}

/// Extracts and returns the original data from a signed string (using global tokens)
///
/// [signedString] - The complete signed string returned by sign()
///
/// Uses globally cached tokens. For testing, use verifyDataWithTokens().
String? verifyData(String signedString) {
  return verifyDataWithTokens(signedString, _getSignToken(), _getXorToken());
}
