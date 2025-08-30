import 'package:flutter_test/flutter_test.dart';
import 'package:tang0/src/top0.dart';

void main() {

  group('HMAC Signing and Verification Tests', () {
    test('Basic sign and verify flow', () {
      const command = 'hello';
      const data = 'world';

      // Sign the data using test tokens
      final signedString = sign(command, data);

      // Verify the signed string has correct length
      expect(signedString.length, equals(115 + data.length));

      // Verify command
      final isValidCommand = verifyCommand(signedString, command);
      expect(isValidCommand, isTrue);

      // Verify and extract data
      final extractedData = verifyData(signedString);
      expect(extractedData, equals(data));
    });

    test('Command verification with different commands', () {
      const command = 'test_command';
      const data = 'test_data';

      final signedString = sign(command, data);

      // Correct command should pass
      expect(verifyCommand(signedString, command), isTrue);

      // Wrong command should fail
      expect(verifyCommand(signedString, 'wrong_command'), isFalse);
      expect(verifyCommand(signedString, 'test_comman'), isFalse);
      expect(verifyCommand(signedString, ''), isFalse);
    });

    test('Command matching with list of expected commands', () {
      const command = 'hello_world';
      const data = 'test_data';

      final signedString = sign(command, data);

      // Should match the correct command from list
      final matchedCommand = matchCommand(signedString, [
        'hello_world',
        'goodbye',
        'test',
      ]);
      expect(matchedCommand, equals('hello_world'));

      // Should return null when no match
      final noMatch = matchCommand(signedString, [
        'goodbye',
        'test',
        'other',
      ]);
      expect(noMatch, isNull);

      // Should work with single item list
      final singleMatch = matchCommand(signedString, ['hello_world']);
      expect(singleMatch, equals('hello_world'));

      // Should return null for empty list
      final emptyMatch = matchCommand(signedString, []);
      expect(emptyMatch, isNull);

      // Should handle commands with different lengths
      final mixedLengths = matchCommand(signedString, [
        'hi',
        'hello_world',
        'very_long_command_name',
      ]);
      expect(mixedLengths, equals('hello_world'));
    });

    test('Command matching edge cases', () {
      // Test with maximum length command
      const maxCommand = '12345678901234567890123456789012'; // 32 chars
      final maxSigned = sign(maxCommand, 'data');
      final maxMatch = matchCommand(maxSigned, [maxCommand, 'short']);
      expect(maxMatch, equals(maxCommand));

      // Test with single character command
      const singleChar = 'x';
      final singleSigned = sign(singleChar, 'data');
      final singleMatch = matchCommand(singleSigned, ['a', 'x', 'z']);
      expect(singleMatch, equals('x'));

      // Test invalid signed string
      expect(matchCommand('invalid', ['test']), isNull);

      // Test with command too long in list
      expect(
        () => matchCommand(maxSigned, [
          'valid',
          'this_command_is_way_too_long_and_exceeds_32_characters',
        ]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Comparison: verifyCommand vs matchCommand behavior', () {
      const command = 'secure_cmd';
      const data = 'payload_data';

      final signedString = sign(command, data);

      // verifyCommand: requires exact command knowledge
      expect(verifyCommand(signedString, 'secure_cmd'), isTrue);
      expect(verifyCommand(signedString, 'wrong_cmd'), isFalse);

      // matchCommand: discovers command from list without prior knowledge
      expect(
        matchCommand(signedString, ['auth', 'secure_cmd', 'sync']),
        equals('secure_cmd'),
      );
      expect(
        matchCommand(signedString, ['auth', 'wrong_cmd', 'sync']),
        isNull,
      );

      // matchCommand is useful when you don't know the exact command
      // but want to check if it's one of several expected commands
      final commandList = [
        'login',
        'logout',
        'refresh',
        'secure_cmd',
        'update',
      ];
      final discoveredCommand = matchCommand(signedString, commandList);
      expect(discoveredCommand, equals('secure_cmd'));

      // You can then use the discovered command for routing/filtering
      expect(discoveredCommand, isNotNull);
      expect(commandList.contains(discoveredCommand), isTrue);
    });

    test('Data verification and extraction', () {
      const command = 'getData';
      const testData = 'This is some test data with special chars: !@#\$%^&*()';

      final signedString = sign(command, testData);

      // Should extract correct data
      final extractedData = verifyData(signedString);
      expect(extractedData, equals(testData));
      expect(extractedData, isNotNull);
    });

    test('Empty and edge case data', () {
      // Empty data
      final emptyDataSigned = sign('cmd', '');
      expect(verifyCommand(emptyDataSigned, 'cmd'), isTrue);
      expect(verifyData(emptyDataSigned), equals(''));

      // Single character data
      final singleCharSigned = sign('x', 'a');
      expect(verifyCommand(singleCharSigned, 'x'), isTrue);
      expect(verifyData(singleCharSigned), equals('a'));

      // Long command (should throw exception)
      const longCommand =
          'this_is_a_very_long_command_that_exceeds_32_characters';
      expect(
        () => sign(longCommand, 'data'),
        throwsA(isA<ArgumentError>()),
      );

      // Also test verifyCommand with long command (need valid signed string)
      final validSigned = sign('test', 'data');
      expect(
        () => verifyCommand(validSigned, longCommand),
        throwsA(isA<ArgumentError>()),
      );

      // Test maximum valid command length (exactly 32 chars)
      const maxCommand = '12345678901234567890123456789012'; // 32 chars
      final maxCmdSigned = sign(maxCommand, 'data');
      expect(verifyCommand(maxCmdSigned, maxCommand), isTrue);
      expect(verifyData(maxCmdSigned), equals('data'));
    });

    test('Large data handling', () {
      const command = 'bigData';
      final largeData = 'x' * 1000; // 1000 character string

      final signedString = sign(command, largeData);

      expect(signedString.length, equals(115 + largeData.length));
      expect(verifyCommand(signedString, command), isTrue);
      expect(verifyData(signedString), equals(largeData));
    });

    test('Invalid signed string handling', () {
      // Too short string
      expect(verifyCommand('short', 'any'), isFalse);
      expect(verifyData('short'), isNull);

      // Exactly 114 chars (just under minimum)
      final tooShort = 'a' * 114;
      expect(verifyCommand(tooShort, 'any'), isFalse);
      expect(verifyData(tooShort), isNull);

      // Minimum valid length (115 chars)
      final validSigned = sign('test', '');
      expect(validSigned.length, equals(115));
      expect(verifyCommand(validSigned, 'test'), isTrue);
    });

    test('Tampered data detection', () {
      const command = 'secure';
      const data = 'important_data';

      final signedString = sign(command, data);

      // Tamper with different parts of the signed string
      final tamperedNonce = 'X${signedString.substring(1)}';
      final tamperedSignature =
          '${signedString.substring(0, 19)}X${signedString.substring(20)}';
      final tamperedCommand =
          '${signedString.substring(0, 83)}X${signedString.substring(84)}';
      final tamperedData =
          '${signedString.substring(0, 115)}X${signedString.substring(116)}';

      // All tampered versions should fail verification
      expect(verifyData(tamperedNonce), isNull);
      expect(verifyData(tamperedSignature), isNull);
      expect(verifyCommand(tamperedCommand, command), isFalse);
      expect(verifyData(tamperedData), isNull);
    });

    test('Multiple signing produces different results', () {
      const command = 'test';
      const data = 'data';

      final signed1 = sign(command, data);
      final signed2 = sign(command, data);

      // Different signatures due to different nonces
      expect(signed1, isNot(equals(signed2)));

      // But both should verify correctly
      expect(verifyCommand(signed1, command), isTrue);
      expect(verifyCommand(signed2, command), isTrue);
      expect(verifyData(signed1), equals(data));
      expect(verifyData(signed2), equals(data));

      // Nonces should be different
      final nonce1 = signed1.substring(0, 19);
      final nonce2 = signed2.substring(0, 19);
      expect(nonce1, isNot(equals(nonce2)));
    });

    test('Unicode and special character handling', () {
      const command = 'unicode_test';
      const unicodeData = 'Hello 世界! 🌟 émojis and spéciål chars: ñáéíóú';

      final signedString = sign(command, unicodeData);

      expect(verifyCommand(signedString, command), isTrue);
      expect(verifyData(signedString), equals(unicodeData));
    });

    test('Signed string format validation', () {
      const command = 'format_test';
      const data = 'test_data_123';

      final signedString = sign(command, data);

      // Check format: nonce(19) + signature(64) + xor_cmd(32) + xor_data(variable)
      expect(signedString.length, equals(115 + data.length));

      // Extract each part and verify lengths
      final nonce = signedString.substring(0, 19);
      final signature = signedString.substring(19, 83);
      final xorCommand = signedString.substring(83, 115);
      final xorData = signedString.substring(115);

      expect(nonce.length, equals(19));
      expect(signature.length, equals(64));
      expect(xorCommand.length, equals(32));
      expect(xorData.length, equals(data.length));

      // Nonce should be all digits
      expect(RegExp(r'^\d+$').hasMatch(nonce), isTrue);

      // Signature should be hex
      expect(RegExp(r'^[a-f0-9]+$').hasMatch(signature), isTrue);
    });
  });

  group('Different Data Types Tests', () {
    test('JSON data handling', () {
      const command = 'json_data';
      const jsonData = '''
{
  "user": {
    "id": 12345,
    "name": "John Doe",
    "email": "john.doe@example.com",
    "preferences": {
      "theme": "dark",
      "notifications": true,
      "languages": ["en", "es", "fr"]
    }
  },
  "metadata": {
    "created": "2025-08-29T10:30:00Z",
    "version": "1.2.3",
    "tags": null
  }
}''';

      final signed = sign(command, jsonData);
      expect(verifyCommand(signed, command), isTrue);

      final extractedData = verifyData(signed);
      expect(extractedData, equals(jsonData));
      expect(extractedData, contains('"user"'));
      expect(extractedData, contains('"preferences"'));
    });

    test('Environment variables data', () {
      const command = 'env_vars';
      const envData = '''PATH=/usr/local/bin:/usr/bin:/bin
HOME=/home/user
USER=john_doe
SHELL=/bin/bash
LANG=en_US.UTF-8
NODE_ENV=production
DATABASE_URL=postgresql://user:pass@localhost:5432/mydb
API_KEY=abc123def456ghi789
SECRET_TOKEN=super_secret_key_here
DEBUG=false
PORT=3000''';

      final signed = sign(command, envData);
      expect(verifyCommand(signed, command), isTrue);

      final extractedData = verifyData(signed);
      expect(extractedData, equals(envData));
      expect(extractedData, contains('DATABASE_URL='));
      expect(extractedData, contains('API_KEY='));
    });

    test('Base64 encoded data', () {
      const command = 'base64_data';
      const base64Data =
          'SGVsbG8gV29ybGQhIFRoaXMgaXMgYSB0ZXN0IG1lc3NhZ2UgZW5jb2RlZCBpbiBCYXNlNjQuIEl0IGNvbnRhaW5zIHNwZWNpYWwgY2hhcmFjdGVyczogISQmKCkrLz1bXXt9fjwhPj48Ojo=';

      final signed = sign(command, base64Data);
      expect(verifyCommand(signed, command), isTrue);
      expect(verifyData(signed), equals(base64Data));
    });

    test('XML data handling', () {
      const command = 'xml_data';
      const xmlData = '''<?xml version="1.0" encoding="UTF-8"?>
<root>
  <user id="123">
    <name>John Doe</name>
    <email>john@example.com</email>
    <preferences>
      <theme>dark</theme>
      <notifications enabled="true"/>
    </preferences>
  </user>
  <metadata>
    <created>2025-08-29T10:30:00Z</created>
    <version>1.2.3</version>
  </metadata>
</root>''';

      final signed = sign(command, xmlData);
      expect(verifyCommand(signed, command), isTrue);
      expect(verifyData(signed), equals(xmlData));
    });

    test('CSV data handling', () {
      const command = 'csv_data';
      const csvData = '''Name,Age,Email,Department,Salary
John Doe,30,john.doe@company.com,Engineering,75000
Jane Smith,28,jane.smith@company.com,Marketing,65000
Bob Johnson,35,bob.johnson@company.com,Sales,70000
Alice Wilson,32,alice.wilson@company.com,HR,60000
"Charlie Brown",29,"charlie.brown@company.com","Product Management",80000''';

      final signed = sign(command, csvData);
      expect(verifyCommand(signed, command), isTrue);
      expect(verifyData(signed), equals(csvData));
    });

    test('URL and query parameters', () {
      const command = 'url_data';
      const urlData =
          'https://api.example.com/users?id=123&include=profile,preferences&sort=created_at&order=desc&limit=50&offset=0&filter[status]=active&filter[role]=admin&api_key=abc123&timestamp=1693305000';

      final signed = sign(command, urlData);
      expect(verifyCommand(signed, command), isTrue);
      expect(verifyData(signed), equals(urlData));
    });

    test('Binary-like data (hex strings)', () {
      const command = 'binary_hex';
      const hexData =
          'deadbeef48656c6c6f20576f726c6421000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f';

      final signed = sign(command, hexData);
      expect(verifyCommand(signed, command), isTrue);
      expect(verifyData(signed), equals(hexData));
    });

    test('Configuration file data (TOML-like)', () {
      const command = 'config_data';
      const configData = '''[database]
host = "localhost"
port = 5432
username = "myuser"
password = "mypassword"
database = "mydb"
ssl_mode = "require"

[server]
host = "0.0.0.0"
port = 8080
workers = 4
debug = false

[logging]
level = "info"
file = "/var/log/app.log"
max_size = "100MB"
backup_count = 5

[features]
enable_cache = true
cache_ttl = 300
enable_metrics = true
metrics_endpoint = "/metrics"''';

      final signed = sign(command, configData);
      expect(verifyCommand(signed, command), isTrue);
      expect(verifyData(signed), equals(configData));
    });

    test('SQL query data', () {
      const command = 'sql_query';
      const sqlData = '''SELECT u.id, u.name, u.email, p.preferences, 
       COUNT(o.id) as order_count,
       SUM(o.total) as total_spent
FROM users u
LEFT JOIN user_preferences p ON u.id = p.user_id
LEFT JOIN orders o ON u.id = o.user_id
WHERE u.created_at >= '2025-01-01'
  AND u.status = 'active'
  AND (u.role = 'premium' OR u.total_orders > 10)
GROUP BY u.id, u.name, u.email, p.preferences
HAVING total_spent > 100
ORDER BY total_spent DESC, u.created_at ASC
LIMIT 50;''';

      final signed = sign(command, sqlData);
      expect(verifyCommand(signed, command), isTrue);
      expect(verifyData(signed), equals(sqlData));
    });

    test('Log file entries', () {
      const command = 'log_data';
      const logData =
          '''2025-08-29 10:30:15 [INFO] Application started successfully
2025-08-29 10:30:16 [DEBUG] Database connection established: postgresql://localhost:5432/mydb
2025-08-29 10:30:17 [INFO] Server listening on port 8080
2025-08-29 10:30:20 [WARN] High memory usage detected: 85%
2025-08-29 10:30:25 [ERROR] Failed to process request: Connection timeout after 30s
2025-08-29 10:30:25 [ERROR] Stack trace: 
  at processRequest (server.js:123)
  at handleConnection (server.js:456)
  at Server.listen (server.js:789)
2025-08-29 10:30:30 [INFO] Request processed successfully: GET /api/users/123''';

      final signed = sign(command, logData);
      expect(verifyCommand(signed, command), isTrue);
      expect(verifyData(signed), equals(logData));
    });

    test('Mixed content with special characters', () {
      const command = 'mixed_content';
      const mixedData = '''Content with various formats:

JSON snippet: {"key": "value", "number": 42, "boolean": true}

Base64: SGVsbG8gV29ybGQ=

URL: https://example.com/path?param=value&special=%20%21%40%23

Special chars: !"#\$%&'()*+,-./:;<=>?@[\\]^_`{|}~

Unicode: 🌟 ñáéíóú 世界 🚀

Newlines and tabs:
	- Item 1
	- Item 2
		- Sub item

Binary representation: \\x00\\x01\\x02\\xFF

Shell command: curl -X POST "https://api.com/data" -H "Content-Type: application/json" -d '{"data": "test"}'

Environment: \$HOME/.config/app.conf''';

      final signed = sign(command, mixedData);
      expect(verifyCommand(signed, command), isTrue);
      expect(verifyData(signed), equals(mixedData));
      expect(verifyData(signed), contains('🌟'));
      expect(verifyData(signed), contains('世界'));
    });

    test('Very large structured data', () {
      const command = 'large_data';

      // Generate a large JSON array
      final buffer = StringBuffer();
      buffer.write('{"items": [');
      for (int i = 0; i < 100; i++) {
        if (i > 0) buffer.write(',');
        buffer.write('''
{
  "id": $i,
  "name": "Item $i",
  "description": "This is a detailed description for item number $i with various properties and metadata",
  "properties": {
    "category": "category_${i % 10}",
    "priority": ${i % 5},
    "tags": ["tag${i % 3}", "tag${i % 7}"],
    "metadata": {
      "created": "2025-08-29T${(10 + i % 14).toString().padLeft(2, '0')}:${(i % 60).toString().padLeft(2, '0')}:00Z",
      "updated": null,
      "version": ${1 + i % 10}
    }
  }
}''');
      }
      buffer.write(']}');

      final largeData = buffer.toString();

      final signed = sign(command, largeData);
      expect(signed.length, equals(115 + largeData.length));
      expect(verifyCommand(signed, command), isTrue);
      expect(verifyData(signed), equals(largeData));
      expect(
        verifyData(signed)!.length,
        greaterThan(10000),
      ); // Should be quite large
    });

    test('Data with null bytes and control characters', () {
      const command = 'control_chars';
      // Create data with various control characters
      final controlData =
          'Start\x00null\x01SOH\x02STX\x03ETX\x04EOT\x05ENQ\x06ACK\x07BEL\x08BS\x09TAB\x0ALF\x0BVT\x0CFF\x0DCR\x0ESO\x0FSI\x10DLE\x11DC1\x12DC2\x13DC3\x14DC4\x15NAK\x16SYN\x17ETB\x18CAN\x19EM\x1ASUB\x1BESC\x1CFS\x1DGS\x1ERS\x1FUS\x7FDEL\x80\xFF\xFE\xFDEnd';

      final signed = sign(command, controlData);
      expect(verifyCommand(signed, command), isTrue);
      expect(verifyData(signed), equals(controlData));
    });

    test('Performance with multiple rapid signings', () {
      const command = 'perf_test';
      const data = 'Performance test data for rapid signing operations';

      final stopwatch = Stopwatch()..start();
      final results = <String>[];

      // Sign 100 times rapidly
      for (int i = 0; i < 100; i++) {
        final signed = sign(command, '$data $i');
        results.add(signed);
      }

      stopwatch.stop();

      // All should be unique (different nonces)
      final uniqueResults = results.toSet();
      expect(uniqueResults.length, equals(100));

      // All should verify correctly
      for (int i = 0; i < results.length; i++) {
        expect(verifyCommand(results[i], command), isTrue);
        expect(verifyData(results[i]), equals('$data $i'));
      }

      // Should complete in reasonable time (less than 1 second)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });
}
