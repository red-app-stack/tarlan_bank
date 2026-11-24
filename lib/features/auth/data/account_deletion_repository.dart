import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tarlan_bank/core/utils/phone_number.dart';

import 'account_deletion_plan.dart';

/// Deletes every Firestore document tied to one Firebase uid.
///
/// There is no trusted deletion callable in this demo, so the client does it
/// under owner-only `allow delete` rules. All deletes go through batched
/// commits to avoid leaving a half-deleted account if the network drops
/// mid-way through hundreds of single-document writes.
class AccountDeletionRepository {
  AccountDeletionRepository(this._firestore);

  final FirebaseFirestore _firestore;

  /// Collects owner-scoped docs and deletes them in bounded batches.
  ///
  /// [phone] is optional because Google accounts and malformed profiles may
  /// not have one; the uid-based phone_index query still covers those cases.
  Future<void> deleteAllFor(String uid, {String? phone}) async {
    final paths = <String>['users/$uid', 'face_verifications/$uid'];

    // Single-field equality queries need no composite index.
    for (final entry in const [
      (collection: 'accounts', field: 'ownerId'),
      (collection: 'cards', field: 'ownerId'),
      (collection: 'recipient_index', field: 'uid'),
      (collection: 'phone_index', field: 'uid'),
    ]) {
      await _collect(paths, entry.collection, entry.field, uid);
    }

    // The ledger stores both parties; a user can be on either side.
    for (final field in const ['fromOwnerId', 'toOwnerId']) {
      final snapshot = await _firestore
          .collection('transactions')
          .where(field, isEqualTo: uid)
          .get();
      for (final doc in snapshot.docs) {
        paths.add('transactions/${doc.id}');
      }
    }

    if (phone != null && phone.isNotEmpty) {
      try {
        paths.add('phone_index/${normalizePhone(phone)}');
      } catch (_) {
        // A malformed stored phone must never block deletion.
      }
    }

    for (final batchPaths in chunkDocumentPaths(uniqueDocumentPaths(paths))) {
      final batch = _firestore.batch();
      for (final path in batchPaths) {
        batch.delete(_firestore.doc(path));
      }
      await batch.commit();
    }
  }

  Future<void> _collect(
    List<String> paths,
    String collection,
    String field,
    String uid,
  ) async {
    final snapshot = await _firestore
        .collection(collection)
        .where(field, isEqualTo: uid)
        .get();
    for (final doc in snapshot.docs) {
      paths.add('$collection/${doc.id}');
    }
  }
}
