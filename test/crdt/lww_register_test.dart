import 'package:flutter_test/flutter_test.dart';
import 'package:tang0/tang0.dart';

void main() {
  group('T0LwwRegister', () {
    test('local set bumps version and always wins', () {
      final reg = T0LwwRegister<int>(0, origin: 'a');
      reg.localSet(5, ts: 100, origin: 'a');
      expect(reg.value, 5);
      expect(reg.version, 1);
    });

    test('higher version dominates regardless of timestamp', () {
      final reg = T0LwwRegister<String>('x', version: 2, ts: 999, origin: 'a');
      final applied =
          reg.merge('y', version: 3, ts: 1, origin: 'b');
      expect(applied, isTrue);
      expect(reg.value, 'y');
    });

    test('lower version is rejected', () {
      final reg = T0LwwRegister<String>('x', version: 5, ts: 1, origin: 'a');
      final applied = reg.merge('y', version: 4, ts: 999, origin: 'b');
      expect(applied, isFalse);
      expect(reg.value, 'x');
    });

    test('same version breaks tie on newer timestamp', () {
      final reg = T0LwwRegister<int>(1, version: 1, ts: 10, origin: 'a');
      expect(reg.merge(2, version: 1, ts: 20, origin: 'a'), isTrue);
      expect(reg.value, 2);
    });

    test('same version and timestamp break tie on larger origin', () {
      final reg = T0LwwRegister<int>(1, version: 1, ts: 10, origin: 'aaa');
      expect(reg.merge(2, version: 1, ts: 10, origin: 'zzz'), isTrue);
      expect(reg.value, 2);
      // and the reverse loses
      expect(reg.merge(3, version: 1, ts: 10, origin: 'aaa'), isFalse);
      expect(reg.value, 2);
    });

    test('two registers converge from concurrent writes in any merge order', () {
      // Tab A and Tab B each write version 1 at the same ts; origin breaks tie.
      final a = T0LwwRegister<int>(0, origin: 'A');
      final b = T0LwwRegister<int>(0, origin: 'B');
      a.localSet(10, ts: 50, origin: 'A'); // ver1, tsA
      b.localSet(20, ts: 50, origin: 'B'); // ver1, tsB

      // exchange
      a.merge(b.value, version: b.version, ts: b.ts, origin: b.origin);
      b.merge(a.value, version: a.version, ts: a.ts, origin: a.origin);

      expect(a.value, b.value); // converged
    });
  });
}
