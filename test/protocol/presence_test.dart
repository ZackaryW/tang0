import 'package:flutter_test/flutter_test.dart';
import 'package:tang0/tang0.dart';

import '../support/context.dart';
import '../support/fake_platform.dart';

void main() {
  group('T0Presence', () {
    test('a new tab learns the full group immediately on join', () async {
      final hub = FakeHub();
      final pa = T0Presence('room', context: ctx(hub, 'A'));
      final pb = T0Presence('room', context: ctx(hub, 'B'));
      await pumpEventQueue();

      expect(pa.count, 2);
      expect(pb.count, 2);
      pa.dispose();
      pb.dispose();
    });

    test('propagates per-tab metadata (awareness)', () async {
      final hub = FakeHub();
      final pa = T0Presence('room', context: ctx(hub, 'A'), meta: {'name': 'Ada'});
      final pb = T0Presence('room', context: ctx(hub, 'B'));
      await pumpEventQueue();

      final adaSeenByB =
          pb.members.firstWhere((m) => m.meta['name'] == 'Ada', orElse: () => pb.self);
      expect(adaSeenByB.meta['name'], 'Ada');
      pa.dispose();
      pb.dispose();
    });

    test('prunes a tab not heard from within ttl', () async {
      final hub = FakeHub();
      final pa = T0Presence('room', context: ctx(hub, 'A'),
          ttl: const Duration(seconds: 6));
      final pb = T0Presence('room', context: ctx(hub, 'B'),
          ttl: const Duration(seconds: 6));
      await pumpEventQueue();
      expect(pa.count, 2);

      hub.advance(7000); // B goes silent past ttl
      pa.beat();
      expect(pa.count, 1);
      pa.dispose();
      pb.dispose();
    });

    test('graceful leave removes the tab at once', () async {
      final hub = FakeHub();
      final pa = T0Presence('room', context: ctx(hub, 'A'));
      final pb = T0Presence('room', context: ctx(hub, 'B'));
      await pumpEventQueue();
      expect(pa.count, 2);

      pb.dispose(); // broadcasts leave
      await pumpEventQueue();
      expect(pa.count, 1);
      pa.dispose();
    });
  });
}
