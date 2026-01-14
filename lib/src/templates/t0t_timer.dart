import 'dart:async';

import '../channel.dart';
import '../dispatchPool.dart';

/// Tang0 Timer preset (T0T).
///
/// Sends lightweight periodic state updates and lifecycle events over a shared
/// channel. This file is intentionally *not* exported from `package:tang0/tang0.dart`.
///
/// Message commands:
/// - `T0T_{serial}_SYNC`  (every [syncInterval])
/// - `T0T_{serial}_PAUSE`
/// - `T0T_{serial}_RESUME`
/// - `T0T_{serial}_END`
class T0TTimer {
  static const String channelId = 'tang0.t0t';

  final String serial;
  final Duration syncInterval;
  final Duration? duration;

  /// Optional user metadata merged into outgoing messages under `meta`.
  final Map<String, dynamic> meta;

  final StreamController<Map<String, dynamic>> _events =
      StreamController<Map<String, dynamic>>.broadcast(sync: true);

  late final void Function() _disposeListener;
  Timer? _syncTimer;
  bool _ended = false;

  DateTime _startedAt;
  DateTime? _pausedAt;
  Duration _pausedTotal = Duration.zero;

  T0TTimer({
    required this.serial,
    this.duration,
    Duration? syncInterval,
    Map<String, dynamic>? meta,
    bool listen = true,
  }) : syncInterval = syncInterval ?? const Duration(seconds: 5),
       meta = meta ?? <String, dynamic>{},
       _startedAt = DateTime.now() {
    if (listen) {
      _disposeListener = Tang0Channel.addGListener(channelId, _handleMessage);
    } else {
      _disposeListener = () {};
    }

    _startPeriodicSync();
  }

  Stream<Map<String, dynamic>> get events => _events.stream;

  bool get isPaused => _pausedAt != null;
  bool get isEnded => _ended;

  DateTime get startedAt => _startedAt;

  /// Elapsed time excluding pauses.
  Duration get elapsed {
    final now = DateTime.now();
    return _computeElapsed(now);
  }

  Duration? get remaining {
    if (duration == null) return null;
    final r = duration! - elapsed;
    return r.isNegative ? Duration.zero : r;
  }

  void reset({DateTime? startAt}) {
    _ended = false;
    _pausedAt = null;
    _pausedTotal = Duration.zero;
    _startedAt = startAt ?? DateTime.now();
    _startPeriodicSync();
    sync();
  }

  void pause() {
    if (_ended) return;
    if (_pausedAt != null) return;

    _pausedAt = DateTime.now();
    _send(kind: 'PAUSE', coalesce: false);
  }

  void resume() {
    if (_ended) return;
    final pausedAt = _pausedAt;
    if (pausedAt == null) return;

    _pausedTotal += DateTime.now().difference(pausedAt);
    _pausedAt = null;
    _send(kind: 'RESUME', coalesce: false);
  }

  void end() {
    if (_ended) return;
    _ended = true;
    _syncTimer?.cancel();
    _send(kind: 'END', coalesce: false);
  }

  /// Manually send a SYNC state update.
  void sync() {
    if (_ended) return;
    _send(kind: 'SYNC', coalesce: true);
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    if (_ended) return;

    _syncTimer = Timer.periodic(syncInterval, (_) => sync());
  }

  Duration _computeElapsed(DateTime now) {
    final pausedAt = _pausedAt;
    final pausedSoFar = pausedAt == null
        ? Duration.zero
        : now.difference(pausedAt);
    final totalPaused = _pausedTotal + pausedSoFar;
    return now.difference(_startedAt) - totalPaused;
  }

  int? _forecastEndEpochMs(DateTime now) {
    if (duration == null) return null;

    // Forecast end time includes already accumulated pauses and (if currently
    // paused) assumes pause ends at `now`.
    final elapsedNow = _computeElapsed(now);
    final remainingNow = duration! - elapsedNow;
    final clamped = remainingNow.isNegative ? Duration.zero : remainingNow;
    return now.add(clamped).millisecondsSinceEpoch;
  }

  Map<String, dynamic> _snapshot(String kind) {
    final now = DateTime.now();

    return <String, dynamic>{
      't': 't0t',
      'serial': serial,
      'cmd': 'T0T_${serial}_$kind',
      'kind': kind,
      'nowMs': now.millisecondsSinceEpoch,
      'startMs': _startedAt.millisecondsSinceEpoch,
      'paused': _pausedAt != null,
      'pauseMs': _pausedAt?.millisecondsSinceEpoch,
      'pausedTotalMs': _pausedTotal.inMilliseconds,
      'elapsedMs': _computeElapsed(now).inMilliseconds,
      'durationMs': duration?.inMilliseconds,
      'remainingMs': remaining?.inMilliseconds,
      'forecastEndMs': _forecastEndEpochMs(now),
      if (meta.isNotEmpty) 'meta': Map<String, dynamic>.from(meta),
    };
  }

  void _send({required String kind, required bool coalesce}) {
    final payload = _snapshot(kind);

    // Emit locally for consumers in this tab.
    if (!_events.isClosed) {
      _events.add(payload);
    }

    T0DispatchPool.instance.enqueueJson(
      channelId,
      payload,
      coalesceKey: coalesce ? 't0t:$serial' : null,
    );
  }

  void _handleMessage(String message) {
    final decoded = Tang0Channel.tryDecodeJsonMessage(message);
    if (decoded == null) return;
    if (decoded['t'] != 't0t') return;
    if (decoded['serial'] != serial) return;

    _applyRemote(decoded);

    if (!_events.isClosed) {
      _events.add(decoded);
    }
  }

  void _applyRemote(Map<String, dynamic> decoded) {
    // Keep this intentionally tolerant: missing fields simply don't update.
    final startMs = decoded['startMs'];
    if (startMs is int) {
      _startedAt = DateTime.fromMillisecondsSinceEpoch(startMs);
    }

    final pausedTotalMs = decoded['pausedTotalMs'];
    if (pausedTotalMs is int) {
      _pausedTotal = Duration(milliseconds: pausedTotalMs);
    }

    final paused = decoded['paused'];
    final pauseMs = decoded['pauseMs'];
    if (paused is bool) {
      if (paused) {
        if (pauseMs is int) {
          _pausedAt = DateTime.fromMillisecondsSinceEpoch(pauseMs);
        } else {
          // Best-effort: if pause timestamp missing, treat as "paused now".
          _pausedAt ??= DateTime.now();
        }
      } else {
        _pausedAt = null;
      }
    }

    final kind = decoded['kind'];
    if (kind == 'END') {
      _ended = true;
      _syncTimer?.cancel();
      return;
    }

    // If we were ended locally but a non-END message arrives, keep ended.
    if (_ended) return;

    // Ensure periodic sync is active (especially after reset-like state sync).
    _startPeriodicSync();
  }

  void dispose() {
    _syncTimer?.cancel();
    _disposeListener();
    _events.close();
  }
}
