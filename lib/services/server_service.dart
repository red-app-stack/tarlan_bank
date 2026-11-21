import 'package:tarlan_bank/services/service_url_resolver.dart';

class Server {
  Server({ServiceUrlResolver? resolver})
    : _resolver = resolver ?? ServiceUrlResolver();

  final ServiceUrlResolver _resolver;
  String _currentBaseUrl = '';
  Future<String>? _ongoingCheck;
  int _sequentialFailures = 0;
  static const int maxSequentialFailures = 3;

  String get currentBaseUrl => _currentBaseUrl;

  void recordSuccess() => _sequentialFailures = 0;

  void recordFailure() {
    _sequentialFailures++;
    if (_sequentialFailures >= maxSequentialFailures) {
      _currentBaseUrl = '';
      _sequentialFailures = 0;
    }
  }

  Future<String> getBaseUrl() async {
    if (_currentBaseUrl.isNotEmpty) return _currentBaseUrl;
    final ongoing = _ongoingCheck;
    if (ongoing != null) return await ongoing;

    _ongoingCheck = _resolve();
    try {
      return await _ongoingCheck!;
    } finally {
      _ongoingCheck = null;
    }
  }

  Future<String> _resolve() async {
    final url = await _resolver.resolve();
    _currentBaseUrl = url;
    recordSuccess();
    return url;
  }
}
