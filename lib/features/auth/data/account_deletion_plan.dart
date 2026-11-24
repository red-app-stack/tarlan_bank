/// Pure helpers for account deletion. No plugin imports, so they are unit
/// testable without Firebase.
library;

/// Firestore allows at most 500 writes in one batch. Leave headroom for
/// rule overhead and keep chunks predictable.
const int deletionBatchSize = 400;

/// The documents owned by one uid, deduplicated by full path.
///
/// The same doc can be found twice: a phone index is discovered both by the
/// stored phone and by the uid query, and a transaction can appear in both
/// the sender and recipient queries. Batch.delete is idempotent, but a clean
/// plan keeps the operation small and predictable.
List<String> uniqueDocumentPaths(Iterable<String> paths) {
  final unique = paths.toSet().toList()..sort();
  return unique;
}

/// Splits document paths into batches small enough for one commit.
List<List<String>> chunkDocumentPaths(
  Iterable<String> paths, {
  int size = deletionBatchSize,
}) {
  if (size < 1) throw ArgumentError.value(size, 'size', 'must be positive');
  final flat = paths.toList();
  final chunks = <List<String>>[];
  for (var i = 0; i < flat.length; i += size) {
    chunks.add(flat.sublist(i, (i + size).clamp(0, flat.length)));
  }
  return chunks;
}
