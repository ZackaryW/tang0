import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:tang0/src/channel.dart';
import 'package:web/web.dart' as web;

/// Helper utilities for creating one-way synchronization channels between widgets.
///
/// This module provides convenient methods to establish custom communication
/// channels where one widget can send typed messages to other widgets across
/// browser tabs without bidirectional synchronization.
///
/// Example use cases:
/// - Event notifications (user logged in, data updated)
/// - Command broadcasting (refresh data, show modal)
/// - Status updates (loading states, progress indicators)

/// A one-way message sender that broadcasts typed payloads to receivers.
///
/// Creates a secure communication channel for sending custom messages
/// with defined payload types to specific receiver widgets.
///
/// Example:
/// ```dart
/// final sender = OneWaySender<UserEvent>(
///   command: "user_login",
///   channelName: "auth_events",
/// );
///
/// // Send a message
/// sender.send(UserEvent(userId: 123, name: "John"));
/// ```
class OneWaySender<T> {
  /// The unique command identifier for this message type.
  final String command;

  /// The Tang0 communication channel.
  late final Tang0Channel _channel;

  /// Function to serialize the payload to JSON-compatible data.
  final Map<String, dynamic> Function(T)? _serializer;

  /// Creates a new one-way message sender.
  ///
  /// [command] - Unique command string to identify message type (max 32 chars).
  /// [channelName] - Optional channel name (defaults to "one_way_sync").
  /// [serializer] - Optional custom serializer for complex types.
  ///                If not provided, assumes T has a toJson() method or is JSON-serializable.
  OneWaySender({
    required this.command,
    String? channelName,
    Map<String, dynamic> Function(T)? serializer,
  }) : _serializer = serializer {
    _channel = Tang0Channel(name: channelName ?? "one_way_sync");
  }

  /// Sends a typed message to all listening receivers.
  ///
  /// [payload] - The data to send. Must be JSON-serializable.
  ///
  /// The message is automatically signed and secured using Tang0's
  /// cryptographic system.
  ///
  /// Example:
  /// ```dart
  /// sender.send(MyData(count: 42, message: "Hello"));
  /// ```
  void send(T payload) {
    Map<String, dynamic> data;

    if (_serializer != null) {
      data = _serializer(payload);
    } else if (payload is Map<String, dynamic>) {
      data = payload;
    } else {
      // Try to call toJson if it exists
      try {
        data = (payload as dynamic).toJson();
      } catch (e) {
        // For primitive types or other JSON-serializable objects
        data = {'value': payload};
      }
    }

    _channel.send(command, data);
  }
}

/// A one-way message receiver that listens for typed payloads from senders.
///
/// Receives and processes messages from [OneWaySender] instances with
/// matching command strings and channels.
///
/// The [onReceive] callback can be either synchronous or asynchronous.
/// Async operations are queued and can be executed using [runPendingTasks].
class OneWayReceiver<T> extends Tang0Receive {
  /// Callback function called when a message is received.
  /// Can be sync or async.
  final FutureOr<void> Function(T data, web.MessageEvent event) onReceive;

  /// Function to deserialize JSON data back to the expected type.
  final T Function(Map<String, dynamic>)? _deserializer;

  /// Creates a new one-way message receiver.
  ///
  /// [onReceive] - Callback function to handle received messages (sync or async).
  /// [deserializer] - Optional custom deserializer for complex types.
  ///                  If not provided, assumes T has a fromJson constructor.
  /// [errorStrategy] - How to handle errors in async receive operations (defaults to [Tang0ErrorStrategy.print]).
  /// [onError] - Custom error handler, required when [errorStrategy] is [Tang0ErrorStrategy.callback].
  OneWayReceiver({
    required this.onReceive,
    T Function(Map<String, dynamic>)? deserializer,
    super.errorStrategy,
    super.onError,
  }) : _deserializer = deserializer,
       super(isJson: true);

  @override
  FutureOr<void> receive(dynamic data, web.MessageEvent event) {
    if (data is Map<String, dynamic>) {
      T? payload;

      if (_deserializer != null) {
        try {
          payload = _deserializer(data);
        } catch (e) {
          return Future<void>.value();
        }
      } else if (T == Map<String, dynamic>) {
        payload = data as T;
      } else if (data.containsKey('value')) {
        // Handle primitive types wrapped in {'value': ...}
        payload = data['value'] as T;
      } else {
        // For custom types without deserializer, user must provide one
        debugPrint(
          'Error: Cannot deserialize $T without a deserializer function. '
          'Provide one in OneWayReceiver constructor or use OneWaySync.receiver() factory.',
        );
        return Future<void>.value();
      }

      if (payload != null) {
        return onReceive(payload, event);
      }
    }
    return Future<void>.value();
  }
}

/// Widget that sets up one-way message receiving capabilities.
///
/// Wraps a child widget and automatically handles message reception
/// from [OneWaySender] instances with matching commands.
///
/// The [onReceive] callback can be either synchronous or asynchronous.
///
/// Example:
/// ```dart
/// OneWayReceiver<UserEvent>(
///   command: "user_login",
///   channelName: "auth_events",
///   onReceive: (event, messageEvent) {
///     print("User logged in: ${event.name}");
///   },
///   child: MyWidget(),
/// )
///
/// // Async example:
/// OneWayReceiver<UserEvent>(
///   command: "user_login",
///   onReceive: (event, messageEvent) async {
///     await handleUserLogin(event);
///   },
///   child: MyWidget(),
/// )
/// ```
class OneWayReceiverWidget<T> extends StatefulWidget {
  /// The child widget to wrap.
  final Widget child;

  /// The command string to listen for.
  final String command;

