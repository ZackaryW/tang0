# Active Context

This Memory Bank has been updated to match the post-revamp Tang0 scope (no crypto/SyncedWidget). Legacy docs are in `memory-bank/details/legacy_*`.

## Current Focus
- Keep the package small and web-only while making the primitives ergonomic
- Finalize a stable public API surface (exports + naming)
- Ensure docs reflect current architecture and hooks

## Recent Changes
- Fixed `BroadcastChannel` JS interop wiring and message conversion
- Added multi-listener support per channel id (disposer-based cleanup)
- Added payload override hooks (outer envelope) and inner JSON mutators
- Added cross-tab primitives:
  - `T0SyncVar<T>` (state)
  - `T0ReactiveStream<T>` (events)
- Added `T0DispatchPool` for rate limiting/queueing and optional coalescing

- Added public export surface in `lib/tang0.dart`
- Added internal presets under `lib/src/templates/`:
  - `T0TTimer` (timer state broadcast)
  - `T0TabDeduper` (tab presence + dedup)
- Split the example app into two independent demos (one per preset)
- Fixed timer preset so PAUSE/RESUME propagates by applying remote state (not just emitting events)

## Next Steps
1. Update README with examples for `T0SyncVar`, `T0ReactiveStream`, pooling, and JSON hooks
3. Decide if codec names should also be prefixed (`SyncVarCodec` → `T0SyncVarCodec`) for consistency
4. Keep presets internal unless/until they stabilize
