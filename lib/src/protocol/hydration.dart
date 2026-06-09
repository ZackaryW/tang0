import 'dart:async';

import '../core/context.dart';
import '../core/store.dart';
import 'rpc.dart';

/// New-tab state catch-up: a freshly opened tab asks peers for the current
/// snapshot instead of starting blank.
///
/// Existing tabs register a snapshot provider via [provide]; a newcomer calls
/// [hydrate], which first asks peers over RPC and, if none answer (it is the
/// only tab), falls back to the last value [persist]ed in localStorage.
class T0Hydrator {
  final Tang0 context;
  final String scope;
  final T0Rpc _rpc;
  final T0Store _store;

  T0Hydrator(this.scope, {Tang0? context})
      : context = context ?? Tang0.instance,
        _rpc = T0Rpc('hydrate.$scope', context: context),
        _store = T0Store((context ?? Tang0.instance).platform.local);

  String get _key => 'hydrate.$scope';

  /// Answer peer hydrate requests with the live snapshot from [snapshot].
  void provide(FutureOr<Object?> Function() snapshot) {
    _rpc.answer('snapshot', (_) => snapshot());
  }

  /// Persist [snapshot] so a future lone tab can still catch up from storage.
  void persist(Object? snapshot) {
    if (snapshot == null) {
      _store.remove(_key);
    } else {
      _store.writeJson(_key, {'s': snapshot});
    }
  }

  /// Fetch the current snapshot: ask peers first, then fall back to storage.
  /// Returns `null` if nothing is available.
  Future<Object?> hydrate({
    Duration timeout = const Duration(milliseconds: 500),
  }) async {
    final peer = await _rpc.request('snapshot', timeout: timeout);
    if (peer != null) return peer;
    return _store.readJson(_key)?['s'];
  }

  void dispose() => _rpc.dispose();
}
