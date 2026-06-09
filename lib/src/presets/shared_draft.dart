import 'dart:async';

import 'package:flutter/foundation.dart';

import '../codec/codec.dart';
import '../core/context.dart';
import '../protocol/presence.dart';
import '../protocol/soft_lock.dart';
import 'sync_var.dart';

/// A shared editing session for one document across tabs — the pattern
/// `pathverse_portal` hand-rolls in its 500-line `SharedDraftSessionService`,
/// assembled here from tang0 primitives.
///
/// - [value] is a [T0SyncVar]: the draft syncs with LWW conflict resolution,
///   coalesced broadcasts, localStorage persistence, and new-tab catch-up.
/// - [presence] tracks which tabs currently have the draft open.
/// - [saveExclusive] uses a [T0SoftLock] so that when several tabs autosave at
///   once, only one actually writes to the server (best-effort, matching the
///   portal — a redundant idempotent save is cheap).
class T0SharedDraft<T> {
  final Tang0 context;
  final String draftId;

  final T0SyncVar<T> value;
  final T0Presence presence;
  final T0SoftLock _saveLock;

  T0SharedDraft({
    required this.draftId,
    required T initial,
    Tang0? context,
    T0Codec<T>? codec,
    Map<String, dynamic>? meta,
  })  : context = context ?? Tang0.instance,
        value = T0SyncVar<T>(
          scope: 'draft.$draftId',
          key: 'doc',
          initialValue: initial,
          context: context,
          codec: codec,
        ),
        presence = T0Presence('draft.$draftId', context: context, meta: meta),
        _saveLock = T0SoftLock('draft.$draftId', context: context);

  /// Current draft contents.
  T get draft => value.value;

  /// Update the draft — syncs, persists, and coalesces rapid edits.
  set draft(T next) => value.value = next;

  void addListener(VoidCallback listener) => value.addListener(listener);
  void removeListener(VoidCallback listener) => value.removeListener(listener);

  /// Whether another tab currently has this draft open.
  bool get otherTabsPresent => presence.count > 1;

  /// The tabs currently editing this draft.
  List<T0Member> get editors => presence.members;

  /// Run [persist] only if this tab wins the save lease. Returns whether this
  /// tab performed the save; other racing tabs get `false` and skip.
  Future<bool> saveExclusive(FutureOr<void> Function(T draft) persist) async {
    if (!await _saveLock.tryHold()) return false;
    try {
      await persist(value.value);
      return true;
    } finally {
      _saveLock.release();
    }
  }

  void dispose() {
    value.dispose();
    presence.dispose();
    _saveLock.dispose();
  }
}
