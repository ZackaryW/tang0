# System Patterns

## Basic Architecture

### Simple Layer Design
```
[SyncedWidget]      ← What developers use
      ↓
[Tang0Channel]      ← BroadcastChannel wrapper
      ↓
[Security Functions] ← Signing/verification
      ↓
[BroadcastChannel]  ← Browser API
```

### File Organization  
```
tang0/
├── lib/tang0.dart              # Main exports (needs setup)
├── src/top0.dart              # Crypto functions
├── src/channel.dart           # Channel wrapper
└── src/templates/
    └── synced_widget.dart     # Main sync widget
```

## Key Patterns

### SyncedWidget Pattern
Simple state sync widget that handles all the complex stuff automatically:

```dart
class SyncedWidget extends StatefulWidget {
  final List<SyncedVar> syncedVars;  // Variables to sync
  final Widget Function(BuildContext) builder;  // UI builder
  
  // Handles channel creation, message routing, disposal automatically
}
```

### SyncedVar Pattern
Basic reactive variable that syncs between tabs:

```dart
class SyncedVar<T> {
  T get value => _value;
  set value(T newValue) {
    _value = newValue;
    _onChanged?.call(newValue);  // Local callback
    _broadcastValue(newValue);   // Send to other tabs
  }
}
```

### Security Pattern
All messages get signed automatically - developers don't see any of this:

```dart
// Internally: sign(command, data) → encrypted message
// Internally: verifyCommand(message) → decrypted data or null
// Developer: just sets syncVar.value = newValue
```

### Channel Pattern
Tang0Channel wraps BroadcastChannel with automatic cleanup:

```dart
class Tang0Channel {
  BroadcastChannel _channel;
  
  void send(String command, dynamic data) {
    final signed = sign(command, jsonEncode(data));
    _channel.postMessage(signed);
  }
  
  void dispose() => _channel.close();
}
```

## Implementation Details

### Widget Identity
Each SyncedWidget gets a hash based on its variable names and types. Only widgets with the same hash can sync with each other. This prevents different widgets from interfering with each other.

### Message Flow
1. User changes syncedVar.value
2. Widget serializes all sync variables to JSON
3. Message gets signed with HMAC-SHA256
4. Sent via BroadcastChannel to other tabs
5. Other tabs verify signature and update their variables
6. UI rebuilds automatically

### Error Handling
- Invalid/tampered messages are silently ignored
- Channel errors don't crash the widget
- Failed crypto operations fall back to local-only mode

## Testing Patterns
- Unit tests for crypto functions (27 tests passing)
- Manual testing for cross-tab sync (BroadcastChannel can't be mocked)
- Example app for integration testing

## Code Organization
Keep it simple:
- One main widget (SyncedWidget)
- One channel wrapper (Tang0Channel)  
- One set of crypto functions (top0.dart)
- Clear separation between public API and internal implementation
    _handleVerifiedData(data);
  }
}
```

### State Synchronization Pattern
```dart
// Cross-tab state management
class SyncedVar<T> {
  T get value => _value;
  set value(T newValue) {
    _value = newValue;
    _onChanged?.call(newValue);  // Local callback
    _broadcast(newValue);        // Cross-tab sync
  }
}
```

## Critical Implementation Paths

### Template Instantiation Flow
1. **Configuration**: Developer provides minimal required parameters
2. **Identity Generation**: Hash computed from template structure
3. **Channel Setup**: Automatic channel creation and receiver registration
4. **State Initialization**: Local state established
5. **Sync Enablement**: Cross-tab communication activated

### Message Broadcasting Flow  
1. **Change Detection**: Local state modification triggers broadcast
2. **Data Preparation**: Serialize data for transmission
3. **Security Layer**: Automatic signing and command assignment
4. **Channel Transmission**: BroadcastChannel sends to all tabs
5. **Verification**: Receiving tabs verify and extract data
6. **State Update**: Remote state synchronized with loop prevention

### Template Extension Patterns
```dart
// Creating custom templates
abstract class Tang0Template<TState> extends StatefulWidget {
  String get templateId;           // Unique template identifier
  TState createInitialState();     // State factory method
  void onStateSync(TState state);  // Cross-tab sync handler
  Widget buildUI(BuildContext context, TState state); // UI builder
}
```

## Template Design Principles

### Boilerplate Effectiveness
- **Minimal Configuration**: Sensible defaults, optional customization
- **Maximum Reusability**: Templates work across different use cases
- **Clear Extension Points**: Well-defined hooks for customization
- **Progressive Enhancement**: Basic usage simple, advanced features available

### Developer Experience Patterns
- **Familiar APIs**: Standard Flutter widget patterns
- **Type Safety**: Generic templates with compile-time guarantees  
- **Error Clarity**: Descriptive error messages with solution hints
- **Documentation**: Inline examples and comprehensive guides

### Performance Optimization Patterns
- **Lazy Initialization**: Resources created only when needed
- **Message Batching**: Multiple changes combined into single broadcast
- **Memory Management**: Automatic cleanup and resource disposal
- **Efficient Routing**: Command-based filtering minimizes processing overhead
