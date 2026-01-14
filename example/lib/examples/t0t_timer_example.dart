// ignore_for_file: implementation_imports

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tang0/templates/t0t_timer.dart';

import 'section.dart';

class T0TTimerExampleApp extends StatelessWidget {
  const T0TTimerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'tang0: T0T timer',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const T0TTimerExamplePage(),
    );
  }
}

class T0TTimerExamplePage extends StatefulWidget {
  const T0TTimerExamplePage({super.key});

  @override
  State<T0TTimerExamplePage> createState() => _T0TTimerExamplePageState();
}

class _T0TTimerExamplePageState extends State<T0TTimerExamplePage> {
  late final T0TTimer _timer;

  final List<Map<String, dynamic>> _events = <Map<String, dynamic>>[];
  StreamSubscription<Map<String, dynamic>>? _eventsSub;
  Timer? _uiTicker;

  @override
  void initState() {
    super.initState();

    _timer = T0TTimer(
      serial: 'demo',
      duration: const Duration(minutes: 1),
      meta: <String, dynamic>{'app': 'tang0_timer_example'},
    );

    _eventsSub = _timer.events.listen((event) {
      if (!mounted) return;
      setState(() {
        _events.insert(0, event);
        if (_events.length > 50) {
          _events.removeRange(50, _events.length);
        }
      });
    });

    _uiTicker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _uiTicker?.cancel();
    _eventsSub?.cancel();
    _timer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('T0T timer example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Section(
              title: 'T0T Timer',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Serial: ${_timer.serial}'),
                  Text('Elapsed: ${_timer.elapsed.inMilliseconds}ms'),
                  Text('Remaining: ${_timer.remaining?.inMilliseconds}ms'),
                  Text('Paused: ${_timer.isPaused}  Ended: ${_timer.isEnded}'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      FilledButton(
                        onPressed: _timer.isEnded ? null : _timer.sync,
                        child: const Text('Sync Now'),
                      ),
                      FilledButton.tonal(
                        onPressed: (_timer.isEnded || _timer.isPaused)
                            ? null
                            : _timer.pause,
                        child: const Text('Pause'),
                      ),
                      FilledButton.tonal(
                        onPressed: (_timer.isEnded || !_timer.isPaused)
                            ? null
                            : _timer.resume,
                        child: const Text('Resume'),
                      ),
                      OutlinedButton(
                        onPressed: _timer.isEnded ? null : _timer.end,
                        child: const Text('End'),
                      ),
                      OutlinedButton(
                        onPressed: () => _timer.reset(),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Section(
                title: 'Timer Events (latest first)',
                expandChild: true,
                child: ListView.builder(
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final e = _events[index];
                    final cmd = e['cmd'];
                    final elapsedMs = e['elapsedMs'];
                    final kind = e['kind'];

                    return ListTile(
                      dense: true,
                      title: Text('$cmd'),
                      subtitle: Text('kind=$kind elapsedMs=$elapsedMs'),
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
