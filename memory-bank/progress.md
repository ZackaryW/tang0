# Progress

Legacy (SyncedWidget/crypto) progress is archived in `memory-bank/details/legacy_progress_2026-01-14.md`.

## Working Now
- `Tang0Channel`:
  - correct `BroadcastChannel.addEventListener('message', ...)` wiring
  - multiple listeners per channel id + per-listener disposer
  - outer payload override (`payloadEncoder`/`payloadDecoder`)
  - inner JSON map middleware (`jsonOutbound`/`jsonInbound`)
- `T0DispatchPool`: outbound rate limiting + bounded queue + optional coalescing
- `T0SyncVar<T>`: cross-tab `ValueNotifier<T>` with loop prevention, codecs, modes, and pooling
- `T0ReactiveStream<T>`: cross-tab event stream + notifier with modes and pooling

- Public exports are available via `lib/tang0.dart` (core primitives only)
- Internal presets exist (not exported): timer + tab dedup
- Example app is split into two separate demos

## Known Limitations
- Web-only; requires modern browsers with `BroadcastChannel`
- No automatic conflict resolution beyond “latest message wins”
- Cross-tab behavior is hard to unit-test (best validated in real browsers)

## Next Up
1. Update README to match new primitives (state + event + pooling + JSON hooks)
2. Decide on naming consistency for codec types
3. Decide whether presets remain internal or become public later
