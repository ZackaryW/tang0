@Skip('Web package version incompatibility with current Dart SDK')
library;

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:tang0/src/channel.dart';
import 'package:web/web.dart' as web;

void main() {
  group('Tang0Receive Async/Sync Hybrid Tests', () {
    test('Synchronous receive handler executes immediately', () {
      var callCount = 0;
      final receiver = SyncTestReceiver(
        onReceive: (data, event) {
          callCount++;
        },
      );

      // Simulate receiving a message
      receiver.handle('{"test": "data"}', createMockEvent());

      // Should execute immediately
      expect(callCount, equals(1));
    });

    test('Asynchronous receive handler executes automatically', () async {
      var callCount = 0;
      var asyncCompleted = false;
      final completer = Completer<void>();

      final receiver = AsyncTestReceiver(
        onReceive: (data, event) async {
          callCount++;
          await Future.delayed(Duration(milliseconds: 10));
          asyncCompleted = true;
          completer.complete();
        },
      );

      // Simulate receiving a message
      receiver.handle('{"test": "data"}', createMockEvent());

      // Async operation should start immediately
      expect(callCount, equals(1));
      expect(asyncCompleted, isFalse);

      // Wait for async operation to complete
      await completer.future;

      // Now it should be completed
      expect(asyncCompleted, isTrue);
    });

    test('Multiple async handlers execute independently', () async {
      var executionOrder = <int>[];
      final allCompleted = Completer<void>();
      var completedCount = 0;

      final receiver = AsyncTestReceiver(
        onReceive: (data, event) async {
          final value = data['index'] as int;
          await Future.delayed(Duration(milliseconds: 5));
          executionOrder.add(value);
          completedCount++;
          if (completedCount == 3) {
            allCompleted.complete();
          }
        },
      );

      // Simulate receiving multiple messages
      receiver.handle('{"index": 1}', createMockEvent());
      receiver.handle('{"index": 2}', createMockEvent());
      receiver.handle('{"index": 3}', createMockEvent());

      // Wait for all to complete
      await allCompleted.future;

      expect(executionOrder, equals([1, 2, 3]));
    });

    test('Hybrid sync and async messages work together', () async {
      var syncCount = 0;
      var asyncCount = 0;
      final asyncCompleter = Completer<void>();

      final syncReceiver = SyncTestReceiver(
        onReceive: (data, event) {
          syncCount++;
        },
      );

      final asyncReceiver = AsyncTestReceiver(
        onReceive: (data, event) async {
          await Future.delayed(Duration(milliseconds: 5));
          asyncCount++;
          asyncCompleter.complete();
        },
      );

      // Handle both sync and async
      syncReceiver.handle('{"test": "sync"}', createMockEvent());
      asyncReceiver.handle('{"test": "async"}', createMockEvent());

      // Sync should complete immediately
      expect(syncCount, equals(1));

      // Async should start immediately
      expect(asyncCount, equals(0)); // Not completed yet

      // Wait for async to complete
      await asyncCompleter.future;
      expect(asyncCount, equals(1));
    });

    test('FutureOr return type handles both sync and async paths', () async {
      var syncExecuted = false;
      var asyncExecuted = false;
      final asyncCompleter = Completer<void>();

      final hybridReceiver = HybridTestReceiver(
        syncHandler: (data, event) {
          syncExecuted = true;
        },
        asyncHandler: (data, event) async {
          await Future.delayed(Duration(milliseconds: 5));
          asyncExecuted = true;
          asyncCompleter.complete();
        },
      );

      // Test sync path
      hybridReceiver.useSyncPath = true;
      hybridReceiver.handle('{"test": "sync"}', createMockEvent());
      expect(syncExecuted, isTrue);
      expect(asyncExecuted, isFalse);

      // Test async path
      hybridReceiver.useSyncPath = false;
      hybridReceiver.handle('{"test": "async"}', createMockEvent());

      await asyncCompleter.future;
      expect(asyncExecuted, isTrue);
    });

    test('prehandle processes JSON correctly before receive', () async {
      Map<String, dynamic>? receivedData;
      final completer = Completer<void>();

      final receiver = AsyncTestReceiver(
        onReceive: (data, event) async {
          receivedData = data as Map<String, dynamic>;
          completer.complete();
        },
      );

      final jsonString = '{"name": "test", "value": 42}';
      receiver.handle(jsonString, createMockEvent());

      await completer.future;

      expect(receivedData, isNotNull);
      expect(receivedData!['name'], equals('test'));
      expect(receivedData!['value'], equals(42));
    });

    test('Non-JSON receiver handles raw strings', () {
      String? receivedString;

      final receiver = NonJsonTestReceiver(
        onReceive: (data, event) {
          receivedString = data as String;
        },
      );

      receiver.handle('raw string data', createMockEvent());

      expect(receivedString, equals('raw string data'));
    });

    test('Async operations do not block message handling', () async {
      var messageCount = 0;
      final lastCompleter = Completer<void>();

      final receiver = AsyncTestReceiver(
        onReceive: (data, event) async {
          final index = data['index'] as int;
          messageCount++;
          // Longer delay for first message
          if (index == 1) {
            await Future.delayed(Duration(milliseconds: 50));
          } else {
            await Future.delayed(Duration(milliseconds: 5));
          }
          if (index == 3) lastCompleter.complete();
        },
      );

      // Send 3 messages rapidly
      receiver.handle('{"index": 1}', createMockEvent());
      receiver.handle('{"index": 2}', createMockEvent());
      receiver.handle('{"index": 3}', createMockEvent());

      // All messages should be handled immediately (fire-and-forget)
      expect(messageCount, equals(3));

      // Wait for all to complete
      await lastCompleter.future;
    });
  });

  group('Tang0Receive Error Handling Tests', () {
    test('ErrorStrategy.skip silently ignores errors', () async {
      var successfulCalls = 0;
      var errorThrown = false;
      final allCompleted = Completer<void>();
      var completedCount = 0;

      final receiver = AsyncTestReceiver(
        onReceive: (data, event) async {
          if (data['shouldError'] == true) {
            errorThrown = true;
            completedCount++;
            if (completedCount == 3) allCompleted.complete();
            throw Exception('Test error');
          }
          await Future.delayed(Duration(milliseconds: 5));
          successfulCalls++;
          completedCount++;
          if (completedCount == 3) allCompleted.complete();
        },
        errorStrategy: Tang0ErrorStrategy.skip,
      );

      // Handle successful message
      receiver.handle('{"shouldError": false}', createMockEvent());

      // Handle error message - should not crash
      receiver.handle('{"shouldError": true}', createMockEvent());

      // Handle another successful message
      receiver.handle('{"shouldError": false}', createMockEvent());

      // Wait for all to complete
      await allCompleted.future;

      expect(successfulCalls, equals(2));
      expect(errorThrown, isTrue);
    });

    test('ErrorStrategy.print logs errors to debug console', () async {
      var errorThrown = false;
      final completer = Completer<void>();

      final receiver = AsyncTestReceiver(
        onReceive: (data, event) async {
          errorThrown = true;
          completer.complete();
          throw Exception('Test error for printing');
        },
        errorStrategy: Tang0ErrorStrategy.print,
      );

      // Handle error message - should print but not crash
      receiver.handle('{"test": "data"}', createMockEvent());

      await completer.future;

      expect(errorThrown, isTrue);
      // Note: We can't easily test debugPrint output, but we verify it doesn't crash
    });

    test('ErrorStrategy.callback invokes custom error handler', () async {
      Object? capturedError;
      StackTrace? capturedStackTrace;
      final errorCompleter = Completer<void>();

      final receiver = AsyncTestReceiver(
        onReceive: (data, event) async {
          throw Exception('Custom error test');
        },
        errorStrategy: Tang0ErrorStrategy.callback,
        onError: (error, stackTrace) {
          capturedError = error;
          capturedStackTrace = stackTrace;
          errorCompleter.complete();
        },
      );

      receiver.handle('{"test": "data"}', createMockEvent());

      await errorCompleter.future;

      expect(capturedError, isNotNull);
      expect(capturedError.toString(), contains('Custom error test'));
      expect(capturedStackTrace, isNotNull);
    });

    test('ErrorStrategy.callback with multiple errors', () async {
      var errorCount = 0;
      final allErrorsCompleter = Completer<void>();

      final receiver = AsyncTestReceiver(
        onReceive: (data, event) async {
          final value = data['value'] as int;
          if (value.isOdd) {
            throw Exception('Error for odd value: $value');
          }
          await Future.delayed(Duration(milliseconds: 5));
        },
        errorStrategy: Tang0ErrorStrategy.callback,
        onError: (error, stackTrace) {
          errorCount++;
          if (errorCount == 2) {
            allErrorsCompleter.complete();
          }
        },
      );

      // Send mix of even and odd values
      receiver.handle('{"value": 1}', createMockEvent()); // Error
      receiver.handle('{"value": 2}', createMockEvent()); // Success
      receiver.handle('{"value": 3}', createMockEvent()); // Error
      receiver.handle('{"value": 4}', createMockEvent()); // Success

      await allErrorsCompleter.future;

      expect(errorCount, equals(2));
    });

    test('Assert fails when callback strategy without onError', () {
      expect(
        () => AsyncTestReceiver(
          onReceive: (data, event) async {},
          errorStrategy: Tang0ErrorStrategy.callback,
          // Missing onError - should assert
        ),
        throwsAssertionError,
      );
    });

    test('Default error strategy is print', () {
      final receiver = AsyncTestReceiver(onReceive: (data, event) async {});

      expect(receiver.errorStrategy, equals(Tang0ErrorStrategy.print));
    });

    test('Sync errors in async receive are caught', () async {
      var errorCaught = false;
      final completer = Completer<void>();

      final receiver = AsyncTestReceiver(
        onReceive: (data, event) async {
          // Synchronous error in async function
          throw Exception('Sync error in async function');
        },
        errorStrategy: Tang0ErrorStrategy.callback,
        onError: (error, stackTrace) {
          errorCaught = true;
          completer.complete();
        },
      );

      receiver.handle('{"test": "data"}', createMockEvent());

      await completer.future;

      expect(errorCaught, isTrue);
    });

    test('Error after await in async receive is caught', () async {
      var errorCaught = false;
      final completer = Completer<void>();

      final receiver = AsyncTestReceiver(
        onReceive: (data, event) async {
          await Future.delayed(Duration(milliseconds: 5));
          throw Exception('Error after await');
        },
        errorStrategy: Tang0ErrorStrategy.callback,
        onError: (error, stackTrace) {
          errorCaught = true;
          completer.complete();
        },
      );

      receiver.handle('{"test": "data"}', createMockEvent());

      await completer.future;

      expect(errorCaught, isTrue);
    });
  });
}

