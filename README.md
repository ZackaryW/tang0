# Tang0

A Flutter web package for effortless cross-tab communication using BroadcastChannel API.

## What it does

Tang0 enables secure, encrypted cross-tab communication for Flutter web applications. Keep your app state synchronized between browser tabs automatically, or set up one-way messaging patterns for event broadcasting.

## Features

- **Secure Communication**: HMAC-SHA256 signed messages with XOR encryption
- **Optional Enhanced Security**: Plug in your own encryption functions for sensitive data
- **One-Way Messaging**: Simple sender/receiver pattern for event broadcasting  
- **Synced Widgets**: Automatic state synchronization between browser tabs
- **Type Safety**: Full generic type support with custom serialization
- **Easy Integration**: Widget-based API with minimal setup
- **Fallback Support**: Works even when secure storage is unavailable

## Quick Start

### One-Way Communication
```dart
import 'package:flutter/material.dart';
import 'package:tang0/tang0.dart';

// Initialize Tang0 (call once at app start)
await initializeTang0Tokens();

// Sender tab
final sender = OneWaySender<String>(command: "notification");
sender.send("Hello from another tab!");

// Receiver tab  
OneWayReceiverWidget<String>(
  command: "notification",
  onReceive: (message, event) => print("Received: $message"),
  child: MyWidget(),
)
```

### Synced State
```dart
import 'package:tang0/tang0.dart';

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

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  tang0: ^1.0.0
  # Dependencies are automatically included
```

Or install directly:
```bash
flutter pub add tang0
```

## Initialization

**Important**: Initialize Tang0 before using any communication features:

```dart
import 'package:tang0/tang0.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Tang0 tokens (call once at app startup)
  await initializeTang0Tokens();
  
  runApp(MyApp());
}
```

### Security Notes

- **Secure Mode**: By default, Tang0 uses Flutter Secure Storage for encryption keys
- **Fallback Mode**: If secure storage is unavailable, Tang0 uses predefined tokens with reduced security
- **Optional Enhanced Security**: For sensitive data, provide your own encryption functions
- **Cross-tab Only**: All tabs must use the same security tokens to communicate

## Enhanced Security (Optional)

For applications requiring stronger encryption than XOR, Tang0 supports custom encryption functions:

```dart
import 'package:tang0/src/top0.dart';
import 'package:crypto/crypto.dart';

// Example: AES encryption (implement your preferred method)
String customEncrypt(String data, String nonce) {
  // Your AES/RSA/other encryption implementation
  // Use nonce as IV or salt as needed
  return encryptedData;
}

String customDecrypt(String encryptedData, String nonce) {
  // Your corresponding decryption implementation
  return originalData;
}

void main() async {
  await initializeTang0Tokens();
  
  // Set your custom encryption functions
  optionalSecurityEncrypt = customEncrypt;
  optionalSecurityDecrypt = customDecrypt;
  
  runApp(MyApp());
}
```

**Important Notes**:
- Commands always use Tang0's XOR system for compatibility
- Only message **data** uses your custom encryption
- Your functions receive `(String data, String nonce)` parameters
- HMAC verification still applies to ensure message integrity

## How it works

1. **Secure Channel**: Uses BroadcastChannel API for fast tab-to-tab messaging
2. **Message Signing**: HMAC-SHA256 signing prevents message tampering
3. **Encryption**: XOR encryption with rotating nonces for message privacy
4. **Storage**: Flutter Secure Storage keeps encryption keys consistent across sessions

## API Reference

### One-Way Communication

#### Sending Messages
```dart
// Create a sender for a specific message type
final sender = OneWaySender<UserEvent>(
  command: "user_login",
  channelName: "auth_events", // Optional, defaults to "one_way_sync"
);

// Send typed messages
sender.send(UserEvent(userId: 123, name: "John"));
```

#### Receiving Messages
```dart
// Widget-based receiver
OneWayReceiverWidget<UserEvent>(
  command: "user_login",
  channelName: "auth_events",
  deserializer: UserEvent.fromJson, // Required for custom types
  onReceive: (event, messageEvent) {
    print("User logged in: ${event.name}");
  },
  child: MyWidget(),
)

// Programmatic receiver
final receiver = OneWayReceiver<UserEvent>(
  deserializer: UserEvent.fromJson,
  onReceive: (event, messageEvent) => handleUserLogin(event),
);
```

### Synced State

#### Quick Variable Creation
```dart
final counter = SyncedVars.counter('score', 0);
final message = SyncedVars.text('status', 'Hello');
final enabled = SyncedVars.toggle('active', true);
```

#### Built-in UI Widgets
```dart
counter.controls()              // +/- buttons with current value
counter.incrementButton()       // Just the + button
message.textField()            // Auto-syncing text input
enabled.switch_()              // Auto-syncing switch
enabled.checkbox()             // Auto-syncing checkbox
```

#### Styling Helpers
```dart
SyncedUI.card(title: 'Settings', children: [...])
SyncedUI.openTabButton()       // "Open New Tab" test button
SyncedUI.syncInstructions()    // Usage instructions text
```

## Examples

### One-Way Communication Example
See `example/one_way_sync.dart` for a complete sender/receiver demo:

1. **Home Page**: Choose between sender or receiver role
2. **Sender Tab**: Send different types of messages  
3. **Receiver Tab**: Display received messages with color coding

To test:
```bash
flutter run -d chrome example/one_way_sync.dart
```

### Synced Widget Example  
See `example/synced_widget.dart` for automatic state synchronization:

To test:
```bash
flutter run -d chrome example/synced_widget.dart
```

Then:
1. Click "Open New Tab"
2. Change values in one tab and watch them sync to others

## Web Only

Tang0 only works in web browsers because it uses the BroadcastChannel API. Mobile and desktop platforms don't support cross-tab communication.

## License

MIT

