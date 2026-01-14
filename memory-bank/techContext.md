# Tech Context

Legacy (crypto-era) context is archived in `memory-bank/details/legacy_techContext_2026-01-14.md`.

## Stack
- Dart SDK: `^3.8.1`
- Flutter: web target
- Browser API: `BroadcastChannel`

## Dependencies (current)
- `web`: JS interop + DOM bindings (BroadcastChannel, MessageEvent, localStorage)
- `uuid`: id generation

## Web APIs Used
- `BroadcastChannel`: cross-tab messaging (same-origin)
- `window.sessionStorage`: stores a per-tab sender id (used for self-echo suppression)

## Constraints
- Web-only (BroadcastChannel is not available on mobile/desktop Flutter)
- Manual testing required for multi-tab behavior
- Messages should be small (JSON strings); avoid sending large blobs

## Useful Commands
- `flutter analyze`
- `flutter test`
- `flutter run -d chrome`

## Example App
- `example/` is a separate Flutter app with two demo entrypoints
	- `flutter run -d chrome -t lib/t0t_timer_main.dart`
	- `flutter run -d chrome -t lib/tab_dedup_main.dart`

## Interop Notes
- Incoming payloads arrive as `MessageEvent.data` (`JSAny?`)
- Tang0 treats string payloads as the canonical path
- Listener wiring uses `BroadcastChannel.addEventListener('message', ...)`