  /// Optional channel name (must match sender's channel).
  final String? channelName;

  /// Callback function for received messages (can be sync or async).
  final FutureOr<void> Function(T data, web.MessageEvent event) onReceive;

  /// Optional custom deserializer.
  final T Function(Map<String, dynamic>)? deserializer;

  /// Error handling strategy for async operations.
  final Tang0ErrorStrategy? errorStrategy;

  /// Optional error callback.
  final void Function(Object error, StackTrace stackTrace)? onError;

  /// Creates a new one-way receiver widget.
  const OneWayReceiverWidget({
    super.key,
    required this.child,
    required this.command,
    required this.onReceive,
    this.channelName,
    this.deserializer,
    this.errorStrategy,
    this.onError,
  });

  @override
  State<OneWayReceiverWidget<T>> createState() =>
      _OneWayReceiverWidgetState<T>();
}

class _OneWayReceiverWidgetState<T> extends State<OneWayReceiverWidget<T>> {
  Tang0Channel? _channel;

  @override
  void initState() {
    super.initState();
    _initializeAsync();
  }

  void _initializeAsync() async {
    // Tang0 will use fallback tokens if not explicitly initialized
    // For better security, initialize with: await initializeTang0Tokens();

    // Create channel
    _channel = Tang0Channel(name: widget.channelName ?? "one_way_sync");

    // Register receiver
    _channel!.registerReceiver(
      widget.command,
      OneWayReceiver<T>(
        onReceive: widget.onReceive,
        deserializer: widget.deserializer,
        errorStrategy: widget.errorStrategy ?? Tang0ErrorStrategy.print,
        onError: widget.onError,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Utility class for creating common one-way sync patterns.
///
/// Provides factory methods for typical communication scenarios
/// with predefined command names and payload types.
class OneWaySync {
  /// Creates a notification sender/receiver pair for simple string messages.
  ///
  /// [notificationType] - Unique identifier for this notification type.
  /// [channelName] - Optional channel name.
  ///
  /// Returns a tuple of (sender, receiver function) for easy setup.
  ///
  /// Example:
  /// ```dart
  /// final (sender, createReceiver) = OneWaySync.notification("user_action");
  ///
  /// // In sender widget:
  /// sender.send("User clicked button");
  ///
  /// // In receiver widget:
  /// OneWayReceiverWidget(
  ///   command: "user_action",
  ///   onReceive: (message, event) => print(message),
  ///   child: MyWidget(),
  /// )
  /// ```
  static (OneWaySender<String>, String Function()) notification(
    String notificationType, {
    String? channelName,
  }) {
    final sender = OneWaySender<String>(
      command: notificationType,
      channelName: channelName,
    );
    return (sender, () => notificationType);
  }

  /// Creates an event sender for structured data with automatic command generation.
  ///
  /// [eventType] - Base name for the event type.
  /// [channelName] - Optional channel name.
  ///
  /// Automatically generates a unique command based on the event type and payload structure.
  ///
  /// Example:
  /// ```dart
  /// final sender = OneWaySync.event<UserLoginEvent>("auth");
  /// sender.send(UserLoginEvent(userId: 123, timestamp: DateTime.now()));
  /// ```
  static OneWaySender<T> event<T>(
    String eventType, {
    String? channelName,
    Map<String, dynamic> Function(T)? serializer,
  }) {
    // Generate command based on event type and generic type
    final command = '${eventType}_${T.toString().toLowerCase()}';

    return OneWaySender<T>(
      command: command,
      channelName: channelName,
      serializer: serializer,
    );
  }

  /// Creates a command sender for triggering actions across tabs.
  ///
  /// Commands are simple action triggers without complex payloads.
  ///
  /// [actionName] - The name of the action to trigger.
  /// [channelName] - Optional channel name.
  ///
  /// Example:
  /// ```dart
  /// final refreshCommand = OneWaySync.command("refresh_data");
  /// refreshCommand.send("trigger"); // Simple trigger message
  /// ```
  static OneWaySender<String> command(
    String actionName, {
    String? channelName,
  }) {
    return OneWaySender<String>(
      command: 'cmd_$actionName',
      channelName: channelName,
    );
  }

  /// Creates a status update sender for broadcasting state changes.
  ///
  /// [statusType] - The type of status being broadcast.
  /// [channelName] - Optional channel name.
  ///
  /// Example:
  /// ```dart
  /// final loadingStatus = OneWaySync.status<LoadingState>("loading");
  /// loadingStatus.send(LoadingState(isLoading: true, progress: 0.5));
  /// ```
  static OneWaySender<T> status<T>(
    String statusType, {
    String? channelName,
    Map<String, dynamic> Function(T)? serializer,
  }) {
    return OneWaySender<T>(
      command: 'status_$statusType',
      channelName: channelName,
      serializer: serializer,
    );
  }
}

/// Function-based helper for generating unique command names.
///
/// Creates deterministic command strings based on function signatures
/// and caller context.
///
/// [Function] - The function to base the command on.
/// [context] - Optional additional context for uniqueness.
///
/// Returns a unique command string suitable for Tang0 channels.
///
/// Example:
/// ```dart
/// void handleUserLogin() {
///   final command = generateCommandFromFunction(handleUserLogin, "auth");
///   // Results in something like "func_handleUserLogin_auth"
/// }
/// ```
String generateCommandFromFunction(Function func, [String? context]) {
  final funcString = func.toString();
  // Extract function name if possible
  final match = RegExp(r"'([^']+)'").firstMatch(funcString);
  final funcName = match?.group(1) ?? 'anonymous';

  final parts = ['func', funcName];
  if (context != null) {
    parts.add(context);
  }

  return parts.join('_').replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
}
