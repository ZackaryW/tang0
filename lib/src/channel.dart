import 'dart:convert';
import 'dart:js_interop';
import 'package:tang0/src/top0.dart';
import 'package:web/web.dart' as web;

/// Abstract base class for handling incoming Tang0 messages.
///
/// Implement this class to define how your application should handle
/// messages received through the Tang0 communication channel.
///
/// Example:
/// ```dart
/// class MyReceiver extends Tang0Receive {
///   @override
///   void receive(dynamic data, web.MessageEvent event) {
///     print('Received: $data');
///   }
/// }
/// ```
abstract class Tang0Receive {
  /// Whether to automatically parse incoming data as JSON.
  ///
  /// When `true`, incoming string data will be parsed as JSON using
  /// [jsonDecode]. When `false`, data will be passed as raw strings.
  final bool isJson;

  /// Creates a new Tang0Receive handler.
  ///
  /// [isJson] - Whether to parse incoming data as JSON (defaults to `true`).
  Tang0Receive({this.isJson = true});

  /// Called when a message is received and successfully processed.
  ///
  /// This is the main method you should override to handle incoming messages.
  ///
  /// [data] - The parsed message data (JSON object if [isJson] is true,
  ///          otherwise raw string).
  /// [event] - The original BroadcastChannel MessageEvent.
  void receive(dynamic data, web.MessageEvent event);

  /// Preprocesses raw message data before handling.
  ///
  /// If [isJson] is true, attempts to parse the data as JSON.
  /// Otherwise returns the raw string data.
  ///
  /// [data] - The raw message data as a string.
  /// Returns the processed data (parsed JSON or raw string).
  dynamic prehandle(String data) {
    if (isJson) {
      return jsonDecode(data);
    }
    return data;
  }

  /// Internal method that processes incoming messages.
  ///
  /// This method preprocesses the data using [prehandle] and then
  /// calls [receive] with the processed data.
  ///
  /// [data] - The raw message data as a string.
  /// [event] - The original BroadcastChannel MessageEvent.
  void handle(String data, web.MessageEvent event) {
    final parsed = prehandle(data);
    // Handle the parsed data
    receive(parsed, event);
  }
}

/// A secure communication channel for cross-tab messaging using BroadcastChannel API.
///
/// Tang0Channel provides a secure wrapper around the browser's BroadcastChannel API,
/// automatically handling message signing, verification, and routing to appropriate
/// receivers based on command strings.
///
/// Features:
/// - Automatic message signing and verification using HMAC-SHA256
/// - Command-based message routing
/// - JSON serialization support
/// - Cross-tab communication within the same origin
///
/// Example:
/// ```dart
/// final channel = Tang0Channel(name: "my_app");
///
/// // Register a receiver for "update" commands
/// channel.registerReceiver("update", MyUpdateReceiver());
///
/// // Send a message to all tabs
/// channel.send("update", {"count": 42});
/// ```
class Tang0Channel {
  /// The name of this communication channel.
  ///
  /// Multiple Tang0Channel instances with the same name will communicate
  /// with each other across browser tabs. The actual BroadcastChannel name
  /// will be prefixed with "tang0_".
  final String name;

  /// Map of command strings to their corresponding message receivers.
  final Map<String, Tang0Receive> _receivers = {};

  /// The underlying BroadcastChannel instance.
  late final web.BroadcastChannel _channel;

  /// Creates a new Tang0Channel with the specified name.
  ///
  /// [name] - The channel name (defaults to "untitled"). This will be
  ///          prefixed with "tang0_" for the actual BroadcastChannel.
  ///
  /// The constructor automatically sets up the BroadcastChannel and
  /// begins listening for incoming messages.
  Tang0Channel({this.name = "untitled"}) {
    _channel = web.BroadcastChannel("tang0_$name");
    _channel.addEventListener("message", _handleMessage.toJS);
  }

  /// Registers a message receiver for a specific command.
  ///
  /// When a message with the specified command is received, it will be
  /// routed to the provided receiver's [Tang0Receive.handle] method.
  ///
  /// [command] - The command string to listen for (max 32 characters).
  /// [receiver] - The Tang0Receive instance to handle matching messages.
  ///
  /// Example:
  /// ```dart
  /// channel.registerReceiver("chat", MyChatReceiver());
  /// channel.registerReceiver("sync", MySyncReceiver());
  /// ```
  void registerReceiver(String command, Tang0Receive receiver) {
    _receivers[command] = receiver;
  }

  /// Internal method that handles incoming BroadcastChannel messages.
  ///
  /// This method:
  /// 1. Safely converts JavaScript message data to Dart strings
  /// 2. Matches the message command against registered receivers
  /// 3. Verifies message signature and authenticity
  /// 4. Routes verified messages to the appropriate receiver
  ///
  /// [event] - The BroadcastChannel MessageEvent containing the message data.
  void _handleMessage(web.MessageEvent event) {
    // Use proper JS interop conversion with type safety
    final jsData = event.data;
    if (jsData == null) return;

    // Convert JSAny? to String safely with fallback
    String data;
    try {
      if (jsData.typeofEquals('string')) {
        data = (jsData as JSString).toDart;
      } else {
        // Handle case where data might be sent as different type
        data = jsData.toString();
      }
    } catch (e) {
      // If conversion fails completely, ignore the message
      return;
    }

    final matched = matchCommand(data, _receivers.keys.toList());
    if (matched == null) {
      return;
    }

    // Extract data and forward to appropriate receiver
    final extractedData = verifyData(data);
    if (extractedData != null) {
      final receiver = _receivers[matched];
      if (receiver != null) {
        receiver.handle(extractedData, event);
      }
    }
  }

  /// Sends a message to all tabs listening on this channel.
  ///
  /// The message is automatically signed using HMAC-SHA256 for security
  /// and can be optionally JSON-encoded before transmission.
  ///
  /// [command] - The command string (max 32 characters) that identifies
  ///             the message type. Receiving tabs must have a registered
  ///             receiver for this command.
  /// [data] - The message payload to send.
  /// [isJson] - Whether to JSON-encode the data before sending (defaults to true).
  ///
  /// Example:
  /// ```dart
  /// // Send JSON data
  /// channel.send("update", {"userId": 123, "status": "online"});
  ///
  /// // Send raw string data
  /// channel.send("message", "Hello World", isJson: false);
  /// ```
  ///
  /// Throws:
  /// - [ArgumentError] if command exceeds 32 characters
  void send(String command, dynamic data, {bool isJson = true}) {
    // if is json, convert to string
    final message = isJson ? jsonEncode(data) : data.toString();
    final payload = sign(command, message);
    _channel.postMessage(payload.toJS);
  }
}
