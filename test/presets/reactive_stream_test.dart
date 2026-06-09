import 'package:flutter_test/flutter_test.dart';
import 'package:tang0/tang0.dart';

import '../support/context.dart';
import '../support/fake_platform.dart';

void main() {
  group('T0ReactiveStream', () {
    test('events emitted in one tab arrive in another', () async {
      final hub = FakeHub();
      final a = T0ReactiveStream<String>(
          scope: 'e', key: 'evt', context: ctx(hub, 'A'));
      final b = T0ReactiveStream<String>(
          scope: 'e', key: 'evt', context: ctx(hub, 'B'));

      final got = <String>[];
      b.stream.listen(got.add);

      a.add('hello');
      await pumpEventQueue();

      expect(got, ['hello']);
      expect(b.last, 'hello');
      a.dispose();
      b.dispose();
    });

    test('addLocalOnly does not cross tabs', () async {
      final hub = FakeHub();
      final a = T0ReactiveStream<int>(
          scope: 'e', key: 'evt', context: ctx(hub, 'A'));
      final b = T0ReactiveStream<int>(
          scope: 'e', key: 'evt', context: ctx(hub, 'B'));

      final got = <int>[];
      b.stream.listen(got.add);
      a.addLocalOnly(1);
      await pumpEventQueue();

      expect(got, isEmpty);
      a.dispose();
      b.dispose();
    });
  });
}
