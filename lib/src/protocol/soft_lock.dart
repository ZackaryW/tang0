import 'dart:async';

import 'package:uuid/uuid.dart';

import '../core/context.dart';
import '../core/store.dart';

/// An **advisory** cross-tab lease over localStorage — explicitly *not* a true
/// leader. This is the portal's proven "save-lock" pattern (write your id, wait
/// a short election window, check you still own it), hardened with a generation
/// token and a heartbeat so a crashed holder's lease eventually expires.
///
/// ## Honest guarantees
/// localStorage has no cross-tab atomic compare-and-swap, so two tabs racing in
/// the same election window can *both* briefly believe they hold the lease.
/// Use this only where a transient double-holder is cheap (e.g. a redundant,
/// idempotent autosave). For real mutual exclusion use [T0Leader].
class T0SoftLock {
  final Tang0 context;
  final String scope;
  final Duration lease;
  final Duration electionWindow;

  final T0Store _store;
  bool _held = false;
  String? _gen;
  Timer? _heartbeat;

  T0SoftLock(
    this.scope, {
    Tang0? context,
    Duration? lease,
    Duration? electionWindow,
  })  : context = context ?? Tang0.instance,
        lease = lease ?? const Duration(seconds: 6),
        electionWindow = electionWindow ?? const Duration(milliseconds: 150),
        _store = T0Store((context ?? Tang0.instance).platform.local);

  String get _key => 'softlock.$scope';
  int get _now => context.platform.clock.nowMs();
  String get _tabId => context.tabId;

  bool get held => _held;

  /// Attempt to acquire the lease. Returns whether this tab now holds it.
  Future<bool> tryHold() async {
    final current = _store.readJson(_key);
    final fresh = current != null &&
        (_now - (current['ts'] as int? ?? 0)) < lease.inMilliseconds;
    if (fresh && current['owner'] != _tabId) return false;

    final gen = const Uuid().v4();
    _gen = gen;
    _write(gen);

    if (electionWindow > Duration.zero) await Future.delayed(electionWindow);

    final after = _store.readJson(_key);
    if (after != null && after['gen'] == gen) {
      _held = true;
      _startHeartbeat();
      return true;
    }
    _held = false;
    return false;
  }

  void release() {
    _heartbeat?.cancel();
    _heartbeat = null;
    if (_held) {
      final current = _store.readJson(_key);
      if (current != null && current['gen'] == _gen) _store.remove(_key);
    }
    _held = false;
    _gen = null;
  }

  void _write(String gen) =>
      _store.writeJson(_key, {'owner': _tabId, 'gen': gen, 'ts': _now});

  void _startHeartbeat() {
    _heartbeat?.cancel();
    final period = Duration(milliseconds: lease.inMilliseconds ~/ 2);
    _heartbeat = Timer.periodic(period, (_) {
      if (_held && _gen != null) _write(_gen!);
    });
  }

  void dispose() => release();
}
