// ignore_for_file: file_names

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'channel.dart';
import 'dispatchPool.dart';
import 'syncEnum.dart';

typedef SyncVarEncoder<T> = Object? Function(T value);
typedef SyncVarDecoder<T> = T Function(Object? value);

abstract class SyncVarCodec<T> {
  const SyncVarCodec();
  Object? encode(T value);
  T decode(Object? value);
}

class _IdentityCodec<T> extends SyncVarCodec<T> {
  const _IdentityCodec();

  @override
  Object? encode(T value) => value as Object?;

  @override
  T decode(Object? value) => value as T;
}

class SyncVarCodecs {
  SyncVarCodecs._();

  static final Map<Type, SyncVarCodec<dynamic>> _registry =
      <Type, SyncVarCodec<dynamic>>{};
  static bool _defaultsRegistered = false;

  static void register<T>(SyncVarCodec<T> codec) {
    _registry[T] = codec;
  }

  static SyncVarCodec<T>? tryGet<T>() {
    final codec = _registry[T];
    if (codec == null) return null;
    return codec as SyncVarCodec<T>;
  }

  static SyncVarCodec<T> get<T>() {
    return tryGet<T>() ?? _IdentityCodec<T>();
  }

  /// Register common codecs (safe to call multiple times).
  static void registerDefaults() {
    if (_defaultsRegistered) return;
    _defaultsRegistered = true;

    register<String>(const _IdentityCodec<String>());
    register<int>(const _IdentityCodec<int>());
    register<double>(const _IdentityCodec<double>());
    register<bool>(const _IdentityCodec<bool>());
    register<num>(const _IdentityCodec<num>());

    register<DateTime>(_DateTimeCodec());
    register<Uri>(_UriCodec());
  }

  static SyncVarCodec<T> getWithDefaults<T>() {
    registerDefaults();
    return get<T>();
  }
}

class _DateTimeCodec extends SyncVarCodec<DateTime> {
  const _DateTimeCodec();

  @override
  Object? encode(DateTime value) => value.toIso8601String();

  @override
  DateTime decode(Object? value) => DateTime.parse(value as String);
}

class _UriCodec extends SyncVarCodec<Uri> {
  const _UriCodec();

  @override
  Object? encode(Uri value) => value.toString();

  @override
  Uri decode(Object? value) => Uri.parse(value as String);
}

class JsonMapCodec extends SyncVarCodec<Map<String, dynamic>> {
  const JsonMapCodec();

  @override
  Object? encode(Map<String, dynamic> value) => value;

  @override
  Map<String, dynamic> decode(Object? value) =>
      Map<String, dynamic>.from(value as Map);
}

class JsonListCodec extends SyncVarCodec<List<dynamic>> {
  const JsonListCodec();

  @override
  Object? encode(List<dynamic> value) => value;

  @override
  List<dynamic> decode(Object? value) => List<dynamic>.from(value as List);
}

class T0SyncVar<T> extends ValueNotifier<T> {
  final String channelId;
  final String key;
  final SyncVarEncoder<T> _encode;
  final SyncVarDecoder<T> _decode;
  final void Function(Object error, StackTrace stackTrace)? onError;
  final SyncEnum mode;
  final Duration uploadDelay;

  late final void Function() _disposeListener;
  bool _applyingRemote = false;
  Timer? _uploadTimer;

  T0SyncVar({
    required this.channelId,
    required this.key,
    required T initialValue,
    this.mode = SyncEnum.twoWay,
    Duration? uploadDelay,
    SyncVarCodec<T>? codec,
    SyncVarEncoder<T>? encode,
    SyncVarDecoder<T>? decode,
    this.onError,
  }) : uploadDelay = uploadDelay ?? const Duration(milliseconds: 250),
       _encode = encode ?? (codec ?? SyncVarCodecs.getWithDefaults<T>()).encode,
       _decode = decode ?? (codec ?? SyncVarCodecs.getWithDefaults<T>()).decode,
       super(initialValue) {
    if (_canReceive) {
      _disposeListener = Tang0Channel.addGListener(channelId, _handleMessage);
    } else {
      _disposeListener = () {};
    }
  }

  /// Convenience: register a codec for `T` globally.
  ///
  /// Example:
  /// `T0SyncVar.registerCodec<User>(UserCodec());`
  static void registerCodec<T>(SyncVarCodec<T> codec) {
    SyncVarCodecs.register<T>(codec);
  }

  @override
  set value(T newValue) {
    super.value = newValue;
    if (_applyingRemote) return;
    _broadcast(newValue);
  }

  bool get _canReceive =>
      mode == SyncEnum.twoWay || mode == SyncEnum.downloadOnly;

  bool get _canSend =>
      mode == SyncEnum.twoWay ||
      mode == SyncEnum.uploadOnly ||
      mode == SyncEnum.uploadWithDelay;

  bool get _useDelayedUpload => mode == SyncEnum.uploadWithDelay;

  /// Sets the value without broadcasting to other tabs.
  void setLocalOnly(T newValue) {
    super.value = newValue;
  }

  void _broadcast(T newValue) {
    if (!_canSend) return;

    if (_useDelayedUpload) {
      _uploadTimer?.cancel();
      _uploadTimer = Timer(uploadDelay, () => _sendPayload(newValue));
      return;
    }

    _sendPayload(newValue);
  }

  void _sendPayload(T value) {
    try {
      T0DispatchPool.instance.enqueueJson(channelId, <String, dynamic>{
        't': 'sv',
        'k': key,
        'v': _encode(value),
      }, coalesceKey: 'sv:$channelId:$key');
    } catch (e, st) {
      onError?.call(e, st);
    }
  }

  void _handleMessage(String message) {
    try {
      final decoded = Tang0Channel.tryDecodeJsonMessage(message);
      if (decoded == null) return;
      if (decoded['t'] != 'sv') return;
      if (decoded['k'] != key) return;
      if (!_canReceive) return;

      _applyingRemote = true;
      super.value = _decode(decoded['v']);
      _applyingRemote = false;
    } catch (e, st) {
      _applyingRemote = false;
      onError?.call(e, st);
    }
  }

  @override
  void dispose() {
    _uploadTimer?.cancel();
    _disposeListener();
    super.dispose();
  }
}
