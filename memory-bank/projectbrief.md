# Tang0 Project Brief

Tang0 is a Flutter Web package that provides small, composable primitives for cross-tab communication using the browser `BroadcastChannel` API.

Legacy (pre-revamp) docs are archived in `memory-bank/details/legacy_*`.

## Core Purpose
- Provide a clean Dart API over `BroadcastChannel`
- Support two common cross-tab needs:
	- state sync (a “shared variable”)
	- event sync (a “shared stream”)
- Stay lightweight: minimal deps and minimal opinionated UI

## Key Requirements
- **Web-first**: works in modern browsers supporting `BroadcastChannel`
- **Extensible payloads**: override outer envelope parsing and mutate inner JSON maps
- **Backpressure**: avoid flooding via a central dispatch pool (rate limit + queue + optional coalescing)
- **Lifecycle-safe**: listeners return disposers for cleanup
- **Type-friendly**: built-in codec mapping for common Dart types

## Non-Goals
- Cryptographic signing/encryption (removed from the new scope)
- Multi-platform (mobile/desktop) support
- Conflict resolution for concurrent edits (last-write-wins semantics by default)
- Persistence (localStorage is used only for per-tab identity)

## Public Surface (current)
- `Tang0Channel`: channel wrapper + listener registry + payload/JSON hooks
- `T0SyncVar<T>`: `ValueNotifier<T>` that broadcasts updates across tabs
- `T0ReactiveStream<T>`: `ChangeNotifier` + broadcast stream for event-style sync
- `T0DispatchPool`: shared throttling/coalescing for outbound messages
- `SyncEnum`: sync modes (`twoWay`, `uploadOnly`, `downloadOnly`, `uploadWithDelay`)
- `SyncVarCodec<T>` / `SyncVarCodecs`: type ↔ codec registry

## Internal Presets (not exported)
Presets live under `lib/src/templates/` and are intentionally not part of the public API:
- `T0TTimer`: a lightweight cross-tab timer “presence” broadcast (SYNC/PAUSE/RESUME/END)
- `T0TabDeduper`: a cross-tab heartbeat + dedup helper (keep oldest N tabs)

## Success Criteria
- Dev can sync a value/event across tabs in a few lines
- No JS interop footguns for consumers
- Rate-limited by default under high-frequency updates
- Clear README examples and stable API names
