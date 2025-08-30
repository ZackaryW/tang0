# Technical Context

## Technology Stack

### Flutter/Dart 
- **Flutter**: Web platform (need BroadcastChannel API)
- **Dart**: Standard null-safe Dart
- **Target**: Modern web browsers only

### Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  crypto: ^3.0.3                    # For HMAC message signing
  flutter_secure_storage: ^9.2.2   # For persistent token storage
  web: ^1.1.1                      # For BroadcastChannel access
```

### Web APIs Used
- **BroadcastChannel**: Native browser API for tab-to-tab messaging
- **Window.localStorage**: Used by flutter_secure_storage for web
- **JSON**: Standard message serialization

## Development Setup

### File Structure
```
tang0/
├── lib/
│   ├── tang0.dart                    # Main exports (empty, needs setup)
│   └── src/
│       ├── top0.dart                 # Crypto functions
│       ├── channel.dart              # BroadcastChannel wrapper
│       └── templates/
│           └── synced_widget.dart    # Main sync widget
├── test/
│   └── top0_test.dart               # 27 unit tests for crypto
├── example/
│   └── synced_widget.dart           # Working demo
└── memory-bank/                     # Documentation
```

### Development Commands
```bash
# Run example in browser
flutter run -d chrome example/synced_widget.dart

# Run unit tests
flutter test

# Build for web
flutter build web
```

## Technical Constraints

### Platform Limitations
- **Web Only**: BroadcastChannel doesn't exist on mobile/desktop
- **Same Origin**: Tabs must be from same domain to communicate
- **Testing**: Can't unit test BroadcastChannel (need real browser)
- **Browser Support**: Modern browsers only

### Security Implementation
- **HMAC-SHA256**: Standard message signing (crypto package)
- **XOR Encoding**: Simple obfuscation for messages
- **Secure Storage**: Flutter Secure Storage for persistent tokens
- **Auto-handled**: All security invisible to developers using SyncedWidget

### Widget Design
- **Hash Identity**: SHA1 of widget config determines sync channel
- **Generic Variables**: SyncedVar<T> works with int, String, bool, double
- **StatefulWidget**: Standard Flutter patterns
- **Builder Pattern**: Flexible UI composition

## Known Issues
- **Cross-tab testing**: Must test manually in multiple browser tabs
- **Error handling**: Channel errors are silently ignored
- **Type safety**: Runtime checks needed for generic callback casting
- **Dependencies**: Added 3 new dependencies for web+crypto functionality

## Development Notes
- Use `flutter run -d web-server` for local testing
- Open multiple tabs to test cross-tab sync
- Check browser console for any JS interop errors
- Security functions tested with comprehensive unit test suite
- Widget functionality requires manual browser validation

# Build for web deployment
flutter build web
```

### Testing Strategy
- **Unit Tests**: Core security functions (27/27 passing)
- **Manual Testing**: Web features in actual browser tabs
- **Integration Validation**: Cross-tab communication scenarios
- **Performance Testing**: Message throughput and memory usage

### Library Publishing
```bash
# Prepare for pub.dev publication
flutter pub publish --dry-run

# Version management
flutter pub publish
```

## Integration Patterns

### Template Usage Pattern
```dart
// Developer integration approach
import 'package:tang0/tang0.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SyncedWidget<CounterState>(
      initialState: CounterState(count: 0),
      builder: (context, state) {
        // UI automatically syncs across tabs
        return CounterDisplay(state);
      },
    );
  }
}
```

### Channel Usage Pattern
```dart
// Advanced users can use channels directly
class CustomReceiver extends Tang0Receive {
  @override
  void receive(dynamic data, web.MessageEvent event) {
    // Security verification already handled
    handleCustomData(data);
  }
}

final channel = Tang0Channel('my-feature', CustomReceiver());
channel.send('UPDATE', {'key': 'value'});
```

### Security Integration Pattern
```dart
// Security is completely transparent to developers
// Templates automatically handle:
// - Message signing and verification  
// - Command assignment and filtering
// - Cross-tab identity management
// - Replay attack prevention
```

## Performance Considerations

### Memory Management
- **Automatic Cleanup**: Channels dispose when widgets unmount
- **Message Batching**: Multiple state changes can be batched
- **Efficient Routing**: Command filtering prevents unnecessary processing
- **Identity Caching**: Hash computation cached per template instance

### Network Efficiency  
- **JSON Serialization**: Compact data transmission format
- **Command Compression**: Fixed-length commands optimize message size
- **Local-first**: Changes applied locally before broadcasting
- **Selective Updates**: Only changed data transmitted across tabs

### Runtime Optimization
- **Lazy Initialization**: Resources created only when needed
- **Type-safe Operations**: Compile-time optimization opportunities
- **Minimal Dependencies**: Small bundle size for web deployment
- **Hash-based Routing**: O(1) message filtering by template identity

## Future Technical Roadmap

### Template Expansion
- **AuthState Template**: Session management across tabs
- **NotificationTemplate**: Alert broadcasting system  
- **DataStream Template**: Real-time data synchronization
- **FormSync Template**: Multi-step form coordination

### Platform Extensions
- **Storage Integration**: Persistent state with localStorage
- **Service Worker**: Offline capability and background sync
- **WebRTC Fallback**: Direct peer-to-peer when BroadcastChannel unavailable
- **Mobile Bridge**: Native mobile communication via platform channels

### Developer Experience Enhancements
- **Template Generator**: CLI tool for custom template scaffolding
- **Debug Dashboard**: Visual debugging of cross-tab communications
- **Performance Profiler**: Message timing and throughput analysis
- **Type Generation**: Code generation for complex state objects
