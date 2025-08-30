import 'package:flutter/material.dart';
import 'package:tang0/src/templates/synced_widget.dart';
import 'package:tang0/src/helper/synced_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tang0 Synced Widget Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ExampleSyncedWidgetPage(),
    );
  }
}

// Example usage of SyncedWidget with helper methods
class ExampleSyncedWidgetPage extends StatelessWidget {
  const ExampleSyncedWidgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tang0 Synced Widget Example')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child:
            // Much simpler with helper methods!
            SyncedWidgetBuilder()
                .addCounter('counter', 0)
                .addText('message', 'Hello World')
                .addToggle('isEnabled', true)
                .build((context, vars) {
                  final counter = vars[0] as SyncedVar<int>;
                  final message = vars[1] as SyncedVar<String>;
                  final isEnabled = vars[2] as SyncedVar<bool>;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Widget Hash: This widget will sync with other tabs having the same variable structure',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 20),

                      // Counter section - much simpler with helpers!
                      SyncedUI.card(
                        title: 'Counter',
                        children: [counter.controls(title: 'Counter')],
                      ),

                      const SizedBox(height: 16),

                      // Message section - auto-wired text field
                      SyncedUI.card(
                        title: 'Message',
                        children: [
                          message.toLabelText('Current Message'),
                          const SizedBox(height: 10),
                          message.textField(label: 'Enter new message'),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Boolean toggle - built-in switch
                      SyncedUI.card(
                        title: 'Feature Toggle',
                        children: [isEnabled.switch_(title: 'Feature Enabled')],
                      ),

                      const SizedBox(height: 20),

                      // Test sync functionality
                      SyncedUI.card(
                        title: 'Test Sync Functionality',
                        children: [SyncedUI.openTabButton()],
                      ),

                      const SizedBox(height: 20),

                      // Instructions with helper
                      SyncedUI.syncInstructions(),
                    ],
                  );
                }),
      ),
    );
  }
}
