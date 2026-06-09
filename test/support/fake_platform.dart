/// In-memory [T0Platform] that simulates several browser tabs sharing one
/// origin: one BroadcastChannel space, one localStorage, per-tab sessionStorage,
/// and one Web-Locks registry. Lets the protocol be unit-tested in pure Dart.
library;

import 'dart:async';

import 'package:tang0/src/platform/platform.dart';

/// The shared origin. Spawn tabs with [tab]; advance time with [advance].
class FakeHub {
  final _ManualClock _clock = _ManualClock();
  final Map<String, String> _local = {};
  final Map<String, List<_FakeChannelEnd>> _channelEnds = {};
  final Map<String, _LockQueue> _locks = {};
  final List<_FakeLocalStore> _localStores = [];

  bool locksAvailable = true;

  int get nowMs => _clock.nowMs();

  void advance(int ms) => _clock._now += ms;

  /// A new tab with stable [tabId], wired to this hub.
  FakeTab tab(String tabId) => FakeTab._(this, tabId);

  // ── localStorage (shared) ──────────────────────────────────────────────
  void _localWrite(String key, String value, _FakeLocalStore origin) {
    final changed = _local[key] != value;
    _local[key] = value;
    if (changed) _notifyOthers(key, value, origin);
  }

  void _localRemove(String key, _FakeLocalStore origin) {
    if (!_local.containsKey(key)) return;
    _local.remove(key);
    _notifyOthers(key, null, origin);
  }

  void _notifyOthers(String key, String? value, _FakeLocalStore origin) {
    for (final s in _localStores) {
      if (identical(s, origin)) continue;
      s._emit(T0StorageEvent(key, value));
    }
  }

  // ── locks ──────────────────────────────────────────────────────────────
  Future<T?> _requestLock<T>(
    String name,
    bool ifAvailable,
    FutureOr<T> Function() body,
  ) {
    final q = _locks.putIfAbsent(name, () => _LockQueue());
    if (q.held && ifAvailable) return Future<T?>.value(null);
    final completer = Completer<T?>();
    q.waiters.add(() async {
      try {
        completer.complete(await body());
      } catch (e, st) {
        if (!completer.isCompleted) completer.completeError(e, st);
      }
    });
    q.pump();
    return completer.future;
  }
}

/// One simulated tab; exposes a ready-to-use [T0Platform].
class FakeTab {
  final FakeHub hub;
  final String tabId;
  late final T0Platform platform;

  FakeTab._(this.hub, this.tabId) {
    final local = _FakeLocalStore(hub);
    hub._localStores.add(local);
    platform = T0Platform(
      clock: hub._clock,
      local: local,
      session: _FakeSessionStore(),
      channels: _FakeChannelFactory(hub, tabId),
      locks: _FakeLocks(hub),
    );
  }
}

class _ManualClock implements T0Clock {
  int _now = 0;
  @override
  int nowMs() => _now;
}

class _FakeLocalStore implements T0KeyValueStore {
  final FakeHub hub;
  final StreamController<T0StorageEvent> _controller =
      StreamController<T0StorageEvent>.broadcast();

  _FakeLocalStore(this.hub);

  @override
  String? read(String key) => hub._local[key];
  @override
  void write(String key, String value) => hub._localWrite(key, value, this);
  @override
  void remove(String key) => hub._localRemove(key, this);
  @override
  Stream<T0StorageEvent> get onExternalChange => _controller.stream;

  void _emit(T0StorageEvent e) {
    if (!_controller.isClosed) _controller.add(e);
  }
}

class _FakeSessionStore implements T0KeyValueStore {
  final Map<String, String> _data = {};
  @override
  String? read(String key) => _data[key];
  @override
  void write(String key, String value) => _data[key] = value;
  @override
  void remove(String key) => _data.remove(key);
  @override
  Stream<T0StorageEvent> get onExternalChange => const Stream.empty();
}

class _FakeChannelFactory implements T0ChannelFactory {
  final FakeHub hub;
  final String tabId;
  final Map<String, _FakeChannelEnd> _open = {};

  _FakeChannelFactory(this.hub, this.tabId);

  @override
  T0RawChannel open(String id) =>
      _open.putIfAbsent(id, () => _FakeChannelEnd(hub, id, tabId));
}

class _FakeChannelEnd implements T0RawChannel {
  final FakeHub hub;
  final String id;
  final String tabId;
  final StreamController<String> _controller =
      StreamController<String>.broadcast();
  bool _closed = false;

  _FakeChannelEnd(this.hub, this.id, this.tabId) {
    hub._channelEnds.putIfAbsent(id, () => []).add(this);
  }

  @override
  void post(String data) {
    for (final end in hub._channelEnds[id] ?? const <_FakeChannelEnd>[]) {
      if (identical(end, this) || end._closed) continue;
      // Deliver asynchronously, like a real BroadcastChannel.
      scheduleMicrotask(() {
        if (!end._closed) end._controller.add(data);
      });
    }
  }

  @override
  Stream<String> get messages => _controller.stream;

  @override
  void close() {
    _closed = true;
    hub._channelEnds[id]?.remove(this);
    _controller.close();
  }
}

class _FakeLocks implements T0LockManager {
  final FakeHub hub;
  _FakeLocks(this.hub);

  @override
  bool get available => hub.locksAvailable;

  @override
  Future<T?> request<T>(
    String name, {
    required bool ifAvailable,
    required FutureOr<T> Function() body,
  }) =>
      hub._requestLock<T>(name, ifAvailable, body);
}

class _LockQueue {
  bool held = false;
  final List<Future<void> Function()> waiters = [];

  void pump() {
    if (held || waiters.isEmpty) return;
    held = true;
    final run = waiters.removeAt(0);
    run().whenComplete(() {
      held = false;
      pump();
    });
  }
}
