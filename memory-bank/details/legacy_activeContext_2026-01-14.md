# Legacy: activeContext.md (2026-01-14)

This file preserves the previous contents of `memory-bank/activeContext.md` prior to the documentation revamp.

---

# Active Context

## Current Work Status

### Async/Sync Hybrid Support + Production Error Handling ✅ NEW
Tang0 now supports both synchronous and asynchronous receive handlers with production-grade error handling.

**What's Working**:
- `FutureOr<void>` return type for `receive` methods - supports both sync and async
- Fire-and-forget async execution using `.then()` - no manual task management needed
- Configurable error handling strategies for production use
- All receivers updated to support async operations
- Comprehensive error handling across all communication patterns

**Error Handling Strategies**:
- `Tang0ErrorStrategy.skip` - Silently ignore errors (production fail-safe)
- `Tang0ErrorStrategy.print` - Log errors to debug console (default, development-friendly)
- `Tang0ErrorStrategy.callback` - Custom error handler for advanced monitoring/logging

**Technical Implementation**:
- Async tasks execute automatically without blocking message handling
- Proper error and stack trace capture
- Assertion validation for callback strategy configuration
- Exported `Tang0ErrorStrategy` enum for public API

### SyncedWidget Implementation Complete + Optional Security ✅
Simple cross-tab synchronization widget for Flutter web apps with clean helper methods and enhanced security options.

**What's Working**:
- Basic SyncedVar<T> variables that sync between browser tabs
- Simple widget wrapper that handles the sync automatically
- Helper methods make creating synced widgets much easier
- Flutter Secure Storage for keeping encryption keys consistent
- Working example using the new helper methods
- Cross-tab synchronization works reliably
- Optional security functions for custom encryption beyond XOR
- **NEW**: Async/sync hybrid receive handlers with error handling

**Recent Addition - Async/Sync Support**:
- `Tang0Receive.receive()` now returns `FutureOr<void>` instead of `void`
- Both sync and async implementations supported seamlessly
- Async operations execute via fire-and-forget pattern
- Production-ready error handling with multiple strategies
- All helper classes updated: `OneWayReceiver`, `_SyncReceiver`

**Technical Details**:
- Uses BroadcastChannel for tab-to-tab messaging
- HMAC signing to prevent tampering
- Widget hash ensures only matching widgets sync together
- Handles the crypto stuff transparently so devs don't have to think about it
- Optional security allows true encryption for sensitive data
- Async operations don't block message processing

## Current Implementation

### Simple Abstraction Layer + Helper Methods + Async Support
Just wraps the messy BroadcastChannel and crypto stuff, plus adds helper methods for super easy usage, now with full async support.

**Core Files**:
- `synced_widget.dart`: Main widget that handles sync
- `helper/synced_widget.dart`: Helper methods for easy widget creation ✅
- `helper/one_way_sync.dart`: One-way messaging with async support ✅ UPDATED
- `channel.dart`: BroadcastChannel wrapper with error handling ✅ UPDATED
- `top0.dart`: Crypto/signing functions (mostly invisible to users)

**Helper Methods Added**:
- `SyncedVars.counter()`, `SyncedVars.text()`, `SyncedVars.toggle()` - Easy variable creation
- Extension methods: `counter.controls()`, `message.textField()`, `toggle.switch_()` - Built-in UI
- `SyncedUI.card()`, `SyncedUI.openTabButton()` - Consistent styling helpers
- `SyncedWidgetBuilder` - Fluent builder pattern for easy construction

**Dependencies**:
- `flutter_secure_storage`: For keeping crypto keys the same across tabs
- `crypto`: For HMAC message signing
- `web`: For BroadcastChannel access

### Next Steps
1. ✅ Helper methods created - makes usage much simpler
2. ✅ Async/sync hybrid support implemented
3. ✅ Production error handling strategies added
4. ✅ Set up proper exports in `lib/tang0.dart` - COMPLETE
5. ✅ Write basic README showing how to use it - UPDATED
6. Consider additional examples showcasing async patterns

The helper methods transformed a complex manual setup into simple, readable code. Async support enables real-world use cases like database operations and API calls.

## File Status
- ✅ `lib/src/top0.dart` - Crypto functions working
- ✅ `lib/src/channel.dart` - BroadcastChannel wrapper with async + error handling ✅ UPDATED
- ✅ `lib/src/templates/synced_widget.dart` - Main sync widget with async support ✅ UPDATED
- ✅ `lib/src/helper/synced_widget.dart` - Helper methods working
- ✅ `lib/src/helper/one_way_sync.dart` - One-way sync with async support ✅ UPDATED
- ✅ `example/synced_widget.dart` - Demo app updated with helper methods
- ✅ `lib/tang0.dart` - Exports Tang0ErrorStrategy and core classes ✅ UPDATED

## Testing
- Manual testing works - can sync between browser tabs
- Helper methods dramatically simplify usage
- Example reduced from 100+ lines of boilerplate to clean, readable code
- ✅ Unit tests: 37 tests passing (27 crypto + 10 optional security) ✅
- ✅ Async tests created but skipped due to web package version incompatibility
- Need to test more edge cases with async patterns
- BroadcastChannel only works in actual browsers, not in test environment

## Usage Examples

### Async Receive Handler
```dart
final receiver = OneWayReceiver<UserData>(
	onReceive: (data, event) async {
		// Async operations work seamlessly
		await database.saveUser(data);
		await analytics.logEvent('user_updated');
	},
);
```

### Custom Error Handling
```dart
final receiver = OneWayReceiverWidget<String>(
	command: "important_updates",
	errorStrategy: Tang0ErrorStrategy.callback,
	onError: (error, stackTrace) {
		// Log to monitoring service
		ErrorLogger.report(error, stackTrace);
		// Notify user
		showErrorToast("Update failed");
	},
	onReceive: (message, event) async {
		await processImportantUpdate(message);
	},
	child: MyWidget(),
);
```
