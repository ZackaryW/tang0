import 'package:flutter_test/flutter_test.dart';
import 'package:tang0/tang0.dart';

import '../support/context.dart';
import '../support/fake_platform.dart';

void main() {
  group('T0SoftLock', () {
    test('only one holder while the lease is fresh', () async {
      final hub = FakeHub();
      final a = T0SoftLock('x', context: ctx(hub, 'A'),
          electionWindow: Duration.zero);
      final b = T0SoftLock('x', context: ctx(hub, 'B'),
          electionWindow: Duration.zero);

      expect(await a.tryHold(), isTrue);
      expect(await b.tryHold(), isFalse);
      a.dispose();
      b.dispose();
    });

    test('the lease frees up after release', () async {
      final hub = FakeHub();
      final a = T0SoftLock('x', context: ctx(hub, 'A'),
          electionWindow: Duration.zero);
      final b = T0SoftLock('x', context: ctx(hub, 'B'),
          electionWindow: Duration.zero);

      expect(await a.tryHold(), isTrue);
      a.release();
      expect(await b.tryHold(), isTrue);
      b.dispose();
    });

    test('a stale (expired) lease can be taken over', () async {
      final hub = FakeHub();
      final a = T0SoftLock('x', context: ctx(hub, 'A'),
          lease: const Duration(seconds: 6), electionWindow: Duration.zero);
      final b = T0SoftLock('x', context: ctx(hub, 'B'),
          lease: const Duration(seconds: 6), electionWindow: Duration.zero);

      expect(await a.tryHold(), isTrue);
      // Simulate a crashed holder: it never releases and stops heartbeating.
      hub.advance(7000); // its lease expires
      expect(await b.tryHold(), isTrue);
      a.dispose();
      b.dispose();
    });
  });
}
