import 'dart:async';
import 'dart:collection';

import '../platform/platform.dart';

class _QueuedSend {
  final String channelId;
  final String message;
  const _QueuedSend({required this.channelId, required this.message});
}

/// Rate limiter + coalescing queue for outgoing cross-tab messages, so
/// high-frequency updates never flood a BroadcastChannel.
///
/// - sends at most [maxPerInterval] messages every [interval]
/// - queues the rest up to [maxQueueSize] (oldest dropped past the cap)
/// - a [coalesceKey] keeps only the latest pending message for that key
///
/// Ported from the original `T0DispatchPool`, but routes through an injected
/// [T0ChannelFactory] instead of a global channel singleton.
class T0DispatchPool {
  final T0ChannelFactory _channels;

  Duration interval;
  int maxPerInterval;
  int maxQueueSize;

  int _tokens = 0;
  Timer? _timer;
  int _seq = 0;

  final LinkedHashMap<String, _QueuedSend> _pending =
      LinkedHashMap<String, _QueuedSend>();

  T0DispatchPool(
    this._channels, {
    this.interval = const Duration(milliseconds: 50),
    this.maxPerInterval = 50,
    this.maxQueueSize = 500,
  });

  void enqueue(String channelId, String message, {String? coalesceKey}) {
    _ensureTimer();

    if (_pending.isEmpty && _tokens > 0) {
      _tokens--;
      _channels.open(channelId).post(message);
      return;
    }

    final key = coalesceKey ?? 'seq:${_seq++}';
    if (coalesceKey != null && _pending.containsKey(key)) {
      _pending.remove(key); // replace + move to newest position
    }
    _pending[key] = _QueuedSend(channelId: channelId, message: message);

    while (_pending.length > maxQueueSize) {
      _pending.remove(_pending.keys.first);
    }
    _flush();
  }

  void _ensureTimer() {
    _timer ??= Timer.periodic(interval, (_) {
      _tokens = maxPerInterval;
      _flush();
    });
    if (_tokens == 0) _tokens = maxPerInterval;
  }

  void _flush() {
    while (_tokens > 0 && _pending.isNotEmpty) {
      final firstKey = _pending.keys.first;
      final next = _pending.remove(firstKey);
      if (next == null) continue;
      _tokens--;
      _channels.open(next.channelId).post(next.message);
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _pending.clear();
  }
}
