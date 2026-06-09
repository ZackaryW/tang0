import 'package:flutter/material.dart';
import 'package:tang0/tang0.dart';

/// A single-page demo. Run with `flutter run -d chrome` and open the same URL in
/// several browser tabs to watch presence, leadership, a synced counter, and
/// tab-dedup coordinate live across them.
void main() => runApp(const Tang0Demo());

class Tang0Demo extends StatelessWidget {
  const Tang0Demo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'tang0 demo',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});
  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  late final T0Presence _presence;
  late final T0Leader _leader;
  late final T0SyncVar<int> _counter;
  late final T0TabDeduper _dedup;

  @override
  void initState() {
    super.initState();
    _presence = T0Presence('demo', meta: {'opened': DateTime.now().toIso8601String()});
    _leader = T0Leader('demo');
    _counter = T0SyncVar<int>(scope: 'demo', key: 'counter', initialValue: 0);
    _dedup = T0TabDeduper(scope: 'demo-tabs', maxTabs: 3, keepTabs: 2);
  }

  @override
  void dispose() {
    _presence.dispose();
    _leader.dispose();
    _counter.dispose();
    _dedup.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('tang0 — cross-tab demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _LeaderCard(leader: _leader),
          const SizedBox(height: 12),
          _CounterCard(counter: _counter),
          const SizedBox(height: 12),
          _PresenceCard(presence: _presence),
          const SizedBox(height: 12),
          _DedupCard(dedup: _dedup),
        ],
      ),
    );
  }
}

class _LeaderCard extends StatelessWidget {
  const _LeaderCard({required this.leader});
  final T0Leader leader;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: leader.onLeadershipHint,
      initialData: leader.isLeader,
      builder: (context, snap) {
        final isLeader = snap.data ?? false;
        return Card(
          color: isLeader ? Colors.green.shade100 : null,
          child: ListTile(
            leading: Icon(isLeader ? Icons.star : Icons.star_border),
            title: const Text('Leader election (Web Locks)'),
            subtitle: Text(isLeader
                ? 'This tab is the leader. Close it to watch another tab take over.'
                : 'Another tab is the leader.'),
          ),
        );
      },
    );
  }
}

class _CounterCard extends StatelessWidget {
  const _CounterCard({required this.counter});
  final T0SyncVar<int> counter;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ValueListenableBuilder<int>(
          valueListenable: counter,
          builder: (context, value, _) {
            return Row(
              children: [
                const Expanded(child: Text('Synced counter (LWW + catch-up)')),
                IconButton(
                  onPressed: () => counter.value = value - 1,
                  icon: const Icon(Icons.remove),
                ),
                Text('$value', style: Theme.of(context).textTheme.headlineSmall),
                IconButton(
                  onPressed: () => counter.value = value + 1,
                  icon: const Icon(Icons.add),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PresenceCard extends StatelessWidget {
  const _PresenceCard({required this.presence});
  final T0Presence presence;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: AnimatedBuilder(
        animation: presence,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.groups),
                title: Text('Presence — ${presence.count} tab(s) open'),
              ),
              for (final m in presence.members)
                ListTile(
                  dense: true,
                  leading: Icon(m.isSelf ? Icons.person : Icons.person_outline),
                  title: Text(m.isSelf ? '${m.tabId} (you)' : m.tabId),
                  subtitle: Text('${m.meta}'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DedupCard extends StatelessWidget {
  const _DedupCard({required this.dedup});
  final T0TabDeduper dedup;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: AnimatedBuilder(
        animation: dedup,
        builder: (context, _) {
          final over = dedup.closeRequested;
          return ListTile(
            leading: Icon(over ? Icons.warning_amber : Icons.tab),
            tileColor: over ? Colors.red.shade100 : null,
            title: Text('Tab dedup — ${dedup.tabCount} open (max 3, keep 2)'),
            subtitle: Text(over
                ? 'This tab is over quota and was asked to close.'
                : 'Within quota.'),
          );
        },
      ),
    );
  }
}
