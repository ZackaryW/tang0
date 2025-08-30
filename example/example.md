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