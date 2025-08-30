import 'package:flutter/widgets.dart';
import 'package:tang0/src/channel.dart';
import 'package:tang0/src/top0.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:web/web.dart' as web;

class SyncedVar<T> {
  final String name;
  T _value;
  final void Function(T)? onChanged;
  void Function()? _onSyncTrigger; // Callback to trigger sync

  SyncedVar({required this.name, required T value, this.onChanged})
    : _value = value;

  T get value => _value;

  set value(T newValue) {
    if (_value != newValue) {
      _value = newValue;
      onChanged?.call(newValue);
      _onSyncTrigger?.call(); // Trigger sync when value changes
    }
  }

  String get typeName => T.toString();

  // Set value without triggering callbacks (for sync updates)
  void _setValueSilently(T newValue) {
    _value = newValue;
  }
}

class SyncedWidget extends StatefulWidget {
  final List<SyncedVar> syncedVars;
  final Widget Function(BuildContext context) builder;
  final String? channelName;

  const SyncedWidget({
    super.key,
    required this.syncedVars,
    required this.builder,
    this.channelName,
  });

  @override
  State<SyncedWidget> createState() => _SyncedWidgetState();
}

class _SyncedWidgetState extends State<SyncedWidget> {
  Tang0Channel? _channel;
  String? _widgetHash;
  String? _command;

  @override
  void initState() {
    super.initState();
    _initializeAsync();
  }

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

  void _broadcastAllState() {
    if (_channel == null || _command == null) return;

    final serializedState = _serializeAllState();
    _channel!.send(_command!, serializedState);
  }

  void _handleSyncData(Map<String, dynamic> data, web.MessageEvent event) {
    print('Received sync data: $data');
    final stateData = data['state'] as Map<String, dynamic>;
    // Note: timestamp could be used for conflict resolution in future versions

    bool anyUpdated = false;

    // Update all variables from the serialized state
    for (final syncedVar in widget.syncedVars) {
      final varData = stateData[syncedVar.name];
      if (varData != null) {
        final newValue = varData['value'];
        print(
          'Processing ${syncedVar.name}: current=${syncedVar.value}, new=$newValue',
        );

        // Update value silently to avoid triggering sync loops
        if (syncedVar is SyncedVar<int> && newValue is int) {
          if (syncedVar.value != newValue) {
            print(
              'Updating ${syncedVar.name} from ${syncedVar.value} to $newValue',
            );
            syncedVar._setValueSilently(newValue);
            anyUpdated = true;
          }
        } else if (syncedVar is SyncedVar<String> && newValue is String) {
          if (syncedVar.value != newValue) {
            print(
              'Updating ${syncedVar.name} from ${syncedVar.value} to $newValue',
            );
            syncedVar._setValueSilently(newValue);
            anyUpdated = true;
          }
        } else if (syncedVar is SyncedVar<bool> && newValue is bool) {
          if (syncedVar.value != newValue) {
            print(
              'Updating ${syncedVar.name} from ${syncedVar.value} to $newValue',
            );
            syncedVar._setValueSilently(newValue);
            anyUpdated = true;
          }
        } else if (syncedVar is SyncedVar<double> && newValue is double) {
          if (syncedVar.value != newValue) {
            print(
              'Updating ${syncedVar.name} from ${syncedVar.value} to $newValue',
            );
            syncedVar._setValueSilently(newValue);
            anyUpdated = true;
          }
        }
        // Add more types as needed
      }
    }

    // Trigger UI rebuild if any values were updated
    if (anyUpdated && mounted) {
      print('Triggering UI rebuild due to sync updates');
      setState(() {});
    } else {
      print('No updates needed or widget not mounted');
    }
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

class _SyncReceiver extends Tang0Receive {
  final void Function(Map<String, dynamic>, web.MessageEvent) onDataReceived;

  _SyncReceiver({required this.onDataReceived}) : super(isJson: true);

  @override
  void receive(dynamic data, web.MessageEvent event) {
    if (data is Map<String, dynamic>) {
      onDataReceived(data, event);
    }
  }
}
