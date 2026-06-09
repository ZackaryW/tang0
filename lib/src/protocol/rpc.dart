import 'dart:async';

import 'package:uuid/uuid.dart';

import '../core/bus.dart';
import '../core/context.dart';

/// Lightweight request/response over a bus: one tab asks, peer tabs answer.
///
/// Useful for "who has the auth token?", "send me the current state", etc.
/// Requests carry a correlation id; the first matching response wins.
class T0Rpc {
  final T0Bus _bus;
  final Map<String, Completer<Object?>> _pending = {};
  final Map<String, FutureOr<Object?> Function(Object? params)> _handlers = {};
  late final void Function() _offReq;
  late final void Function() _offRes;

  T0Rpc(String scope, {Tang0? context})
      : _bus = T0Bus('tang0.rpc.$scope', context: context) {
    _offReq = _bus.on('req', _onRequest);
    _offRes = _bus.on('res', _onResponse);
  }

  /// Register a handler that answers [method] requests from other tabs.
  void answer(String method, FutureOr<Object?> Function(Object? params) handler) {
    _handlers[method] = handler;
  }

  /// Ask peers to handle [method]; resolves with the first response, or `null`
  /// if none arrives before [timeout].
  Future<Object?> request(
    String method, {
    Object? params,
    Duration timeout = const Duration(seconds: 2),
  }) {
    final id = const Uuid().v4();
    final completer = Completer<Object?>();
    _pending[id] = completer;
    _bus.send('req', {'id': id, 'm': method, 'p': params}, rateLimited: false);
    return completer.future.timeout(timeout, onTimeout: () {
      _pending.remove(id);
      return null;
    });
  }

  void _onRequest(Object? data, String sender) async {
    if (data is! Map) return;
    final method = data['m'];
    final id = data['id'];
    if (method is! String || id is! String) return;
    final handler = _handlers[method];
    if (handler == null) return;
    final result = await handler(data['p']);
    _bus.send('res', {'id': id, 'r': result}, rateLimited: false);
  }

  void _onResponse(Object? data, String sender) {
    if (data is! Map) return;
    final id = data['id'];
    if (id is! String) return;
    final completer = _pending.remove(id);
    if (completer != null && !completer.isCompleted) completer.complete(data['r']);
  }

  void dispose() {
    _offReq();
    _offRes();
    _bus.dispose();
    for (final c in _pending.values) {
      if (!c.isCompleted) c.complete(null);
    }
    _pending.clear();
  }
}
