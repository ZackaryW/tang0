import 'package:flutter_test/flutter_test.dart';
import 'package:tang0/tang0.dart';

import '../support/context.dart';
import '../support/fake_platform.dart';

void main() {
  group('T0Leader', () {
    test('exactly one tab is leader at a time', () {
      final hub = FakeHub();
      final la = T0Leader('res', context: ctx(hub, 'A'));
      final lb = T0Leader('res', context: ctx(hub, 'B'));

      expect(la.isLeader, isTrue);
      expect(lb.isLeader, isFalse);
      la.dispose();
      lb.dispose();
    });

    test('leadership transfers when the leader leaves', () async {
      final hub = FakeHub();
      final la = T0Leader('res', context: ctx(hub, 'A'));
      final lb = T0Leader('res', context: ctx(hub, 'B'));
      expect(lb.isLeader, isFalse);

      la.dispose(); // releases the lock
      await pumpEventQueue();

      expect(lb.isLeader, isTrue);
      lb.dispose();
    });

    test('runIfLeader only runs on the leader', () async {
      final hub = FakeHub();
      final la = T0Leader('res', context: ctx(hub, 'A'));
      final lb = T0Leader('res', context: ctx(hub, 'B'));

      expect(await la.runIfLeader(() => 'did'), 'did');
      expect(await lb.runIfLeader(() => 'did'), isNull);
      la.dispose();
      lb.dispose();
    });

    test('fails loud when Web Locks are unavailable', () async {
      final hub = FakeHub()..locksAvailable = false;
      final l = T0Leader('res', context: ctx(hub, 'A'));

      expect(l.available, isFalse);
      expect(l.isLeader, isFalse);
      await expectLater(
        l.runIfLeader(() => 1),
        throwsA(isA<T0LeaderUnavailable>()),
      );
      l.dispose();
    });
  });
}
