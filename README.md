# tang0

Cross-tab **sync & dedup primitives** for Flutter web. tang0 turns the fiddly,
copy-pasted patterns of multi-tab coordination — "who else is here", "only one
tab does this", "merge concurrent edits", "catch a new tab up" — into small,
composable, tested building blocks over `BroadcastChannel` and the Web Locks API.

Web-only. No crypto, no heavy widgets, no code generation.

## Why

Every non-trivial web app eventually hand-rolls cross-tab logic: a localStorage
presence heartbeat here, a "save-lock" race there, a versioned last-write-wins
merge, a localStorage read to hydrate a fresh tab. It's subtle (Zone capture,
self-echo, stale leaders) and gets duplicated across features. tang0 provides the
primitives once, correctly, with honest guarantees.

## Layers

```
Presets      T0SyncVar · T0ReactiveStream · T0TabDeduper · T0SharedDraft
Protocol     T0Presence · T0Leader · T0SoftLock · T0Rpc · T0Hydrator
CRDT         T0LwwRegister
Core         T0Bus · T0Store · T0DispatchPool · T0Identity · T0Envelope
Platform     T0Platform (injectable: clock, storage, channel, Web Locks)
```

The platform surface is injectable, so the whole protocol is unit-tested in pure
Dart against an in-memory fake that simulates several tabs — no browser needed.

## Quick start

```dart
import 'package:tang0/tang0.dart';

// A value that stays in sync across tabs (last-write-wins + catch-up):
final counter = T0SyncVar<int>(scope: 'app', key: 'counter', initialValue: 0);
counter.value++;                       // broadcasts, persists, coalesces
counter.addListener(() => print(counter.value));

// Who else has the app open, with awareness metadata:
final presence = T0Presence('app', meta: {'name': 'Ada'});
presence.addListener(() => print('${presence.count} tabs'));

// Elect ONE tab to own a resource (true mutex via Web Locks):
final leader = T0Leader('socket');
await leader.runIfLeader(() => openWebSocket());   // no-op on non-leaders
```

## Leader election: honest guarantees

tang0 deliberately splits two different needs instead of fusing them behind one
misleading API:

- **`T0Leader`** — a **true mutex** backed by `navigator.locks`. Exactly one tab
  holds leadership; the browser releases it instantly if that tab crashes.
  `runIfLeader` / `withLeadership` are the real API; `isLeader` is a best-effort
  UI hint only. If Web Locks are unavailable it **fails loud** rather than
  silently degrading.
- **`T0SoftLock`** — an explicitly **advisory** localStorage lease for cases where
  a transient double-holder is cheap (e.g. a redundant idempotent autosave). It
  never calls itself a leader.

## Presets

- **`T0SyncVar<T>`** — synced `ValueNotifier` with LWW conflict resolution and
  new-tab catch-up.
- **`T0ReactiveStream<T>`** — fire-and-forget cross-tab events.
- **`T0TabDeduper`** — keep the oldest N tabs, ask the rest to close.
- **`T0SharedDraft<T>`** — a shared editing session (synced draft + presence +
  best-effort save coordination), the shape real apps hand-roll in hundreds of
  lines.

## Example

```bash
cd example && flutter run -d chrome
```

Open the URL in several tabs to watch leadership, a synced counter, presence, and
tab-dedup react live.

## Testing

```bash
flutter test --platform chrome
```

tang0 is web-only, so its tests run under headless Chrome (the real target),
driving the protocol through the in-memory fake platform for deterministic
multi-tab scenarios.
