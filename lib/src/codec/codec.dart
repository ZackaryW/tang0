// Value <-> JSON-safe codecs for synced types. Ported from the original
// T0SyncVar codec system, unchanged in behavior.

typedef T0Encoder<T> = Object? Function(T value);
typedef T0Decoder<T> = T Function(Object? value);

abstract class T0Codec<T> {
  const T0Codec();
  Object? encode(T value);
  T decode(Object? value);
}

class _IdentityCodec<T> extends T0Codec<T> {
  const _IdentityCodec();
  @override
  Object? encode(T value) => value as Object?;
  @override
  T decode(Object? value) => value as T;
}

class _DateTimeCodec extends T0Codec<DateTime> {
  const _DateTimeCodec();
  @override
  Object? encode(DateTime value) => value.toIso8601String();
  @override
  DateTime decode(Object? value) => DateTime.parse(value as String);
}

class _UriCodec extends T0Codec<Uri> {
  const _UriCodec();
  @override
  Object? encode(Uri value) => value.toString();
  @override
  Uri decode(Object? value) => Uri.parse(value as String);
}

class JsonMapCodec extends T0Codec<Map<String, dynamic>> {
  const JsonMapCodec();
  @override
  Object? encode(Map<String, dynamic> value) => value;
  @override
  Map<String, dynamic> decode(Object? value) =>
      Map<String, dynamic>.from(value as Map);
}

class JsonListCodec extends T0Codec<List<dynamic>> {
  const JsonListCodec();
  @override
  Object? encode(List<dynamic> value) => value;
  @override
  List<dynamic> decode(Object? value) => List<dynamic>.from(value as List);
}

/// Global registry of codecs by type, with a set of built-in defaults.
class T0Codecs {
  T0Codecs._();

  static final Map<Type, T0Codec<dynamic>> _registry = {};
  static bool _defaultsRegistered = false;

  static void register<T>(T0Codec<T> codec) => _registry[T] = codec;

  static T0Codec<T>? tryGet<T>() => _registry[T] as T0Codec<T>?;

  static T0Codec<T> get<T>() => tryGet<T>() ?? _IdentityCodec<T>();

  static void registerDefaults() {
    if (_defaultsRegistered) return;
    _defaultsRegistered = true;
    register<String>(const _IdentityCodec<String>());
    register<int>(const _IdentityCodec<int>());
    register<double>(const _IdentityCodec<double>());
    register<bool>(const _IdentityCodec<bool>());
    register<num>(const _IdentityCodec<num>());
    register<DateTime>(const _DateTimeCodec());
    register<Uri>(const _UriCodec());
  }

  static T0Codec<T> getWithDefaults<T>() {
    registerDefaults();
    return get<T>();
  }
}
