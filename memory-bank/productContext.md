# Product Context

## Problem
Cross-tab communication in Flutter web is useful but annoying to implement well:
- `BroadcastChannel` is low-level (serialization, routing, cleanup)
- High-frequency state changes can flood other tabs
- You often want both “shared state” and “shared events”
- Teams want hooks to shape payloads without forking the library

## Why Tang0 Exists
Tang0 provides a thin, extensible layer:
- `Tang0Channel` wraps `BroadcastChannel` and standardizes payload handling
- `T0SyncVar<T>` provides state sync as a `ValueNotifier<T>`
- `T0ReactiveStream<T>` provides event sync as a notifier + stream
- `T0DispatchPool` provides backpressure so updates don’t spam

## Target Users
- Flutter web developers who want cross-tab sync without re-writing plumbing
- Apps that need rate-limited updates (typing, drag, sliders, progress)

## Core Workflows

### Workflow: Shared state
1. Create a `T0SyncVar<T>` with a `channelId` and `key`
2. Update `.value` locally
3. Tang0 broadcasts JSON updates; other tabs apply them
4. Self-echo is suppressed using a per-tab sender id

### Workflow: Shared events
1. Create a `T0ReactiveStream<T>`
2. Call `add(value)` to emit locally and broadcast
3. Other tabs receive and emit into their local stream

### Workflow: Custom payload shaping
- Override outer envelope via `Tang0Channel.payloadEncoder`/`payloadDecoder`
- Mutate inner JSON maps via `Tang0Channel.jsonOutbound`/`jsonInbound`

### Workflow: Presets (internal)
- Timer preset broadcasts a minimal state snapshot every 5 seconds and can pause/resume/end across tabs
- Tab-dedup preset broadcasts tab presence (uuid, createdAt, lastSeen, meta) and requests closure when over a threshold

## UX Goals
- Simple defaults; advanced hooks optional
- Predictable behavior under load (pooling/coalescing)
- Easy cleanup (disposer functions)
