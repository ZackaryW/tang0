import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/context.dart';
import '../protocol/presence.dart';

/// Snapshot of the dedup group at one moment.
class T0TabDedupSnapshot {
  final String selfId;
  final List<T0Member> tabs;
  final int maxTabs;
  final int keepTabs;

  const T0TabDedupSnapshot({
    required this.selfId,
    required this.tabs,
    required this.maxTabs,
    required this.keepTabs,
  });

  int get tabCount => tabs.length;

  static int _createdAt(T0Member m) => (m.meta['createdAt'] as int?) ?? 0;

  /// The tabs that should stay open — the oldest [keepTabs], by creation time.
  List<T0Member> get keepers {
    final sorted = List<T0Member>.of(tabs)
      ..sort((a, b) {
        final c = _createdAt(a).compareTo(_createdAt(b));
        return c != 0 ? c : a.tabId.compareTo(b.tabId);
      });
    return sorted.take(keepTabs).toList(growable: false);
  }

  bool get selfIsKeeper => keepers.any((t) => t.tabId == selfId);
}

/// Cross-tab presence + dedup: when more than [maxTabs] tabs are open, every tab
/// outside the oldest [keepTabs] is asked to close.
///
/// Rebuilt on [T0Presence] for the live tab list. There is no default
/// window-closing behavior (it stays platform-agnostic and testable): observe
/// [closeRequested] or pass [onCloseRequested] to implement your strategy, e.g.
/// `web.window.close()` (which the browser may block unless the tab was opened
/// by script).
class T0TabDeduper extends ChangeNotifier {
  final Tang0 context;
  final int maxTabs;
  final int keepTabs;
  final FutureOr<void> Function(T0TabDedupSnapshot snapshot)? onCloseRequested;

  final T0Presence presence;
  bool _closeRequested = false;

  T0TabDeduper({
    String scope = 'tabs',
    Tang0? context,
    this.maxTabs = 4,
    this.keepTabs = 2,
    Duration? heartbeat,
    Duration? ttl,
    Map<String, dynamic>? meta,
    this.onCloseRequested,
  })  : assert(keepTabs >= 1, 'keepTabs must be >= 1'),
        context = context ?? Tang0.instance,
        presence = T0Presence(
          scope,
          context: context,
          heartbeat: heartbeat,
          ttl: ttl,
          meta: {
            ...?meta,
            'createdAt': (context ?? Tang0.instance).platform.clock.nowMs(),
          },
        ) {
    presence.addListener(_evaluate);
    _evaluate();
  }

  String get id => context.tabId;
  int get tabCount => presence.count;
  bool get closeRequested => _closeRequested;

  T0TabDedupSnapshot get snapshot => T0TabDedupSnapshot(
        selfId: context.tabId,
        tabs: presence.members,
        maxTabs: maxTabs,
        keepTabs: keepTabs,
      );

  void _evaluate() {
    notifyListeners();
    if (_closeRequested) return;
    if (presence.count <= maxTabs) return;
    final snap = snapshot;
    if (snap.selfIsKeeper) return;
    _closeRequested = true;
    notifyListeners();
    final handler = onCloseRequested;
    if (handler != null) Future.sync(() => handler(snap));
  }

  @override
  void dispose() {
    presence.removeListener(_evaluate);
    presence.dispose();
    super.dispose();
  }
}
