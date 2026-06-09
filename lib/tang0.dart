/// tang0 — cross-tab sync & dedup primitives for Flutter web.
///
/// Layers: a platform surface (injectable for tests) → a typed bus + storage →
/// protocol primitives (presence, leader election, soft-lock, rpc, hydration) →
/// CRDT conflict resolution → ready-made presets (synced values, tab dedup,
/// shared drafts).
library;

// Platform (advanced / testing)
export 'src/platform/platform.dart';
export 'src/platform/web_platform.dart' show webPlatform;

// Core
export 'src/core/context.dart' show Tang0;
export 'src/core/identity.dart' show T0Identity;
export 'src/core/envelope.dart' show T0Envelope;
export 'src/core/bus.dart' show T0Bus;
export 'src/core/store.dart' show T0Store;
export 'src/core/dispatch_pool.dart' show T0DispatchPool;

// Codec
export 'src/codec/codec.dart'
    show T0Codec, T0Codecs, T0Encoder, T0Decoder, JsonMapCodec, JsonListCodec;

// Protocol primitives
export 'src/protocol/presence.dart' show T0Presence, T0Member;
export 'src/protocol/leader/leader.dart' show T0Leader, T0LeaderUnavailable;
export 'src/protocol/soft_lock.dart' show T0SoftLock;
export 'src/protocol/rpc.dart' show T0Rpc;
export 'src/protocol/hydration.dart' show T0Hydrator;

// CRDT
export 'src/crdt/lww_register.dart' show T0LwwRegister;

// Presets
export 'src/presets/sync_var.dart' show T0SyncVar;
export 'src/presets/reactive_stream.dart' show T0ReactiveStream;
export 'src/presets/tab_dedup.dart' show T0TabDeduper, T0TabDedupSnapshot;
export 'src/presets/shared_draft.dart' show T0SharedDraft;
