import 'dart:async';

import '../../core/context.dart';

/// Thrown when leadership is requested but the environment has no Web Locks API.
/// tang0 fails loud here rather than silently downgrading to a weaker guarantee
/// (see [T0SoftLock] for an explicit best-effort alternative).
class T0LeaderUnavailable implements Exception {
  final String message;
  const T0LeaderUnavailable([this.message = 'navigator.locks is unavailable']);
  @override
  String toString() => 'T0LeaderUnavailable: $message';
}

/// A **true** single-leader election across all tabs of one origin, backed by
/// the Web Locks API (`navigator.locks`).
///
/// Exactly one tab holds the [scope] lock at a time. The lock is held for the
/// life of this object and released by [dispose] — or instantly by the browser
/// if the tab crashes, so there is no stale-leader window.
///
/// ## Honest guarantees
/// - [runIfLeader] / [withLeadership] are the real, callback-scoped API.
/// - [isLeader] is a **best-effort UI hint only** — leadership can change
///   between reading it and acting, so never gate critical work on it directly.
/// - If `navigator.locks` is absent, every method throws [T0LeaderUnavailable].
class T0Leader {
  final Tang0 context;
  final String scope;

  bool _isLeader = false;
  bool _disposed = false;
  final Completer<void> _release = Completer<void>();
  final StreamController<bool> _hint = StreamController<bool>.broadcast();

  T0Leader(this.scope, {Tang0? context}) : context = context ?? Tang0.instance {
    if (!available) return;
    // Hold the lock for life; release on dispose (or browser-released on crash).
    this.context.platform.locks.request<void>(
      'tang0.leader.$scope',
      ifAvailable: false,
      body: () async {
        if (_disposed) return;
        _setLeader(true);
        await _release.future;
        _setLeader(false);
      },
    );
  }

  /// Whether Web Locks exist in this environment.
  bool get available => context.platform.locks.available;

  /// Best-effort hint for UI. Do not gate critical work on this directly.
  bool get isLeader => _isLeader;

  /// Fires `true` when this tab becomes leader and `false` when it stops being.
  Stream<bool> get onLeadershipHint => _hint.stream;

  /// Run [body] only if this tab is currently the leader; otherwise no-op
  /// (returns `null`). Throws [T0LeaderUnavailable] when locks are unsupported.
  Future<T?> runIfLeader<T>(FutureOr<T> Function() body) async {
    if (!available) throw const T0LeaderUnavailable();
    if (!_isLeader) return null;
    return await body();
  }

  /// Wait until this tab is the leader, then run [body] while holding
  /// leadership. Resolves with [body]'s result. Throws [T0LeaderUnavailable]
  /// when locks are unsupported.
  Future<T> withLeadership<T>(FutureOr<T> Function() body) async {
    if (!available) throw const T0LeaderUnavailable();
    if (_isLeader) return await body();
    await onLeadershipHint.firstWhere((v) => v);
    return await body();
  }

  void _setLeader(bool value) {
    _isLeader = value;
    if (!_hint.isClosed) _hint.add(value);
  }

  void dispose() {
    _disposed = true;
    if (!_release.isCompleted) _release.complete();
    _hint.close();
  }
}
