import 'dart:async';

import 'package:tarlan_bank/utils/overlay_helper.dart';

/// Plain Dart replacement for the old GetxService. Kept as a small service so
/// legacy-style callers have a migration path; new code should use Riverpod
/// auth/auth-state providers instead of this stream bag.
class AuthStateService {
  final StreamController<bool> _authenticated =
      StreamController<bool>.broadcast();
  final StreamController<bool> _checking = StreamController<bool>.broadcast();
  final StreamController<bool> _loggedIn = StreamController<bool>.broadcast();
  final StreamController<String?> _targetRoute =
      StreamController<String?>.broadcast();

  bool isAuthenticated = false;
  bool isCheckingAuth = false;
  bool isLoggedIn = false;
  Map<String, dynamic> targetArguments = const {};

  Stream<bool> get isAuthenticatedStream => _authenticated.stream;
  Stream<bool> get isLoggedInStream => _loggedIn.stream;
  Stream<String?> get targetRouteStream => _targetRoute.stream;

  String? get targetRoute => _lastTargetRoute.isEmpty ? null : _lastTargetRoute;
  String _lastTargetRoute = '';

  void setAuthenticated(bool value) {
    isAuthenticated = value;
    _authenticated.add(value);
  }

  void setChecking(bool value) {
    isCheckingAuth = value;
    if (!value) OverlayHelper().hideLoading();
    _checking.add(value);
  }

  void setIsLoggedIn(bool value) {
    isLoggedIn = value;
    _loggedIn.add(value);
  }

  void setTarget(String? route, [Map<String, dynamic>? args]) {
    _lastTargetRoute = route ?? '';
    targetArguments = args ?? const {};
    _targetRoute.add(targetRoute);
  }

  void setTargetArguments([Map<String, dynamic>? args]) =>
      targetArguments = args ?? const {};

  void clearTarget() {
    _lastTargetRoute = '';
    targetArguments = const {};
    _targetRoute.add(null);
  }

  void dispose() {
    _authenticated.close();
    _checking.close();
    _loggedIn.close();
    _targetRoute.close();
  }
}
