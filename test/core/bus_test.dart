import 'package:flutter_test/flutter_test.dart';
import 'package:tang0/tang0.dart';

import '../support/context.dart';
import '../support/fake_platform.dart';

void main() {
  group('T0Bus', () {
    test('delivers typed messages to other tabs', () async {
      final hub = FakeHub();
      final busA = T0Bus('chan', context: ctx(hub, 'A'));
      final busB = T0Bus('chan', context: ctx(hub, 'B'));

      final received = <Object?>[];
      busB.on('greet', (data, sender) => received.add(data));

      busA.send('greet', 'hi', rateLimited: false);
      await pumpEventQueue();

      expect(received, ['hi']);
    });

    test('never echoes a tab its own messages', () async {
      final hub = FakeHub();
      final busA = T0Bus('chan', context: ctx(hub, 'A'));

      var selfSeen = 0;
      busA.on('greet', (_, __) => selfSeen++);
      busA.send('greet', 'hi', rateLimited: false);
      await pumpEventQueue();

      expect(selfSeen, 0);
    });

    test('routes by message type', () async {
      final hub = FakeHub();
      final busA = T0Bus('chan', context: ctx(hub, 'A'));
      final busB = T0Bus('chan', context: ctx(hub, 'B'));

      final greets = <Object?>[];
      final pings = <Object?>[];
      busB.on('greet', (d, _) => greets.add(d));
      busB.on('ping', (d, _) => pings.add(d));

      busA.send('ping', 1, rateLimited: false);
      await pumpEventQueue();

      expect(greets, isEmpty);
      expect(pings, [1]);
    });
  });
}
