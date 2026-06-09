/// The injectable web surface tang0 builds on.
///
/// Every browser touch — clock, storage, BroadcastChannel, Web Locks — goes
/// through these interfaces instead of calling `package:web` directly. The real
/// implementation lives in `web_platform.dart`; tests inject an in-memory fake
/// that simulates several tabs sharing one channel and one storage, so the
/// protocol logic is unit-testable in pure Dart (no browser required).
library;

import 'dart:async';

/// Monotonic-ish wall clock in milliseconds since epoch.
abstract class T0Clock {
  int nowMs();
}

/// A change to a [T0KeyValueStore] originating in *another* tab.
class T0StorageEvent {
  final String key;
  final String? newValue;
  const T0StorageEvent(this.key, this.newValue);
}

/// A namespaced key/value store (localStorage or sessionStorage).
///
/// [onExternalChange] only fires for writes made by *other* tabs (the browser
/// `storage` event); same-tab writes never echo back. For sessionStorage it is
/// always an empty stream (sessionStorage is tab-private).
abstract class T0KeyValueStore {
  String? read(String key);
  void write(String key, String value);
  void remove(String key);
  Stream<T0StorageEvent> get onExternalChange;
}

/// A raw cross-tab message pipe (one BroadcastChannel).
///
/// [messages] delivers every message posted by *other* tabs on the same channel
/// id. Implementations must deliver in the Dart zone that was current when the
/// channel was opened (the real browser callback fires in a bare JS zone).
abstract class T0RawChannel {
  void post(String data);
  Stream<String> get messages;
  void close();
}

/// Opens raw channels, one shared instance per channel id.
abstract class T0ChannelFactory {
  T0RawChannel open(String id);
}

/// Web Locks API surface — a *true* mutex across all tabs of one origin/profile.
abstract class T0LockManager {
  /// Whether `navigator.locks` exists in this environment.
  bool get available;

  /// Acquire the exclusive lock [name], run [body] while holding it, release on
  /// completion. Mirrors `navigator.locks.request(name, {ifAvailable}, cb)`.
  ///
  /// When [ifAvailable] is true and the lock is already held elsewhere, [body]
  /// is **not** run and the future completes with `null`.
  Future<T?> request<T>(
    String name, {
    required bool ifAvailable,
    required FutureOr<T> Function() body,
  });
}

/// Bundle of the four web surfaces a tang0 component needs.
class T0Platform {
  final T0Clock clock;
  final T0KeyValueStore local;
  final T0KeyValueStore session;
  final T0ChannelFactory channels;
  final T0LockManager locks;

  const T0Platform({
    required this.clock,
    required this.local,
    required this.session,
    required this.channels,
    required this.locks,
  });
}
