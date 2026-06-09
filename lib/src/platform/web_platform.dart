/// Real browser implementation of [T0Platform] over `package:web`.
///
/// This is the only file in the library that touches `package:web` /
/// `dart:js_interop` directly. Everything else depends on the abstract surface
/// in `platform.dart`, which keeps the protocol logic browser-free and testable.
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'platform.dart';

/// Build the production platform bound to the current browser window.
T0Platform webPlatform() => T0Platform(
  clock: const _WallClock(),
  local: _WebStore(web.window.localStorage, listenExternal: true),
  session: _WebStore(web.window.sessionStorage, listenExternal: false),
  channels: _WebChannelFactory(),
  locks: const _WebLockManager(),
);

class _WallClock implements T0Clock {
  const _WallClock();
  @override
  int nowMs() => DateTime.now().millisecondsSinceEpoch;
}

class _WebStore implements T0KeyValueStore {
  final web.Storage _storage;
  StreamController<T0StorageEvent>? _controller;

  _WebStore(this._storage, {required bool listenExternal}) {
    if (!listenExternal) return;
    final controller = _controller = StreamController<T0StorageEvent>.broadcast();
    final zone = Zone.current;
    web.window.addEventListener(
      'storage',
      (web.Event event) {
        final e = event as web.StorageEvent;
        final key = e.key;
        if (key == null) return; // a full clear()
        zone.run(() => controller.add(T0StorageEvent(key, e.newValue)));
      }.toJS,
    );
  }

  @override
  String? read(String key) => _storage.getItem(key);

  @override
  void write(String key, String value) => _storage.setItem(key, value);

  @override
  void remove(String key) => _storage.removeItem(key);

  @override
  Stream<T0StorageEvent> get onExternalChange =>
      _controller?.stream ?? const Stream.empty();
}

class _WebChannelFactory implements T0ChannelFactory {
  final Map<String, _WebRawChannel> _open = {};

  @override
  T0RawChannel open(String id) =>
      _open.putIfAbsent(id, () => _WebRawChannel(id));
}

class _WebRawChannel implements T0RawChannel {
  final web.BroadcastChannel _ch;
  final StreamController<String> _controller = StreamController<String>.broadcast();
  final Zone _zone = Zone.current;

  _WebRawChannel(String id) : _ch = web.BroadcastChannel(id) {
    _ch.onmessage = (web.MessageEvent event) {
      final data = event.data;
      if (data == null || !data.isA<JSString>()) return;
      final str = (data as JSString).toDart;
      // Re-enter the Dart zone captured at construction; the raw browser
      // callback runs in a bare JS zone (the cause of `window.dart:99` asserts).
      _zone.run(() {
        if (!_controller.isClosed) _controller.add(str);
      });
    }.toJS;
  }

  @override
  void post(String data) => _ch.postMessage(data.toJS);

  @override
  Stream<String> get messages => _controller.stream;

  @override
  void close() {
    _ch.close();
    _controller.close();
  }
}

class _WebLockManager implements T0LockManager {
  const _WebLockManager();

  @override
  bool get available {
    try {
      return web.window.navigator.has('locks');
    } catch (_) {
      return false;
    }
  }

  @override
  Future<T?> request<T>(
    String name, {
    required bool ifAvailable,
    required FutureOr<T> Function() body,
  }) {
    final completer = Completer<T?>();

    JSPromise<JSAny?>? granted(web.Lock? lock) {
      if (lock == null) {
        // ifAvailable: lock is held elsewhere — do not run body.
        completer.complete(null);
        return null;
      }
      final held = Future<T>.sync(body).then((value) {
        if (!completer.isCompleted) completer.complete(value);
        return null;
      }).catchError((Object e, StackTrace st) {
        if (!completer.isCompleted) completer.completeError(e, st);
        return null;
      });
      // Holding the returned promise keeps the lock until body settles.
      return held.toJS;
    }

    final options = web.LockOptions(mode: 'exclusive', ifAvailable: ifAvailable);
    web.window.navigator.locks.request(name, options, granted.toJS);
    return completer.future;
  }
}
