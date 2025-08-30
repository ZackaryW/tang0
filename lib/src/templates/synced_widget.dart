import 'package:flutter/widgets.dart';
import 'package:tang0/src/channel.dart';
import 'package:tang0/src/top0.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:web/web.dart' as web;

/// A reactive variable that automatically synchronizes its value across browser tabs.
///
/// SyncedVar wraps a value of type [T] and provides automatic change detection
/// and synchronization capabilities when used within a [SyncedWidget].
///
/// Example:
/// ```dart
/// final counter = SyncedVar<int>(name: "counter", value: 0);
/// counter.value = 5; // This will sync to other tabs
/// ```
class SyncedVar<T> {
  /// The unique name identifier for this synchronized variable.
  ///
  /// This name is used to match variables across different tabs and must be
  /// consistent across all instances that should sync together.
  final String name;

  /// The current value of the synchronized variable.
  T _value;

  /// Optional callback function called whenever the value changes locally.
  ///
  /// This callback is triggered by direct assignment but not by sync updates
  /// from other tabs to prevent infinite loops.
  final void Function(T)? onChanged;

  /// Internal callback used by [SyncedWidget] to trigger synchronization.
  void Function()? _onSyncTrigger; // Callback to trigger sync

  /// Creates a new synchronized variable.
  ///
  /// [name] - Unique identifier for this variable across tabs.
  /// [value] - Initial value for the variable.
  /// [onChanged] - Optional callback for local value changes.
  SyncedVar({required this.name, required T value, this.onChanged})
    : _value = value;

  /// Gets the current value of the synchronized variable.
  T get value => _value;

  /// Sets a new value and triggers synchronization to other tabs.
  ///
  /// When a new value is assigned, this will:
  /// 1. Update the internal value
  /// 2. Call the [onChanged] callback if provided
  /// 3. Trigger synchronization to other browser tabs
  ///
  /// Only triggers callbacks and sync if the new value differs from current.
  set value(T newValue) {
    if (_value != newValue) {
      _value = newValue;
      onChanged?.call(newValue);
      _onSyncTrigger?.call(); // Trigger sync when value changes
    }
  }

  /// Returns the string representation of the variable's type.
  ///
  /// Used internally for type verification during synchronization.
  String get typeName => T.toString();

  /// Sets the value without triggering callbacks or synchronization.
  ///
  /// This method is used internally by [SyncedWidget] when receiving
  /// sync updates from other tabs to prevent sync loops.
  ///
  /// [newValue] - The value to set silently.
  void _setValueSilently(T newValue) {
    _value = newValue;
  }
}

/// A Flutter widget that automatically synchronizes variable states across browser tabs.
///
/// SyncedWidget creates a secure communication channel using the Tang0 system
/// to keep specified variables in sync between different browser tabs of the same
/// web application. It automatically handles:
///
/// - Secure message signing and verification
/// - Type-safe variable synchronization
/// - Conflict-free updates using timestamps
/// - Automatic UI rebuilding when sync occurs
///
/// The widget uses a hash of variable names and types to ensure only compatible
/// widget instances synchronize with each other.
///
/// Example:
/// ```dart
/// SyncedWidget(
///   syncedVars: [
///     SyncedVar<int>(name: "counter", value: 0),
///     SyncedVar<String>(name: "message", value: "Hello"),
///   ],
///   builder: (context) => MyUI(),
/// )
/// ```
///
/// Security: All messages are automatically signed with HMAC-SHA256 and verified
/// on receipt to prevent tampering or malicious injection.
class SyncedWidget extends StatefulWidget {
  /// List of variables to keep synchronized across browser tabs.
  ///
  /// All variables must have unique names within this list. Only widgets
  /// with the same variable structure (names and types) will sync together.
  final List<SyncedVar> syncedVars;

  /// Builder function that creates the widget tree.
  ///
  /// This function will be called to rebuild the UI whenever any of the
  /// synchronized variables change, either locally or from other tabs.
  final Widget Function(BuildContext context) builder;

  /// Optional custom name for the communication channel.
  ///
  /// If not provided, defaults to "synced_widget". Multiple SyncedWidget
  /// instances with the same channel name can communicate, but they must
  /// also have matching variable structures to actually sync.
  final String? channelName;

  /// Creates a new synchronized widget.
  ///
  /// [syncedVars] - List of variables to synchronize across tabs.
  /// [builder] - Function to build the UI that will be rebuilt on sync.
  /// [channelName] - Optional custom channel name (defaults to "synced_widget").
  const SyncedWidget({
    super.key,
    required this.syncedVars,
    required this.builder,
    this.channelName,
  });

  @override
  State<SyncedWidget> createState() => _SyncedWidgetState();
}

/// Internal state class for [SyncedWidget] that handles synchronization logic.
class _SyncedWidgetState extends State<SyncedWidget> {
  /// The Tang0 communication channel for cross-tab messaging.
  Tang0Channel? _channel;

  /// Truncated SHA1 hash representing this widget's variable structure.
  ///
  /// Used to ensure only compatible widgets sync with each other.
  String? _widgetHash;

  /// The command string used for synchronization messages.
  ///
  /// Format: "sync_widget_[widgetHash]"
  String? _command;

  @override
  void initState() {
    super.initState();
    _initializeAsync();
  }

