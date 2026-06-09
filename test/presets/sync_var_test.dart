import 'package:flutter_test/flutter_test.dart';
import 'package:tang0/tang0.dart';

import '../support/context.dart';
import '../support/fake_platform.dart';

void main() {
  group('T0SyncVar', () {
    test('a write in one tab propagates to another', () async {
      final hub = FakeHub();
      final va = T0SyncVar<int>(
          scope: 'c', key: 'n', initialValue: 0, context: ctx(hub, 'A'));
      final vb = T0SyncVar<int>(
          scope: 'c', key: 'n', initialValue: 0, context: ctx(hub, 'B'));
      await pumpEventQueue();

      va.value = 42;
      await pumpEventQueue();

      expect(vb.value, 42);
      va.dispose();
      vb.dispose();
    });

    test('applying a remote value does not echo back', () async {
      final hub = FakeHub();
      final va = T0SyncVar<int>(
          scope: 'c', key: 'n', initialValue: 0, context: ctx(hub, 'A'));
      final vb = T0SyncVar<int>(
          scope: 'c', key: 'n', initialValue: 0, context: ctx(hub, 'B'));
      await pumpEventQueue();

      var bWrites = 0;
      vb.addListener(() => bWrites++);
      va.value = 5;
      await pumpEventQueue();

      expect(vb.value, 5);
      expect(bWrites, 1); // single apply, no re-broadcast loop
      va.dispose();
      vb.dispose();
    });

    test('a new tab catches up to the current value', () async {
      final hub = FakeHub();
      final va = T0SyncVar<int>(
          scope: 'c', key: 'n', initialValue: 0, context: ctx(hub, 'A'));
      await pumpEventQueue();
      va.value = 7;
      await pumpEventQueue();

      // A fresh tab opens after the value was already set.
      final vc = T0SyncVar<int>(
          scope: 'c', key: 'n', initialValue: 0, context: ctx(hub, 'C'));
      await pumpEventQueue();

      expect(vc.value, 7);
      va.dispose();
      vc.dispose();
    });
  });
}
