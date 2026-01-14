// ignore_for_file: file_names

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'channel.dart';

class _QueuedSend {
  final String channelId;
  final String message;

  const _QueuedSend({required this.channelId, required this.message});
}

/// Global rate limiter + queue for outgoing cross-tab messages.
///
/// This prevents high-frequency updates from flooding BroadcastChannel.
///
/// - Sends at most [maxPerInterval] messages every [interval]
/// - Queues additional sends up to [maxQueueSize]
/// - Supports coalescing via [coalesceKey] (keeps latest only)
class T0DispatchPool {
  T0DispatchPool._();

  static final T0DispatchPool instance = T0DispatchPool._();

  Duration interval = const Duration(milliseconds: 50);
  int maxPerInterval = 50;
  int maxQueueSize = 500;

  int _tokens = 0;
  Timer? _timer;
  int _seq = 0;

  final LinkedHashMap<String, _QueuedSend> _pending =
      LinkedHashMap<String, _QueuedSend>();

  void configure({Duration? interval, int? maxPerInterval, int? maxQueueSize}) {
    if (interval != null) this.interval = interval;
    if (maxPerInterval != null) this.maxPerInterval = maxPerInterval;
    if (maxQueueSize != null) this.maxQueueSize = maxQueueSize;

    _restartTimer();
  }

  void enqueue(String channelId, String message, {String? coalesceKey}) {
    _ensureTimer();

    // Fast path: no backlog, we still have budget.
    if (_pending.isEmpty && _tokens > 0) {
      _tokens--;
      Tang0Channel(channelId).send(message);
      return;
    }

    final key = coalesceKey ?? 'seq:${_seq++}';

    if (coalesceKey != null && _pending.containsKey(key)) {
      // Replace and move to the end to reflect newest value.
      _pending.remove(key);
    }

    _pending[key] = _QueuedSend(channelId: channelId, message: message);

    while (_pending.length > maxQueueSize) {
      _pending.remove(_pending.keys.first);
    }

    _flush();
  }

  void enqueueJson(
    String channelId,
    Map<String, dynamic> json, {
    String? coalesceKey,
  }) {
    final outbound = Tang0Channel.jsonOutbound(Map<String, dynamic>.from(json));
    enqueue(channelId, jsonEncode(outbound), coalesceKey: coalesceKey);
  }

  void _ensureTimer() {
    _timer ??= Timer.periodic(interval, (_) {
      _tokens = maxPerInterval;
      _flush();
    });

    if (_tokens == 0) {
      _tokens = maxPerInterval;
    }
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = null;
    _tokens = 0;
    _ensureTimer();
  }

  void _flush() {
    while (_tokens > 0 && _pending.isNotEmpty) {
      final firstKey = _pending.keys.first;
      final next = _pending.remove(firstKey);
      if (next == null) continue;

      _tokens--;
      Tang0Channel(next.channelId).send(next.message);
    }
  }
}