// Test helper classes

/// Mock MessageEvent for testing
web.MessageEvent createMockEvent() {
  // Since we can't easily create web.MessageEvent in tests,
  // we'll use a dynamic approach. In real usage, this would be
  // a proper MessageEvent from BroadcastChannel
  return null as dynamic;
}

/// Synchronous test receiver
class SyncTestReceiver extends Tang0Receive {
  final void Function(dynamic data, web.MessageEvent event) onReceive;

  SyncTestReceiver({
    required this.onReceive,
    super.errorStrategy,
    super.onError,
  }) : super(isJson: true);

  @override
  FutureOr<void> receive(dynamic data, web.MessageEvent event) {
    onReceive(data, event);
  }
}

/// Asynchronous test receiver
class AsyncTestReceiver extends Tang0Receive {
  final Future<void> Function(dynamic data, web.MessageEvent event) onReceive;

  AsyncTestReceiver({
    required this.onReceive,
    super.errorStrategy,
    super.onError,
  }) : super(isJson: true);

  @override
  Future<void> receive(dynamic data, web.MessageEvent event) {
    return onReceive(data, event);
  }
}

/// Hybrid receiver that can switch between sync and async
class HybridTestReceiver extends Tang0Receive {
  final void Function(dynamic data, web.MessageEvent event) syncHandler;
  final Future<void> Function(dynamic data, web.MessageEvent event)
  asyncHandler;
  bool useSyncPath = true;

  HybridTestReceiver({
    required this.syncHandler,
    required this.asyncHandler,
    super.errorStrategy,
    super.onError,
  }) : super(isJson: true);

  @override
  FutureOr<void> receive(dynamic data, web.MessageEvent event) {
    if (useSyncPath) {
      syncHandler(data, event);
    } else {
      return asyncHandler(data, event);
    }
  }
}

/// Non-JSON receiver for raw string testing
class NonJsonTestReceiver extends Tang0Receive {
  final void Function(dynamic data, web.MessageEvent event) onReceive;

  NonJsonTestReceiver({
    required this.onReceive,
    super.errorStrategy,
    super.onError,
  }) : super(isJson: false);

  @override
  FutureOr<void> receive(dynamic data, web.MessageEvent event) {
    onReceive(data, event);
  }
}
