import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:web/web.dart' as web;

import '../src/channel.dart';
import '../src/dispatchPool.dart';

class T0TabPresence {
  final String id;
  final DateTime createdAt;
  DateTime lastSeenAt;
  Map<String, dynamic> meta;

  T0TabPresence({
    required this.id,
    required this.createdAt,
    required this.lastSeenAt,
    required this.meta,
  });
}

class T0TabDedupSnapshot {
  final T0TabPresence self;
  final List<T0TabPresence> tabs;
  final int maxTabs;
  final int keepTabs;

  const T0TabDedupSnapshot({
    required this.self,
    required this.tabs,
    required this.maxTabs,
    required this.keepTabs,
  });

  int get tabCount => tabs.length;

  /// Tabs that should remain open, picked by oldest creation time.
  List<T0TabPresence> get keepers {
    final sorted = List<T0TabPresence>.from(tabs)
      ..sort((a, b) {
        final c = a.createdAt.compareTo(b.createdAt);
        if (c != 0) return c;
        return a.id.compareTo(b.id);
      });
    return sorted.take(keepTabs).toList(growable: false);
  }

  bool get selfIsKeeper => keepers.any((t) => t.id == self.id);
}

/// Cross-tab presence + dedup preset.
///
/// Each tab generates a per-tab UUID and periodically broadcasts:
/// - uuid
/// - creationDate
/// - lastSeen timestamp
/// - optional meta
///
/// If more than [maxTabs] tabs are present, tabs not in the oldest [keepTabs]
/// set will request closure.
///
/// Note: Browser security restrictions may prevent `window.close()` unless the
/// tab was opened by script. Provide [onCloseRequested] to implement a custom
/// strategy.
class T0TabDeduper extends ChangeNotifier {
  static const String channelId = 'tang0.tabs';

  final Duration heartbeat;
  final Duration ttl;
  final int maxTabs;
  final int keepTabs;

  final FutureOr<void> Function(T0TabDedupSnapshot snapshot)? onCloseRequested;

  late final T0TabPresence _self;
  final Map<String, T0TabPresence> _tabs = <String, T0TabPresence>{};

  late final void Function() _disposeListener;
  Timer? _heartbeatTimer;
  bool _closeRequested = false;

  T0TabDeduper({
    Duration? heartbeat,
    Duration? ttl,
    this.maxTabs = 4,
    this.keepTabs = 2,
    Map<String, dynamic>? meta,
    this.onCloseRequested,
  }) : heartbeat = heartbeat ?? const Duration(seconds: 2),
       ttl = ttl ?? const Duration(seconds: 8) {
    assert(keepTabs >= 1, 'keepTabs must be >= 1');

    final now = DateTime.now();
    final session = web.window.sessionStorage;

    const idKey = 'tang0_tab_id';
    const createdKey = 'tang0_tab_createdAtMs';

    final id = session.getItem(idKey) ?? const Uuid().v4();
    session.setItem(idKey, id);

    final createdMsRaw = session.getItem(createdKey);
    final createdAt = createdMsRaw == null
        ? now
        : DateTime.fromMillisecondsSinceEpoch(int.parse(createdMsRaw));
    session.setItem(createdKey, createdAt.millisecondsSinceEpoch.toString());

    _self = T0TabPresence(
      id: id,
      createdAt: createdAt,
      lastSeenAt: now,
      meta: meta ?? <String, dynamic>{},
    );

    _tabs[_self.id] = _self;

    _disposeListener = Tang0Channel.addGListener(channelId, _handleMessage);
    _heartbeatTimer = Timer.periodic(this.heartbeat, (_) => _tick());

    // Kick once immediately.
    _tick();
  }

  String get id => _self.id;
  DateTime get createdAt => _self.createdAt;

  Map<String, dynamic> get meta => Map<String, dynamic>.from(_self.meta);

  void updateMeta(Map<String, dynamic> newMeta) {
    _self.meta = Map<String, dynamic>.from(newMeta);
    notifyListeners();
  }

  int get tabCount => _tabs.length;

  List<T0TabPresence> get tabs {
    final list = _tabs.values.toList(growable: false)
      ..sort((a, b) {
        final c = a.createdAt.compareTo(b.createdAt);
        if (c != 0) return c;
        return a.id.compareTo(b.id);
      });
    return list;
  }

  bool get closeRequested => _closeRequested;

  T0TabDedupSnapshot get snapshot => T0TabDedupSnapshot(
    self: _self,
    tabs: tabs,
    maxTabs: maxTabs,
    keepTabs: keepTabs,
  );

  void _tick() {
    final now = DateTime.now();

    _self.lastSeenAt = now;
    _tabs[_self.id] = _self;

    _prune(now);
    _broadcast(now);
    _evaluateDedup();

    notifyListeners();
  }

  void _broadcast(DateTime now) {
    T0DispatchPool.instance.enqueueJson(channelId, <String, dynamic>{
      't': 'tab',
      'id': _self.id,
      'createdAtMs': _self.createdAt.millisecondsSinceEpoch,
      'seenAtMs': now.millisecondsSinceEpoch,
      if (_self.meta.isNotEmpty) 'meta': Map<String, dynamic>.from(_self.meta),
    }, coalesceKey: 'tab:${_self.id}');
  }

  void _handleMessage(String message) {
    final decoded = Tang0Channel.tryDecodeJsonMessage(message);
    if (decoded == null) return;
    if (decoded['t'] != 'tab') return;

    final id = decoded['id'];
    final createdAtMs = decoded['createdAtMs'];
    final seenAtMs = decoded['seenAtMs'];
    if (id is! String || createdAtMs is! int || seenAtMs is! int) return;

    final now = DateTime.now();

    final presence = _tabs.putIfAbsent(
      id,
      () => T0TabPresence(
        id: id,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
        lastSeenAt: now,
        meta: <String, dynamic>{},
      ),
    );

    presence.lastSeenAt = DateTime.fromMillisecondsSinceEpoch(seenAtMs);

    final meta = decoded['meta'];
    if (meta is Map) {
      presence.meta = Map<String, dynamic>.from(meta);
    }

    notifyListeners();
  }

  void _prune(DateTime now) {
    _tabs.removeWhere((_, tab) => now.difference(tab.lastSeenAt) > ttl);
  }

  Future<void> _evaluateDedup() async {
    if (_closeRequested) return;
    if (_tabs.length <= maxTabs) return;

    final snap = snapshot;
    if (snap.selfIsKeeper) return;

    _closeRequested = true;
    notifyListeners();

    final handler = onCloseRequested ?? _defaultCloseRequested;
    await Future.sync(() => handler(snap));
  }

  static FutureOr<void> _defaultCloseRequested(T0TabDedupSnapshot snapshot) {
    // Best-effort. This may be blocked depending on browser rules.
    web.window.close();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _disposeListener();
    super.dispose();
  }
}
