import 'dart:async';

import '../platform/platform.dart';
import 'context.dart';
import 'envelope.dart';

/// A typed publish/subscribe pipe over one BroadcastChannel.
///
/// Multiplexes many logical message [type]s on a single channel id, suppresses
/// self-echo by sender id, and routes high-frequency sends through the shared
/// [T0DispatchPool]. Messages are delivered cross-tab only (a tab never receives
/// its own posts — share state directly within a tab).
class T0Bus {
  final String channelId;
  final Tang0 context;

  final T0RawChannel _raw;
  final Map<String, List<void Function(Object? data, String sender)>> _listeners =
      {};
  StreamSubscription<String>? _sub;
  bool _wired = false;

  T0Bus(this.channelId, {Tang0? context})
      : context = context ?? Tang0.instance,
        _raw = (context ?? Tang0.instance).platform.channels.open(channelId);

  String get senderId => context.tabId;

  /// Send [data] under [type]. With a [coalesceKey], only the latest pending
  /// message for that key survives the dispatch queue.
  void send(String type, Object? data, {String? coalesceKey, bool rateLimited = true}) {
    final payload = T0Envelope(sender: senderId, type: type, data: data).encode();
    if (rateLimited) {
      context.pool.enqueue(channelId, payload, coalesceKey: coalesceKey);
    } else {
      _raw.post(payload);
    }
  }

  /// Subscribe to messages of [type] from other tabs. Returns a disposer.
  void Function() on(
    String type,
    void Function(Object? data, String sender) handler,
  ) {
    _ensureWired();
    final list = _listeners.putIfAbsent(type, () => []);
    list.add(handler);
    return () {
      list.remove(handler);
      if (list.isEmpty) _listeners.remove(type);
    };
  }

  void _ensureWired() {
    if (_wired) return;
    _wired = true;
    _sub = _raw.messages.listen(_dispatch);
  }

  void _dispatch(String raw) {
    final env = T0Envelope.tryDecode(raw);
    if (env == null) return;
    if (env.sender == senderId) return; // self-echo guard
    final handlers = _listeners[env.type];
    if (handlers == null) return;
    for (final h in List.of(handlers)) {
      h(env.data, env.sender);
    }
  }

  void dispose() {
    _sub?.cancel();
    _listeners.clear();
    _wired = false;
  }
}
