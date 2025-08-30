# Tang0 Project Brief

## Core Purpose
Tang0 is a simple Flutter web package that wraps the BroadcastChannel API to make cross-tab state synchronization easier for developers. It handles the crypto and messaging complexity automatically.

## Key Requirements
1. **Simple Widget**: Easy-to-use SyncedWidget that handles sync automatically
2. **Secure Messages**: All messages signed/verified transparently  
3. **Flutter Native**: Uses familiar Flutter patterns and widgets
4. **Just Works**: No configuration needed, sensible defaults
5. **Cross-tab Sync**: Variables stay in sync between browser tabs

## Library Structure

### `lib/tang0.dart` - Main Exports
- Public API for developers (needs to be set up)

### `lib/src/top0.dart` - Security Functions
- Message signing with HMAC-SHA256
- Automatic token generation and storage
- All handled transparently by widgets

### `lib/src/channel.dart` - BroadcastChannel Wrapper
- Tang0Channel class wraps native BroadcastChannel
- Handles JSON serialization and message routing
- Automatic cleanup on widget disposal

### `lib/src/templates/synced_widget.dart` - Main Widget
- SyncedWidget for cross-tab variable synchronization
- SyncedVar<T> for reactive variables
- Integrates with Flutter StatefulWidget pattern

## Use Cases

### Current: Basic State Sync
- Shopping cart updates across tabs
- Form data persistence
- Settings/preferences sync
- Counter/status displays

### Possible Future
If people find it useful:
- Login/logout state sync
- Simple notifications across tabs
- Basic data streaming

## Success Criteria
- Developers can add cross-tab sync in a few lines of code
- No need to understand BroadcastChannel API directly
- Security handled automatically
- Works reliably in common browsers
- Clear example showing how to use it
