/// Minimal key/value seam for small device-local records.
///
/// Lives outside the security feature so `SecureStore` can implement it
/// without importing a feature package, and tests can use an in-memory fake.
abstract class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}
