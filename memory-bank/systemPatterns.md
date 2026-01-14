# System Patterns

Legacy (SyncedWidget/crypto) patterns are archived in `memory-bank/details/legacy_systemPatterns_2026-01-14.md`.

## Architecture

### Layering
```
[T0SyncVar / T0ReactiveStream]  ← user-facing primitives
              ↓
        [T0DispatchPool]        ← throttling/queue/coalescing
              ↓
          [Tang0Channel]        ← BroadcastChannel wrapper + hooks
              ↓
        [BroadcastChannel]      ← browser API
```

### File Organization
```
lib/src/
  channel.dart        # Tang0Channel + payload/json hooks + listener registry
  dispatchPool.dart   # T0DispatchPool
  syncVar.dart        # T0SyncVar<T> + codec registry
  reactiveStream.dart # T0ReactiveStream<T>
  syncEnum.dart       # SyncEnum
      templates/          # internal presets (NOT exported)
            t0t_timer.dart    # T0TTimer
            tab_dedup.dart    # T0TabDeduper
```

## Key Patterns

### Listener Registry + Disposer
- Multiple callbacks can subscribe to a channel id
- Registration returns a `void Function()` disposer for cleanup
- Under the hood there is only one native `addEventListener('message', ...)` per channel id

### Outer Envelope (payload override)
- `Tang0Channel.payloadEncoder(senderId, message)` builds the payload
- `Tang0Channel.payloadDecoder(payload)` parses it
- The parsed `senderId` is used to suppress self-echo

### Inner JSON “Rim” (map mutation)
- `Tang0Channel.jsonOutbound(Map)` runs before encoding/sending JSON maps
- `Tang0Channel.jsonInbound(Map)` runs after decoding/receiving JSON maps
- Used for injecting metadata, renaming keys, etc.

### Backpressure + Coalescing
- `T0DispatchPool` is the single outbound choke point
- Queue bounded by `maxQueueSize`
- Optional coalescing key lets you keep only “latest value” for a stream of updates

### Sync Modes
- `SyncEnum.uploadOnly` / `downloadOnly` for one-way flows
- `SyncEnum.uploadWithDelay` for debounced sends

## Preset Pattern (internal)
- Presets communicate via JSON over a shared channel id and a small `t` discriminator
- Presets should apply incoming state to local state (not just log/emit) when cross-tab coordination is intended
