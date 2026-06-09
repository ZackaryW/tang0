import 'package:flutter_test/flutter_test.dart';
import 'package:tang0/tang0.dart';

import '../support/context.dart';
import '../support/fake_platform.dart';

void main() {
  group('T0Hydrator', () {
    test('a new tab hydrates from a peer snapshot', () async {
      final hub = FakeHub();
      final existing = T0Hydrator('s', context: ctx(hub, 'A'));
      existing.provide(() => {'count': 3});

      final fresh = T0Hydrator('s', context: ctx(hub, 'B'));
      final snap = await fresh.hydrate(timeout: const Duration(seconds: 1));

      expect(snap, {'count': 3});
      existing.dispose();
      fresh.dispose();
    });

    test('falls back to persisted storage when no peer answers', () async {
      final hub = FakeHub();
      final a = T0Hydrator('s', context: ctx(hub, 'A'));
      a.persist({'count': 9});
      a.dispose();

      // A lone new tab: no peer to answer, must use the stored snapshot.
      final fresh = T0Hydrator('s', context: ctx(hub, 'B'));
      final snap = await fresh.hydrate(timeout: const Duration(milliseconds: 100));

      expect(snap, {'count': 9});
      fresh.dispose();
    });
  });
}
