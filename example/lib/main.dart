import 'package:flutter/material.dart';

import 'examples/tab_dedup_example.dart';
import 'examples/t0t_timer_example.dart';

void main() {
  runApp(const Tang0LauncherApp());
}

class Tang0LauncherApp extends StatelessWidget {
  const Tang0LauncherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'tang0 examples',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const LauncherHome(),
    );
  }
}

class LauncherHome extends StatelessWidget {
  const LauncherHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('tang0 examples')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          ListTile(
            title: const Text('T0T Timer example'),
            subtitle: const Text('Periodic SYNC + PAUSE/RESUME/END messages'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const T0TTimerExamplePage(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Tab dedup example'),
            subtitle: const Text(
              'Heartbeat presence + close request when >4 tabs',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TabDedupExamplePage(),
                ),
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Tip: run a single demo directly with:\n'
              '  flutter run -d chrome -t lib/t0t_timer_main.dart\n'
              '  flutter run -d chrome -t lib/tab_dedup_main.dart',
            ),
          ),
        ],
      ),
    );
  }
}
