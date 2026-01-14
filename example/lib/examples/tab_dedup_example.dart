// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:tang0/src/templates/tab_dedup.dart';

import 'section.dart';

class TabDedupExampleApp extends StatelessWidget {
  const TabDedupExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'tang0: tab dedup',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const TabDedupExamplePage(),
    );
  }
}

class TabDedupExamplePage extends StatefulWidget {
  const TabDedupExamplePage({super.key});

  @override
  State<TabDedupExamplePage> createState() => _TabDedupExamplePageState();
}

class _TabDedupExamplePageState extends State<TabDedupExamplePage> {
  late final T0TabDeduper _deduper;

  @override
  void initState() {
    super.initState();

    _deduper = T0TabDeduper(
      maxTabs: 4,
      keepTabs: 2,
      meta: <String, dynamic>{'app': 'tang0_tab_dedup_example'},
    )..addListener(_onUpdate);
  }

  void _onUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _deduper.removeListener(_onUpdate);
    _deduper.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _deduper.tabs;

    return Scaffold(
      appBar: AppBar(title: const Text('Tab dedup example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Section(
              title: 'This tab',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Id: ${_deduper.id}'),
                  Text('Created: ${_deduper.createdAt.toIso8601String()}'),
                  const SizedBox(height: 8),
                  Text(
                    'Tabs seen: ${_deduper.tabCount}  (max: ${_deduper.maxTabs}, keep: ${_deduper.keepTabs})',
                  ),
                  if (_deduper.closeRequested)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Close requested for this tab (browser may block window.close).',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Section(
                title: 'Tabs (oldest first)',
                expandChild: true,
                child: ListView.builder(
                  itemCount: tabs.length,
                  itemBuilder: (context, index) {
                    final t = tabs[index];
                    final isSelf = t.id == _deduper.id;

                    return ListTile(
                      dense: true,
                      title: Text(isSelf ? '${t.id} (self)' : t.id),
                      subtitle: Text(
                        'created=${t.createdAt.toIso8601String()} seen=${t.lastSeenAt.toIso8601String()}',
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
