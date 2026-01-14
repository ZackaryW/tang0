// ignore_for_file: file_names

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'channel.dart';
import 'dispatchPool.dart';
import 'syncEnum.dart';
import 'syncVar.dart';

/// A cross-tab event stream that notifies listeners on incoming/outgoing events.
///
/// - Emits events locally via [stream]
/// - Broadcasts events to other tabs via [Tang0Channel]
/// - Calls [notifyListeners] whenever an event is received or emitted
class T0ReactiveStream<T> extends ChangeNotifier {
  final String channelId;
  final String key;
  final SyncVarEncoder<T> _encode;
  final SyncVarDecoder<T> _decode;
  final void Function(Object error, StackTrace stackTrace)? onError;

  final SyncEnum mode;
  final Duration uploadDelay;
  final bool coalesceLatest;

  final StreamController<T> _controller;
  late final void Function() _disposeListener;
  Timer? _uploadTimer;

  /// Most recent event observed (local emit or remote receive).
  T? last;

  T0ReactiveStream({
    required this.channelId,
    required this.key,
    this.mode = SyncEnum.twoWay,
    Duration? uploadDelay,
    this.coalesceLatest = false,
    SyncVarCodec<T>? codec,
    SyncVarEncoder<T>? encode,
    SyncVarDecoder<T>? decode,
    this.onError,
  }) : uploadDelay = uploadDelay ?? const Duration(milliseconds: 250),
       _encode = encode ?? (codec ?? SyncVarCodecs.getWithDefaults<T>()).encode,
       _decode = decode ?? (codec ?? SyncVarCodecs.getWithDefaults<T>()).decode,
       _controller = StreamController<T>.broadcast(sync: true) {
    if (_canReceive) {
      _disposeListener = Tang0Channel.addGListener(channelId, _handleMessage);
    } else {
      _disposeListener = () {};
    }
  }

  Stream<T> get stream => _controller.stream;

  bool get _canReceive =>
      mode == SyncEnum.twoWay || mode == SyncEnum.downloadOnly;

  bool get _canSend =>
      mode == SyncEnum.twoWay ||
      mode == SyncEnum.uploadOnly ||
      mode == SyncEnum.uploadWithDelay;

  bool get _useDelayedUpload => mode == SyncEnum.uploadWithDelay;

  /// Emit an event locally and (depending on [mode]) broadcast to other tabs.
  void add(T event) {
    _emitLocal(event);

    if (!_canSend) return;

    if (_useDelayedUpload) {
      _uploadTimer?.cancel();
      _uploadTimer = Timer(uploadDelay, () => _sendPayload(event));
      return;
    }

    _sendPayload(event);
  }

  /// Emit an event locally without broadcasting to other tabs.
  void addLocalOnly(T event) {
    _emitLocal(event);
  }

  void _emitLocal(T event) {
    last = event;
    if (!_controller.isClosed) {
      _controller.add(event);
    }
    notifyListeners();
  }

  void _sendPayload(T event) {
    try {
      T0DispatchPool.instance.enqueueJson(channelId, <String, dynamic>{
        't': 'rs',
        'k': key,
        'v': _encode(event),
      }, coalesceKey: coalesceLatest ? 'rs:$channelId:$key' : null);
    } catch (e, st) {
      onError?.call(e, st);
    }
  }

  void _handleMessage(String message) {
    if (!_canReceive) return;

    try {
      final decoded = Tang0Channel.tryDecodeJsonMessage(message);
      if (decoded == null) return;
      if (decoded['t'] != 'rs') return;
      if (decoded['k'] != key) return;

      final event = _decode(decoded['v']);
      _emitLocal(event);
    } catch (e, st) {
      onError?.call(e, st);
    }
  }

  @override
  void dispose() {
    _uploadTimer?.cancel();
    _disposeListener();
    _controller.close();
    super.dispose();
  }
}
