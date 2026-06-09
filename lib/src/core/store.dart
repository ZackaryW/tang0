import 'dart:convert';

import '../platform/platform.dart';

/// A namespaced JSON view over a [T0KeyValueStore] (local or session).
///
/// Keys are prefixed so unrelated app data is never touched, JSON is encoded
/// transparently, and [changes] surfaces only cross-tab writes under this prefix
/// (the browser `storage` event) — the backbone of new-tab state catch-up.
class T0Store {
  final T0KeyValueStore _kv;
  final String prefix;

  T0Store(this._kv, {this.prefix = 'tang0.'});

  String _k(String key) => '$prefix$key';

  String? readString(String key) => _kv.read(_k(key));
  void writeString(String key, String value) => _kv.write(_k(key), value);
  void remove(String key) => _kv.remove(_k(key));

  Map<String, dynamic>? readJson(String key) {
    final raw = readString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  void writeJson(String key, Object value) =>
      writeString(key, jsonEncode(value));

  /// Cross-tab changes to keys under this prefix. Each event's `key` is the
  /// un-prefixed logical key.
  Stream<T0StorageEvent> get changes => _kv.onExternalChange
      .where((e) => e.key.startsWith(prefix))
      .map((e) => T0StorageEvent(e.key.substring(prefix.length), e.newValue));
}
