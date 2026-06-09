import 'dart:async';

import 'package:flutter/foundation.dart';

import '../codec/codec.dart';
import '../core/bus.dart';
import '../core/context.dart';

/// A cross-tab event stream: events added in one tab surface in every tab.
///
/// Unlike [T0SyncVar] there is no retained state or conflict resolution — it is
/// a fire-and-forget broadcast of discrete events. Emits locally via [stream]
/// and notifies listeners on every local emit or remote receive.
class T0ReactiveStream<T> extends ChangeNotifier {
  final Tang0 context;
  final String scope;
  final String key;
  final T0Codec<T> codec;
  final bool coalesceLatest;

  final T0Bus _bus;
  final StreamController<T> _controller = StreamController<T>.broadcast(sync: true);
  late final void Function() _off;

  /// Most recent event seen (local or remote).
  T? last;

  T0ReactiveStream({
    required this.scope,
    required this.key,
    Tang0? context,
    T0Codec<T>? codec,
    this.coalesceLatest = false,
  })  : context = context ?? Tang0.instance,
        codec = codec ?? T0Codecs.getWithDefaults<T>(),
        _bus = T0Bus('tang0.rs.$scope', context: context) {
    _off = _bus.on('rs', _onRemote);
  }

  Stream<T> get stream => _controller.stream;

  /// Emit [event] locally and broadcast it to other tabs.
  void add(T event) {
    _emitLocal(event);
    _bus.send(
      'rs',
      {'k': key, 'v': codec.encode(event)},
      coalesceKey: coalesceLatest ? 'rs:$scope:$key' : null,
    );
  }

  /// Emit [event] locally only.
  void addLocalOnly(T event) => _emitLocal(event);

  void _emitLocal(T event) {
    last = event;
    if (!_controller.isClosed) _controller.add(event);
    notifyListeners();
  }

  void _onRemote(Object? data, String sender) {
    if (data is! Map || data['k'] != key) return;
    _emitLocal(codec.decode(data['v']));
  }

  @override
  void dispose() {
    _off();
    _bus.dispose();
    _controller.close();
    super.dispose();
  }
}
