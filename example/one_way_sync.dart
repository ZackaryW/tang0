import 'package:flutter/material.dart';
import 'package:tang0/tang0.dart';
import 'package:web/web.dart' as web;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tang0 One-Way Sync Demo',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const HomePage(),
    );
  }
}

/// Example data class for demonstrating typed message passing
class UserEvent {
  final int userId;
  final String name;
  final String action;
  final DateTime timestamp;

  UserEvent({
    required this.userId,
    required this.name,
    required this.action,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Serialization method for sending over Tang0 channels
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'name': name,
    'action': action,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  /// Deserialization method for receiving from Tang0 channels
  factory UserEvent.fromJson(Map<String, dynamic> json) => UserEvent(
    userId: json['userId'] as int? ?? 0,
    name: json['name'] as String? ?? 'Unknown',
    action: json['action'] as String? ?? 'unknown',
    timestamp: json['timestamp'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
        : DateTime.now(),
  );

  @override
  String toString() => 'UserEvent(id: $userId, name: $name, action: $action)';
}

/// Status update class for loading states
class LoadingState {
  final bool isLoading;
  final double progress;
  final String message;

  LoadingState({
    required this.isLoading,
    this.progress = 0.0,
    this.message = '',
  });

  Map<String, dynamic> toJson() => {
    'isLoading': isLoading,
    'progress': progress,
    'message': message,
  };

  factory LoadingState.fromJson(Map<String, dynamic> json) => LoadingState(
    isLoading: json['isLoading'] as bool? ?? false,
    progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
    message: json['message'] as String? ?? '',
  );

  @override
  String toString() =>
      'LoadingState(loading: $isLoading, progress: ${(progress * 100).toInt()}%)';
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tang0 One-Way Sync Demo'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Tang0 Cross-Tab Communication Demo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text('Choose your role:', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SenderPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 60),
              ),
              child: const Text('SENDER TAB', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReceiverPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 60),
              ),
              child: const Text('RECEIVER TAB', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 40),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Instructions:\n'
                '1. Open this page in multiple browser tabs\n'
                '2. Make one tab a SENDER (click blue button)\n'
                '3. Make another tab a RECEIVER (click orange button)\n'
                '4. Send messages from sender tab and watch them appear in receiver tab',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// SENDER PAGE - Only sends messages to other tabs
class SenderPage extends StatefulWidget {
  const SenderPage({super.key});

  @override
  State<SenderPage> createState() => _SenderPageState();
}

class _SenderPageState extends State<SenderPage> {
  // Senders for different message types
  OneWaySender<UserEvent>? userEventSender;
  OneWaySender<String>? notificationSender;
  OneWaySender<String>? commandSender;
  OneWaySender<LoadingState>? statusSender;

  int messageCounter = 0;
  final List<String> _sentMessages = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAsync();
  }

  void _initializeAsync() async {
    // Tang0 will use fallback tokens if not explicitly initialized
    // For better security, you can initialize with:
    // await initializeTang0Tokens();

    // Initialize all senders after tokens are ready
    setState(() {
      userEventSender = OneWaySender<UserEvent>(
        command: "user_login",
        channelName: "auth_events",
      );

      notificationSender = OneWaySender<String>(command: "user_action");

      commandSender = OneWaySender<String>(command: "cmd_refresh_data");

      statusSender = OneWaySender<LoadingState>(command: "status_loading");

      _isInitialized = true;
    });
  }

  void _addSentMessage(String message) {
    setState(() {
      _sentMessages.insert(
        0,
        "[${DateTime.now().toString().substring(11, 19)}] $message",
      );
      // Keep only last 10 messages
      if (_sentMessages.length > 10) {
        _sentMessages.removeLast();
      }
    });
  }

  void _sendUserEvent() {
    if (userEventSender == null) return;
    messageCounter++;
    final event = UserEvent(
      userId: messageCounter,
      name: "User$messageCounter",
      action: "login",
    );
    userEventSender!.send(event);
    _addSentMessage("SENT UserEvent: ${event.toString()}");
  }

  void _sendNotification() {
    if (notificationSender == null) return;
    messageCounter++;
    final message = "Button clicked $messageCounter times";
    notificationSender!.send(message);
    _addSentMessage("SENT Notification: $message");
  }

  void _sendCommand() {
    if (commandSender == null) return;
    commandSender!.send("trigger");
    _addSentMessage("SENT Command: refresh_data trigger");
  }

  void _sendStatus() {
    if (statusSender == null) return;
    messageCounter++;
    final isLoading = messageCounter % 2 == 0;
    final status = LoadingState(
      isLoading: isLoading,
      progress: isLoading ? 0.5 : 1.0,
      message: isLoading ? "Processing..." : "Complete",
    );
    statusSender!.send(status);
    _addSentMessage("SENT Status: ${status.toString()}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SENDER TAB'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'This is the SENDER tab. Use the buttons below to send messages to RECEIVER tabs.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Send buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isInitialized ? _sendUserEvent : null,
                    child: Text(
                      _isInitialized ? 'Send User Event' : 'Initializing...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isInitialized ? _sendNotification : null,
                    child: Text(
                      _isInitialized ? 'Send Notification' : 'Initializing...',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isInitialized ? _sendCommand : null,
                    child: Text(
                      _isInitialized ? 'Send Command' : 'Initializing...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isInitialized ? _sendStatus : null,
                    child: Text(
                      _isInitialized ? 'Send Status' : 'Initializing...',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Text(
              'Sent Messages:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Message history
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _sentMessages.isEmpty
                    ? const Center(child: Text('No messages sent yet'))
                    : ListView.builder(
                        itemCount: _sentMessages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 4.0,
                            ),
                            child: Text(
                              _sentMessages[index],
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),

            const SizedBox(height: 10),
            const Text(
              'Tip: Open another tab and choose "RECEIVER TAB" to see these messages appear!',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// RECEIVER PAGE - Only receives and displays messages from other tabs
class ReceiverPage extends StatefulWidget {
  const ReceiverPage({super.key});

  @override
  State<ReceiverPage> createState() => _ReceiverPageState();
}

class _ReceiverPageState extends State<ReceiverPage> {
  final List<String> _receivedMessages = [];

  void _addReceivedMessage(String message) {
    setState(() {
      _receivedMessages.insert(
        0,
        "[${DateTime.now().toString().substring(11, 19)}] $message",
      );
      // Keep only last 20 messages
      if (_receivedMessages.length > 20) {
        _receivedMessages.removeLast();
      }
    });
  }

  void _handleUserEventReceived(
    UserEvent event,
    web.MessageEvent messageEvent,
  ) {
    _addReceivedMessage("RECEIVED UserEvent: ${event.toString()}");
  }

  void _handleNotificationReceived(
    String notification,
    web.MessageEvent messageEvent,
  ) {
    _addReceivedMessage("RECEIVED Notification: $notification");
  }

  void _handleCommandReceived(String command, web.MessageEvent messageEvent) {
    _addReceivedMessage("RECEIVED Command: $command");
  }

  void _handleStatusReceived(
    LoadingState status,
    web.MessageEvent messageEvent,
  ) {
    _addReceivedMessage("RECEIVED Status: ${status.toString()}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RECEIVER TAB'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body:
          // Wrap with multiple receivers for different message types
          OneWayReceiverWidget<UserEvent>(
            command: "user_login",
            channelName: "auth_events",
            deserializer: UserEvent.fromJson,
            onReceive: _handleUserEventReceived,
            child: OneWayReceiverWidget<String>(
              command: "user_action",
              onReceive: _handleNotificationReceived,
              child: OneWayReceiverWidget<String>(
                command: "cmd_refresh_data",
                onReceive: _handleCommandReceived,
                child: OneWayReceiverWidget<LoadingState>(
                  command: "status_loading",
                  deserializer: LoadingState.fromJson,
                  onReceive: _handleStatusReceived,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'This is the RECEIVER tab. It listens for messages from SENDER tabs.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Received Messages:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Message display
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _receivedMessages.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Waiting for messages...\n\nOpen another tab and choose "SENDER TAB" to send messages here!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _receivedMessages.length,
                                    itemBuilder: (context, index) {
                                      final message = _receivedMessages[index];
                                      Color messageColor = Colors.black;
                                      if (message.contains('UserEvent'))
                                        messageColor = Colors.blue;
                                      else if (message.contains('Notification'))
                                        messageColor = Colors.green;
                                      else if (message.contains('Command'))
                                        messageColor = Colors.purple;
                                      else if (message.contains('Status'))
                                        messageColor = Colors.orange;

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12.0,
                                          vertical: 4.0,
                                        ),
                                        child: Text(
                                          message,
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 12,
                                            color: messageColor,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),

                        const SizedBox(height: 10),
                        const Text(
                          'Tip: This tab automatically receives messages sent from SENDER tabs!',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
    );
  }
}

class ExampleOneWaySyncPage extends StatefulWidget {
  const ExampleOneWaySyncPage({super.key});

  @override
  State<ExampleOneWaySyncPage> createState() => _ExampleOneWaySyncPageState();
}

class _ExampleOneWaySyncPageState extends State<ExampleOneWaySyncPage> {
  // Create various senders for different message types
  late final OneWaySender<UserEvent> userEventSender;
  late final OneWaySender<String> notificationSender;
  late final OneWaySender<String> commandSender;
  late final OneWaySender<LoadingState> statusSender;

  // Message history for display
  final List<String> receivedMessages = [];
  int messageCounter = 0;

  @override
  void initState() {
    super.initState();

    // Initialize senders using different patterns
    userEventSender = OneWaySender<UserEvent>(
      command: "user_login",
      channelName: "auth_events",
    );

    // Using factory methods for common patterns
    final (sender, _) = OneWaySync.notification("user_action");
    notificationSender = sender;

    commandSender = OneWaySync.command("refresh_data");
    statusSender = OneWaySync.status<LoadingState>("loading");
  }

  void _addMessage(String message) {
    if (mounted) {
      setState(() {
        receivedMessages.insert(
          0,
          "${DateTime.now().toLocal().toString().split(' ')[1]}: $message",
        );
        if (receivedMessages.length > 10) {
          receivedMessages.removeLast();
        }
      });
    }
  }

  void _handleUserEventReceived(UserEvent event, dynamic messageEvent) {
    _addMessage("RECEIVED: User event - ${event.toString()}");
  }

  void _handleNotificationReceived(String message, dynamic messageEvent) {
    _addMessage("RECEIVED: Notification - $message");
  }

  void _handleCommandReceived(String trigger, dynamic messageEvent) {
    _addMessage("RECEIVED: Refresh command - $trigger");
  }

  void _handleStatusReceived(LoadingState status, dynamic messageEvent) {
    _addMessage("RECEIVED: Status update - ${status.toString()}");
  }

  void _sendUserEvent() {
    messageCounter++;
    final event = UserEvent(
      userId: messageCounter,
      name: "User$messageCounter",
      action: "login",
    );
    userEventSender.send(event);
    _addMessage("SENT: User event - ${event.toString()}");
  }

  void _sendNotification() {
    messageCounter++;
    final message = "Button clicked $messageCounter times";
    notificationSender.send(message);
    _addMessage("SENT: Notification - $message");
  }

  void _sendCommand() {
    commandSender.send("trigger");
    _addMessage("SENT: Refresh command triggered");
  }

  void _sendStatus() {
    messageCounter++;
    final isLoading = messageCounter % 2 == 0;
    final status = LoadingState(
      isLoading: isLoading,
      progress: isLoading ? 0.5 : 1.0,
      message: isLoading ? "Processing..." : "Complete",
    );
    statusSender.send(status);
    _addMessage("SENT: Status update - ${status.toString()}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tang0 One-Way Sync Example'),
        backgroundColor: Colors.green,
      ),
      body:
          // Wrap the entire page with multiple receivers for different message types
          OneWayReceiverWidget<UserEvent>(
            command: "user_login",
            channelName: "auth_events",
            deserializer: UserEvent.fromJson,
            onReceive: _handleUserEventReceived,
            child: OneWayReceiverWidget<String>(
              command: "user_action",
              onReceive: _handleNotificationReceived,
              child: OneWayReceiverWidget<String>(
                command: "cmd_refresh_data",
                onReceive: _handleCommandReceived,
                child: OneWayReceiverWidget<LoadingState>(
                  command: "status_loading",
                  deserializer: LoadingState.fromJson,
                  onReceive: _handleStatusReceived,
                  child: _buildContent(context),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Instructions - more compact
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'One-Way Sync Demo',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '1. Open this page in multiple browser tabs\n'
                    '2. Click any "Send" button in one tab\n'
                    '3. Watch the message appear in all other tabs\n'
                    '4. Each message type has its own unique channel',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Control buttons in a more compact grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.5,
            children: [
              _buildCompactButton(
                onPressed: _sendUserEvent,
                icon: Icons.person,
                label: 'User Event',
                color: Colors.blue,
              ),
              _buildCompactButton(
                onPressed: _sendNotification,
                icon: Icons.notifications,
                label: 'Notification',
                color: Colors.orange,
              ),
              _buildCompactButton(
                onPressed: _sendCommand,
                icon: Icons.refresh,
                label: 'Command',
                color: Colors.purple,
              ),
              _buildCompactButton(
                onPressed: _sendStatus,
                icon: Icons.info,
                label: 'Status',
                color: Colors.green,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Open new tab button - smaller
          Center(
            child: TextButton.icon(
              onPressed: () {
                try {
                  // Open new tab using web API
                  web.window.open(web.window.location.href, '_blank');
                  _addMessage("SYSTEM: Opened new tab for testing");
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please open this page in a new tab manually to test sync',
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open New Tab', style: TextStyle(fontSize: 12)),
            ),
          ),

          const SizedBox(height: 12),

          // Message history - more compact
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Message History',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (receivedMessages.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      child: Center(
                        child: Text(
                          'No messages yet. Click a "Send" button above.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ListView.builder(
                        itemCount: receivedMessages.length,
                        itemBuilder: (context, index) {
                          final message = receivedMessages[index];
                          final isReceived = message.contains('RECEIVED:');
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isReceived
                                  ? Colors.green[50]
                                  : Colors.blue[50],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isReceived
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  size: 12,
                                  color: isReceived
                                      ? Colors.green[700]
                                      : Colors.blue[700],
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    message,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 10,
                                      color: isReceived
                                          ? Colors.green[800]
                                          : Colors.blue[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Technical info - more compact
          Card(
            color: Colors.grey[100],
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Technical Details',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Commands: "user_login", "user_action", "cmd_refresh_data", "status_loading"\n'
                    'All messages signed with HMAC-SHA256 for security',
                    style: TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: const Size(0, 32),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
