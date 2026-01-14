import 'dart:convert';
import 'dart:js_interop';
import 'package:uuid/uuid.dart';
import 'package:web/web.dart' as web;

typedef Tang0PayloadEncoder = String Function(String senderId, String message);
typedef Tang0PayloadDecoder =
    ({String senderId, String message})? Function(String payload);

typedef Tang0JsonMutator = Map<String, dynamic> Function(Map<String, dynamic>);

class _ListenerEntry {
  final void Function(String) callback;
  final Tang0PayloadDecoder? payloadDecoder;
  final void Function(String rawPayload)? onPayload;

  const _ListenerEntry({
    required this.callback,
    this.payloadDecoder,
    this.onPayload,
  });
}

class Tang0Channel {
  static final Map<String, Tang0Channel> _channels = {};
  static final Map<String, List<_ListenerEntry>> _listeners = {};
  static final Set<String> _wiredListenerIds = <String>{};
  static String? _globalIdentifier;

  /// Default payload encoder/decoder.
  ///
  /// Payload format: `$senderId::$message`
  static Tang0PayloadEncoder payloadEncoder = (senderId, message) =>
      '$senderId::$message';
  static Tang0PayloadDecoder payloadDecoder = (payload) {
    final splitIndex = payload.indexOf('::');
    if (splitIndex == -1) return null;
    return (
      senderId: payload.substring(0, splitIndex),
      message: payload.substring(splitIndex + 2),
    );
  };

  /// Optional “inner rim” JSON processing.
  ///
  /// These run *inside* the payload (the JSON string content) and let you
  /// inject/override fields or reshape the map before encoding/sending or after
  /// decoding/receiving.
  ///
  /// Notes:
  /// - Only applies to JSON map payloads.
  /// - This is separate from [payloadEncoder]/[payloadDecoder] which operate on
  ///   the outer `senderId::message` envelope.
  static Tang0JsonMutator jsonOutbound = (map) => map;
  static Tang0JsonMutator jsonInbound = (map) => map;

  static Map<String, dynamic>? tryDecodeJsonMessage(String message) {
    try {
      final decoded = jsonDecode(message);
      if (decoded is! Map) return null;
      return jsonInbound(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  final String id;
  late final web.BroadcastChannel _channel;

  Tang0Channel._internal(this.id) {
    _channel = web.BroadcastChannel(id);
  }

  factory Tang0Channel(String id) {
    _localStorageCheck();

    return _channels.putIfAbsent(id, () => Tang0Channel._internal(id));
  }

  void send(String message) {
    final senderId = _globalIdentifier ?? '';
    final payload = payloadEncoder(senderId, message);

    _channel.postMessage(payload.toJS);
  }

  void sendJson(Map<String, dynamic> message) {
    final outbound = jsonOutbound(Map<String, dynamic>.from(message));
    send(jsonEncode(outbound));
  }

  static void Function() addGListener(
    String id,
    void Function(String) listener, {
    Tang0PayloadDecoder? payloadDecoder,
    void Function(String rawPayload)? onPayload,
  }) {
    final list = _listeners.putIfAbsent(id, () => <_ListenerEntry>[]);
    final entry = _ListenerEntry(
      callback: listener,
      payloadDecoder: payloadDecoder,
      onPayload: onPayload,
    );
    list.add(entry);

    void dispose() {
      final existing = _listeners[id];
      if (existing == null) return;

      existing.removeWhere((e) => identical(e, entry));
      if (existing.isNotEmpty) return;

      _listeners.remove(id);
      _wiredListenerIds.remove(id);
    }

    if (_wiredListenerIds.contains(id)) return dispose;
    _wiredListenerIds.add(id);

    final channel = Tang0Channel(id);
    channel._channel.addEventListener(
      'message',
      ((web.Event event) {
        final messageEvent = event as web.MessageEvent;
        final jsData = messageEvent.data;
        if (jsData == null) return;

        String dartData;
        try {
          if (jsData.typeofEquals('string')) {
            dartData = (jsData as JSString).toDart;
          } else {
            dartData = jsData.toString();
          }
        } catch (_) {
          return;
        }

        final registeredListeners = _listeners[id];
        if (registeredListeners == null || registeredListeners.isEmpty) return;

        // Copy the list in case a callback mutates registration.
        for (final entry in List<_ListenerEntry>.from(registeredListeners)) {
          entry.onPayload?.call(dartData);

          final decoder = entry.payloadDecoder ?? Tang0Channel.payloadDecoder;
          final decoded = decoder(dartData);
          if (decoded == null) continue;
          if (decoded.senderId == _globalIdentifier) continue;

          entry.callback(decoded.message);
        }
      }).toJS,
    );

    return dispose;
  }

  static void removeGListener(String id) {
    _listeners.remove(id);
    _wiredListenerIds.remove(id);
  }

  static void _localStorageCheck() {
    if (_globalIdentifier != null) return;

    // Sender id must be unique per tab/window so self-echo suppression
    // doesn't suppress other tabs.
    final storage = web.window.sessionStorage;
    const key = 'tang0_sender_1';

    var raw = storage.getItem(key);
    raw ??= base64UrlEncode(Uuid().v4().codeUnits);
    storage.setItem(key, raw);

    _globalIdentifier = String.fromCharCodes(base64Url.decode(raw));
  }
}
