import 'package:flutter_test/flutter_test.dart';
import 'package:tang0/tang0.dart';

import '../support/context.dart';
import '../support/fake_platform.dart';

void main() {
  group('T0Rpc', () {
    test('request resolves with a peer answer', () async {
      final hub = FakeHub();
      final a = T0Rpc('q', context: ctx(hub, 'A'));
      final b = T0Rpc('q', context: ctx(hub, 'B'));
      b.answer('ping', (params) => 'pong:$params');

      final res = await a.request('ping', params: 'x');
      expect(res, 'pong:x');
      a.dispose();
      b.dispose();
    });

    test('request times out to null when nobody answers', () async {
      final hub = FakeHub();
      final a = T0Rpc('q', context: ctx(hub, 'A'));

      final res = await a.request('ping',
          timeout: const Duration(milliseconds: 50));
      expect(res, isNull);
      a.dispose();
    });
  });
}
