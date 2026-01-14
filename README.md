# Tang0

A lightweight Flutter web package for cross-tab communication using the BroadcastChannel API.

## What it does

Tang0 provides composable primitives for synchronizing state and events between browser tabs—no crypto, no heavy widgets, just the essentials.

## Features

- **`Tang0Channel`** — BroadcastChannel wrapper with multi-listener support, payload hooks, and inner JSON mutators
- **`T0SyncVar<T>`** — `ValueNotifier`-based state sync across tabs with built-in codecs
- **`T0ReactiveStream<T>`** — `ChangeNotifier` + broadcast stream for cross-tab events
- **`T0DispatchPool`** — global rate limiter/queue with optional coalescing
- **`SyncEnum`** — control sync direction (`twoWay`, `uploadOnly`, `downloadOnly`, `uploadWithDelay`)
- **Codec registry** — built-in support for primitives, `DateTime`, `Uri`, and JSON maps/lists

## Installation

```yaml
dependencies:
  tang0: ^0.9.0
```

```bash
flutter pub add tang0
```

## Quick Start

### Synced State (T0SyncVar)

```dart
import 'package:tang0/tang0.dart';

// Create a synced counter (two-way by default)
final counter = T0SyncVar<int>(
  channelId: 'app_sync',
  key: 'counter',
  initialValue: 0,
);

// Use like a ValueNotifier
counter.value++;          // broadcasts to other tabs
counter.addListener(() => print(counter.value));

// Dispose when done
counter.dispose();
```

### One-Way Upload with Delay

```dart
final draft = T0SyncVar<String>(
  channelId: 'editor',
  key: 'draft',
  initialValue: '',
  mode: SyncEnum.uploadWithDelay,
  uploadDelay: Duration(milliseconds: 500),
);
```

### Event Stream (T0ReactiveStream)

```dart
final events = T0ReactiveStream<String>(
  channelId: 'app_events',
  key: 'toast',
);

events.stream.listen((msg) => showToast(msg));
events.add('Hello from another tab!');
```

### Custom Codec

```dart
class User {
  final int id;
  final String name;
  User(this.id, this.name);
}

class UserCodec extends SyncVarCodec<User> {
  @override
  Object? encode(User u) => {'id': u.id, 'name': u.name};

  @override
  User decode(Object? v) {
    final m = v as Map;
    return User(m['id'] as int, m['name'] as String);
  }
}

// Register globally
SyncVarCodecs.register<User>(UserCodec());

// Now you can sync User objects
final userVar = T0SyncVar<User>(
  channelId: 'users',
  key: 'current',
  initialValue: User(1, 'Alice'),
);
```

### JSON Hooks (Inner-rim Mutators)

```dart
// Inject a timestamp into every outgoing message
Tang0Channel.jsonOutbound = (map) => {...map, 'ts': DateTime.now().millisecondsSinceEpoch};

// Strip or transform incoming fields
Tang0Channel.jsonInbound = (map) {
  map.remove('debug');
  return map;
};
```

### Rate Limiting (T0DispatchPool)

```dart
T0DispatchPool.instance.configure(
  interval: Duration(milliseconds: 100),
  maxPerInterval: 20,
  maxQueueSize: 200,
);
```

## Example App

The `example/` folder contains two independent demos:

| Demo | Entrypoint | Description |
|------|------------|-------------|
| Timer | `lib/t0t_timer_main.dart` | Synced countdown timer with pause/resume across tabs |
| Tab Dedup | `lib/tab_dedup_main.dart` | Presence heartbeat; auto-close when > 4 tabs |

Run one of them:

```bash
cd example
flutter run -d chrome -t lib/t0t_timer_main.dart
```

> **Note:** The presets (`T0TTimer`, `T0TabDeduper`) are internal and not exported. They live in `lib/src/templates/` and are intended as reference implementations.

## Web Only

Tang0 relies on `BroadcastChannel`, which is only available in browsers. Mobile and desktop Flutter targets are not supported.

## License

MIT