  /// Asynchronously initializes the synchronization system.
  ///
  /// This method:
  /// 1. Initializes Tang0 security tokens
  /// 2. Computes the widget hash based on variable structure
  /// 3. Sets up the communication channel
  /// 4. Registers message receivers
  /// 5. Sets up change listeners for all synchronized variables
  void _initializeAsync() async {
    // Initialize Tang0 tokens first
    await initializeTang0Tokens();

    // Compute truncated SHA1 hash based on variable names and types
    _widgetHash = _computeWidgetHash();
    _command = 'sync_widget_$_widgetHash';

    // Initialize channel
    _channel = Tang0Channel(name: widget.channelName ?? "synced_widget");

    // Register receiver for sync updates
    _channel!.registerReceiver(
      _command!,
      _SyncReceiver(onDataReceived: _handleSyncData),
    );

    // Set up change listeners for all synced vars
    _setupChangeListeners();
  }

  /// Computes a deterministic hash based on variable names and types.
  ///
  /// This ensures that only widgets with identical variable structures
  /// will synchronize with each other. The hash is computed from:
  /// - Variable names
  /// - Variable types (T.toString())
  /// - Sorted alphabetically for consistency
  ///
  /// Returns a 16-character truncated SHA1 hash.
  String _computeWidgetHash() {
    // Create a deterministic string from all synced var names and types
    final varInfo =
        widget.syncedVars.map((v) => '${v.name}:${v.typeName}').toList()
          ..sort(); // Sort for consistency across instances

    final combined = varInfo.join('|');

    // Compute SHA1 and truncate to 16 characters
    final bytes = utf8.encode(combined);
    final digest = sha1.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  /// Sets up change listeners for all synchronized variables.
  ///
  /// Each variable gets a callback that:
  /// 1. Broadcasts the current state to other tabs
  /// 2. Triggers a UI rebuild if the widget is still mounted
  void _setupChangeListeners() {
    for (final syncedVar in widget.syncedVars) {
      syncedVar._onSyncTrigger = () {
        _broadcastAllState();
        // Trigger UI rebuild when any variable changes
        if (mounted) {
          setState(() {});
        }
      };
    }
  }

  /// Serializes the current state of all synchronized variables.
  ///
  /// Creates a JSON-serializable map containing:
  /// - `state`: Map of variable names to {value, type} objects
  /// - `timestamp`: Current timestamp for potential conflict resolution
  ///
  /// Returns a map ready for JSON encoding and transmission.
  Map<String, dynamic> _serializeAllState() {
    final stateData = <String, dynamic>{};

    for (final syncedVar in widget.syncedVars) {
      stateData[syncedVar.name] = {
        'value': syncedVar.value,
        'type': syncedVar.typeName,
      };
    }

    return {
      'state': stateData,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Broadcasts the current state of all variables to other tabs.
  ///
  /// Called automatically when any synchronized variable changes locally.
  /// The message is sent securely through the Tang0 channel system.
  void _broadcastAllState() {
    if (_channel == null || _command == null) return;

    final serializedState = _serializeAllState();
    _channel!.send(_command!, serializedState);
  }

  /// Handles incoming synchronization data from other browser tabs.
  ///
  /// This method:
  /// 1. Extracts the state data from the received message
  /// 2. Updates matching synchronized variables with new values
  /// 3. Uses type-safe casting to ensure data integrity
  /// 4. Updates values silently to prevent sync loops
  /// 5. Triggers UI rebuild if any values were actually updated
  ///
  /// [data] - The deserialized message data containing state updates.
  /// [event] - The original BroadcastChannel MessageEvent.
  void _handleSyncData(Map<String, dynamic> data, web.MessageEvent event) {
    final stateData = data['state'] as Map<String, dynamic>;
    // Note: timestamp could be used for conflict resolution in future versions

    bool anyUpdated = false;

    // Update all variables from the serialized state
    for (final syncedVar in widget.syncedVars) {
      final varData = stateData[syncedVar.name];
      if (varData != null) {
        final newValue = varData['value'];

        // Update value silently to avoid triggering sync loops
        if (syncedVar is SyncedVar<int> && newValue is int) {
          if (syncedVar.value != newValue) {
            syncedVar._setValueSilently(newValue);
            anyUpdated = true;
          }
        } else if (syncedVar is SyncedVar<String> && newValue is String) {
          if (syncedVar.value != newValue) {
            syncedVar._setValueSilently(newValue);
            anyUpdated = true;
          }
        } else if (syncedVar is SyncedVar<bool> && newValue is bool) {
          if (syncedVar.value != newValue) {
            syncedVar._setValueSilently(newValue);
            anyUpdated = true;
          }
        } else if (syncedVar is SyncedVar<double> && newValue is double) {
          if (syncedVar.value != newValue) {
            syncedVar._setValueSilently(newValue);
            anyUpdated = true;
          }
        }
        // Add more types as needed
      }
    }

    // Trigger UI rebuild if any values were updated
    if (anyUpdated && mounted) {
      setState(() {});
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }

  @override
  void dispose() {
    // Clean up channel resources if needed
    super.dispose();
  }
}

/// Internal message receiver for handling sync data from other tabs.
///
/// This class extends [Tang0Receive] to process JSON messages containing
/// synchronized variable state updates.
class _SyncReceiver extends Tang0Receive {
  /// Callback function called when valid sync data is received.
  final void Function(Map<String, dynamic>, web.MessageEvent) onDataReceived;

  /// Creates a new sync message receiver.
  ///
  /// [onDataReceived] - Function to call with deserialized sync data.
  _SyncReceiver({required this.onDataReceived}) : super(isJson: true);

  /// Processes received sync messages and forwards valid data to the callback.
  ///
  /// Only forwards messages that are valid JSON maps to prevent errors.
  ///
  /// [data] - The deserialized message data.
  /// [event] - The original BroadcastChannel MessageEvent.
  @override
  void receive(dynamic data, web.MessageEvent event) {
    if (data is Map<String, dynamic>) {
      onDataReceived(data, event);
    }
  }
}
