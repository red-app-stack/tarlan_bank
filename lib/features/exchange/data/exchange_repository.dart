/// Currency exchange boundary.
///
/// Demo impl: free public rates API cached in Firestore (removes the Node
/// dependency for rates). Returns currency -> rate relative to a base.
///
/// Throws a sealed [AppFailure] on error.
abstract interface class ExchangeRepository {
  /// Rates keyed by currency code (e.g. {'USD': 0.0021, 'EUR': 0.0019}) for [base].
  Future<Map<String, double>> fetchRates({String base = 'KZT'});
}