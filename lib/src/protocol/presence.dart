import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/bus.dart';
import '../core/context.dart';

/// A peer tab known to the presence group.
class T0Member {
  final String tabId;
  Map<String, dynamic> meta;
  int lastSeenMs;
  final bool isSelf;

  T0Member({
    required this.tabId,
    required this.meta,
    required this.lastSeenMs,
    this.isSelf = false,
  });
}

/// Live "who else has this app open" awareness for a [scope], with per-tab
/// metadata (cursor, name, status — whatever you put in [meta]).
///
/// Each tab heartbeats on a shared bus; members not heard from within [ttl] are
/// pruned (covers crashed tabs). A freshly opened tab announces itself and every
/// existing tab replies, so the newcomer learns the full group immediately —
/// no waiting for the next heartbeat.
class T0Presence extends ChangeNotifier {
  static const _kBeat = 'beat';
  static const _kJoin = 'join';
  static const _kLeave = 'leave';

  final Tang0 context;
  final String scope;
  final Duration heartbeat;
  final Duration ttl;

  late final T0Bus _bus;
  late final T0Member _self;
  final Map<String, T0Member> _members = {};
  late final void Function() _off;
  Timer? _timer;

  T0Presence(
    this.scope, {
    Tang0? context,
    Duration? heartbeat,
    Duration? ttl,
    Map<String, dynamic>? meta,
  })  : context = context ?? Tang0.instance,
        heartbeat = heartbeat ?? const Duration(seconds: 2),
        ttl = ttl ?? const Duration(seconds: 6) {
    _bus = T0Bus('tang0.presence.$scope', context: this.context);
    _self = T0Member(
      tabId: this.context.tabId,
      meta: meta ?? {},
      lastSeenMs: _now,
      isSelf: true,
    );
    _members[_self.tabId] = _self;
    _off = _bus.on(_kBeat, _onBeat);
    _bus.on(_kJoin, _onJoin);
    _bus.on(_kLeave, _onLeave);
    _timer = Timer.periodic(this.heartbeat, (_) => beat());
    _announce();
  }

  int get _now => context.platform.clock.nowMs();

  /// All members including self, oldest-first by id for a stable order.
  List<T0Member> get members {
    final list = _members.values.toList()
      ..sort((a, b) => a.tabId.compareTo(b.tabId));
    return list;
  }

  int get count => _members.length;

  T0Member get self => _self;

  /// Replace this tab's advertised metadata and broadcast it.
  void updateMeta(Map<String, dynamic> meta) {
    _self.meta = Map<String, dynamic>.from(meta);
    beat();
  }

  /// Emit a heartbeat now, prune stale members, and notify listeners.
  void beat() {
    _self.lastSeenMs = _now;
    _bus.send(_kBeat, _beatData, coalesceKey: 'presence:$scope:${_self.tabId}');
    _prune();
    notifyListeners();
  }

  void _announce() {
    _bus.send(_kJoin, _beatData);
    notifyListeners();
  }

  Map<String, dynamic> get _beatData => {
        'id': _self.tabId,
        'meta': _self.meta,
        'ts': _self.lastSeenMs,
      };

  void _onJoin(Object? data, String sender) {
    _absorb(data);
    // Reply directly so the newcomer learns us without waiting a full heartbeat.
    _bus.send(_kBeat, _beatData);
  }

  void _onBeat(Object? data, String sender) => _absorb(data);

  void _onLeave(Object? data, String sender) {
    if (data is Map && data['id'] is String) {
      _members.remove(data['id']);
      _prune();
      notifyListeners();
    }
  }

  void _absorb(Object? data) {
    if (data is! Map) return;
    final id = data['id'];
    if (id is! String || id == _self.tabId) return;
    final member = _members.putIfAbsent(
      id,
      () => T0Member(tabId: id, meta: {}, lastSeenMs: _now),
    );
    member.lastSeenMs = _now;
    final meta = data['meta'];
    if (meta is Map) member.meta = Map<String, dynamic>.from(meta);
    _prune();
    notifyListeners();
  }

  void _prune() {
    final cutoff = _now - ttl.inMilliseconds;
    _members.removeWhere((id, m) => !m.isSelf && m.lastSeenMs < cutoff);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bus.send(_kLeave, {'id': _self.tabId}, rateLimited: false);
    _off();
    _bus.dispose();
    super.dispose();
  }
}
