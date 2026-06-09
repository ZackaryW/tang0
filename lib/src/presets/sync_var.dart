import 'package:flutter/foundation.dart';

import '../codec/codec.dart';
import '../core/bus.dart';
import '../core/context.dart';
import '../core/store.dart';
import '../crdt/lww_register.dart';

/// A `ValueNotifier` whose value stays in sync across tabs, with deterministic
/// last-write-wins conflict resolution and new-tab catch-up.
///
/// - Setting [value] broadcasts it (coalesced, so rapid edits don't flood).
/// - Concurrent writes from two tabs converge via [T0LwwRegister] ordering.
/// - A new tab reads the last persisted value immediately and asks peers for the
///   current one, so it never starts blank.
class T0SyncVar<T> extends ValueNotifier<T> {
  final Tang0 context;
  final String scope;
  final String key;
  final T0Codec<T> codec;
  final bool persist;

  final T0Bus _bus;
  final T0Store _store;
  late final T0LwwRegister<T> _reg;
  late final void Function() _offSync;
  late final void Function() _offReq;
  bool _applyingRemote = false;

  T0SyncVar({
    required this.scope,
    required this.key,
    required T initialValue,
    Tang0? context,
    T0Codec<T>? codec,
    this.persist = true,
  })  : context = context ?? Tang0.instance,
        codec = codec ?? T0Codecs.getWithDefaults<T>(),
        _bus = T0Bus('tang0.sv.$scope', context: context),
        _store = T0Store((context ?? Tang0.instance).platform.local),
        super(initialValue) {
    _reg = T0LwwRegister<T>(initialValue, origin: this.context.tabId);
    _offSync = _bus.on('sv', _onRemote);
    _offReq = _bus.on('req', _onReq);
    _restoreFromStore();
    // Ask peers for the live value; the lone-tab case already used the store.
    _bus.send('req', {'k': key}, rateLimited: false);
  }

  int get _now => context.platform.clock.nowMs();
  String get _storeKey => 'sv.$scope.$key';

  @override
  set value(T newValue) {
    super.value = newValue;
    if (_applyingRemote) return;
    _reg.localSet(newValue, ts: _now, origin: context.tabId);
    _broadcast();
    _persist();
  }

  /// Set the value without broadcasting to other tabs.
  void setLocalOnly(T newValue) => super.value = newValue;

  void _broadcast() {
    _bus.send('sv', {
      'k': key,
      'v': codec.encode(_reg.value),
      'ver': _reg.version,
      'ts': _reg.ts,
      'o': _reg.origin,
    }, coalesceKey: 'sv:$scope:$key');
  }

  void _onReq(Object? data, String sender) {
    if (data is Map && data['k'] == key) _broadcast();
  }

  void _onRemote(Object? data, String sender) {
    if (data is! Map || data['k'] != key) return;
    final ver = data['ver'];
    final ts = data['ts'];
    final origin = data['o'];
    if (ver is! int || ts is! int || origin is! String) return;
    final applied = _reg.merge(
      codec.decode(data['v']),
      version: ver,
      ts: ts,
      origin: origin,
    );
    if (!applied) return;
    _applyingRemote = true;
    super.value = _reg.value;
    _applyingRemote = false;
    _persist();
  }

  void _restoreFromStore() {
    if (!persist) return;
    final raw = _store.readJson(_storeKey);
    if (raw == null) return;
    final ver = raw['ver'];
    final ts = raw['ts'];
    final origin = raw['o'];
    if (ver is! int || ts is! int || origin is! String) return;
    final applied = _reg.merge(
      codec.decode(raw['v']),
      version: ver,
      ts: ts,
      origin: origin,
    );
    if (applied) setLocalOnly(_reg.value);
  }

  void _persist() {
    if (!persist) return;
    _store.writeJson(_storeKey, {
      'v': codec.encode(_reg.value),
      'ver': _reg.version,
      'ts': _reg.ts,
      'o': _reg.origin,
    });
  }

  @override
  void dispose() {
    _offSync();
    _offReq();
    _bus.dispose();
    super.dispose();
  }
}
