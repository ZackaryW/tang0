import 'package:flutter_test/flutter_test.dart';
import 'package:tang0/tang0.dart';

import '../support/context.dart';
import '../support/fake_platform.dart';

void main() {
  group('T0TabDeduper', () {
    test('oldest tabs are kept, excess tabs are asked to close', () async {
      final hub = FakeHub();
      final d1 = T0TabDeduper(
          scope: 't', context: ctx(hub, 'A'), maxTabs: 2, keepTabs: 1);
      hub.advance(10);
      final d2 = T0TabDeduper(
          scope: 't', context: ctx(hub, 'B'), maxTabs: 2, keepTabs: 1);
      hub.advance(10);
      final d3 = T0TabDeduper(
          scope: 't', context: ctx(hub, 'C'), maxTabs: 2, keepTabs: 1);
      await pumpEventQueue();

      expect(d1.tabCount, 3);
      expect(d1.closeRequested, isFalse); // oldest — keeper
      expect(d3.closeRequested, isTrue); // newest, over quota
      d1.dispose();
      d2.dispose();
      d3.dispose();
    });

    test('within quota nobody is asked to close', () async {
      final hub = FakeHub();
      final d1 = T0TabDeduper(
          scope: 't', context: ctx(hub, 'A'), maxTabs: 4, keepTabs: 2);
      final d2 = T0TabDeduper(
          scope: 't', context: ctx(hub, 'B'), maxTabs: 4, keepTabs: 2);
      await pumpEventQueue();

      expect(d1.closeRequested, isFalse);
      expect(d2.closeRequested, isFalse);
      d1.dispose();
      d2.dispose();
    });
  });
}
