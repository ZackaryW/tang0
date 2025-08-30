# Tang0

Simple cross-tab synchronization for Flutter web apps.

## What it does

Keep your app state synchronized between browser tabs automatically. Change a value in one tab, see it update in all other tabs instantly.

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:tang0/src/templates/synced_widget.dart';
import 'package:tang0/src/helper/synced_widget.dart';

// Super simple with helper methods
SyncedWidgetBuilder()
  .addCounter('score', 0)
  .addText('playerName', 'Player 1') 
  .addToggle('gameActive', true)
  .build((context, vars) {
    final score = vars[0] as SyncedVar<int>;
    final name = vars[1] as SyncedVar<String>;
    final active = vars[2] as SyncedVar<bool>;
    
    return Column(children: [
      score.controls(title: 'Score'),           // Built-in +/- buttons
      name.textField(label: 'Player Name'),     // Auto-syncing text field  
      active.switch_(title: 'Game Active'),     // Auto-syncing switch
    ]);
  });
```

## Features

- **Zero setup**: Just wrap your variables and they sync automatically
- **Secure**: All messages are cryptographically signed
- **Helper methods**: Built-in UI widgets for common patterns
- **Type safe**: Works with `int`, `String`, `bool`, `double`
- **Flutter native**: Uses familiar StatefulWidget patterns

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_secure_storage: ^9.2.2
  crypto: ^3.0.3
  web: ^1.1.1
```

## How it works

1. Variables with the same name and type sync between tabs
2. Uses BroadcastChannel API for fast tab-to-tab messaging
3. HMAC-SHA256 signing prevents message tampering
4. Flutter Secure Storage keeps encryption keys consistent

## Helper Methods

### Quick variable creation:
```dart
final counter = SyncedVars.counter('score', 0);
final message = SyncedVars.text('status', 'Hello');
final enabled = SyncedVars.toggle('active', true);
```

### Built-in UI widgets:
```dart
counter.controls()              // +/- buttons with current value
counter.incrementButton()       // Just the + button
message.textField()            // Auto-syncing text input
enabled.switch_()              // Auto-syncing switch
enabled.checkbox()             // Auto-syncing checkbox
```

### Styling helpers:
```dart
SyncedUI.card(title: 'Settings', children: [...])
SyncedUI.openTabButton()       // "Open New Tab" test button
SyncedUI.syncInstructions()    // Usage instructions text
```

## Example

See `example/synced_widget.dart` for a complete working example.

To test:
1. Run `flutter run -d chrome example/synced_widget.dart`
2. Click "Open New Tab" 
3. Change values in one tab and watch them sync to others

## Web Only

Tang0 only works in web browsers because it uses the BroadcastChannel API. Mobile and desktop platforms don't support cross-tab communication.

## License

MIT

