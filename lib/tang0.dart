/// A Flutter web package for effortless cross-tab communication using BroadcastChannel API.
///
/// Tang0 provides secure, encrypted cross-tab communication for Flutter web applications
/// with easy-to-use widgets and helpers for common synchronization patterns.
///
/// ## Features
///
/// - **Secure Communication**: HMAC-SHA256 signed messages with XOR encryption
/// - **One-Way Messaging**: Simple sender/receiver pattern for event broadcasting
/// - **Synced Widgets**: Automatic state synchronization between browser tabs
/// - **Type Safety**: Full generic type support with custom serialization
/// - **Easy Integration**: Widget-based API with minimal setup
///
/// ## Initialization (Optional but Recommended)
///
/// For maximum security, initialize Tang0 at app startup:
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   try {
///     await initializeTang0Tokens(); // Secure tokens
///   } catch (e) {
///     print('Secure storage unavailable: $e');
///     // Tang0 will use fallback tokens automatically
///   }
///
///   runApp(MyApp());
/// }
/// ```
///
/// If not initialized, Tang0 uses predefined fallback tokens (reduced security).
///
/// ## Basic Usage
///
/// ### One-Way Communication
/// ```dart
/// // Sender tab
/// final sender = OneWaySender<String>(command: "notification");
/// sender.send("Hello from another tab!");
///
/// // Receiver tab
/// OneWayReceiverWidget<String>(
///   command: "notification",
///   onReceive: (message, event) => print("Received: $message"),
///   child: MyWidget(),
/// )
/// ```
///
/// ### Synced State
/// ```dart
/// SyncedWidgetBuilder()
///   .addCounter('counter', 0)
///   .addText('message', 'Hello')
///   .build((context, vars) {
///     final counter = vars[0] as SyncedVar<int>;
///     return Column(children: [counter.controls()]);
///   })
/// ```
library;

// Core Tang0 channel functionality
export 'src/channel.dart';

// Security and token initialization
export 'src/top0.dart' show initializeTang0Tokens;

// One-way sync helpers for cross-tab messaging
export 'src/helper/one_way_sync.dart';

// Synced widget helpers for state management
export 'src/helper/synced_widget.dart';

// Synced widget templates
export 'src/templates/synced_widget.dart';
