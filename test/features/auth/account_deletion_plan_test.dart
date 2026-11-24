import 'package:flutter_test/flutter_test.dart';

import 'package:tarlan_bank/features/auth/data/account_deletion_plan.dart';

void main() {
  group('uniqueDocumentPaths', () {
    test('deduplicates the same doc found by phone and by uid', () {
      final paths = uniqueDocumentPaths([
        'phone_index/+77001234567',
        'users/uid-1',
        'phone_index/+77001234567',
        'transactions/tx-2',
        'transactions/tx-1',
      ]);
      expect(paths, [
        'phone_index/+77001234567',
        'transactions/tx-1',
        'transactions/tx-2',
        'users/uid-1',
      ]);
    });

    test('empty input stays empty', () {
      expect(uniqueDocumentPaths(const []), isEmpty);
    });
  });

  group('chunkDocumentPaths', () {
    test('splits into batches under the Firestore write limit', () {
      final paths = List.generate(805, (i) => 'accounts/$i');
      final chunks = chunkDocumentPaths(paths);
      expect(chunks.map((c) => c.length), [400, 400, 5]);
      expect(chunks.expand((c) => c).toList(), paths);
    });

    test('honours a custom size and rejects an invalid one', () {
      expect(chunkDocumentPaths(['a', 'b', 'c'], size: 2).length, 2);
      expect(chunkDocumentPaths(const [], size: 2), isEmpty);
      expect(
        () => chunkDocumentPaths(['a'], size: 0),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
