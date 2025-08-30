# Product Context

## Problem Statement
Cross-tab communication in Flutter web apps is messy and tedious. Developers end up:

- Writing repetitive BroadcastChannel boilerplate
- Manually handling message signing/verification
- Debugging sync issues between tabs
- Reimplementing the same patterns over and over

## Why Tang0 Exists
Tang0 wraps the messy parts so developers can focus on their actual features:

1. **Simple Widget**: Just wrap your UI in SyncedWidget and variables sync automatically
2. **Security Handled**: Messages are signed/verified transparently
3. **Flutter Integration**: Uses familiar patterns like StatefulWidget and builder functions
4. **Working Example**: Clear demo showing how to use it

## Use Cases

### Current: SyncedWidget
For when you want variables to stay in sync between browser tabs:
- Shopping cart updates across tabs
- Form data persistence when user opens new tab
- Settings changes reflected everywhere
- Counter/status displays staying consistent

### Possible Future Ideas
If people find it useful, could add templates for:
- Login state sync (logout one tab, logout all)
- Notifications/alerts across tabs
- Simple data streaming

## Target Users
Flutter web developers who need basic cross-tab state sync but don't want to mess with:
- BroadcastChannel API directly
- Message signing/verification
- JSON serialization edge cases
- Widget lifecycle management for channels

## Goals
- **Easy to use**: Drop in widget, variables sync automatically
- **Secure by default**: All messages signed, can't be tampered with
- **Flutter-native**: Feels like normal Flutter development
- **Just works**: Handle the common cases well, no configuration needed
