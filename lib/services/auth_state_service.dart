import 'package:tarlan_bank/utils/overlay_helper.dart';
import 'package:get/get.dart';

class AuthStateService extends GetxService {
  // Private state (enforce controlled mutations)
  final RxBool _isAuthenticated = false.obs; // token valid/invalid/notfound
  final RxBool _isChecking = false.obs; //checking token
  final RxString _targetRoute = ''.obs; // '/createAccount'
  final RxMap<String, dynamic> _targetArgs =
      <String, dynamic>{}.obs; // {'foo':'bar'}
  final RxBool _isLoggedIn = false.obs; // local auth

  // Public readonly observables
  bool get isAuthenticated => _isAuthenticated.value;
  bool get isCheckingAuth => _isChecking.value;
  bool get isLoggedIn => _isLoggedIn.value;

  Stream<bool> get isAuthenticatedStream => _isAuthenticated.stream;
  Stream<bool> get isLoggedInStream => _isLoggedIn.stream;

  String? get targetRoute =>
      _targetRoute.value.isEmpty ? null : _targetRoute.value;
  Map<String, dynamic>? get targetArguments => _targetArgs.toJson();
  Stream<String?> get targetRouteStream => _targetRoute.stream;

  // setters

  void setAuthenticated(bool value) => _isAuthenticated.value = value;
  void setChecking(bool value) {
    if (!value) OverlayHelper().hideLoading();
    _isChecking.value = value;
  }

  void setIsLoggedIn(bool value) => _isLoggedIn.value = value;

  void setTarget(String? route, [Map<String, dynamic>? args]) {
    _targetRoute.value = route ?? '';
    _targetArgs.assignAll(args ?? {});
  }

  void setTargetArguments([Map<String, dynamic>? args]) {
    _targetArgs.assignAll(args ?? {});
  }

  void clearTarget() {
    _targetRoute.value = '';
    _targetArgs.clear();
  }
}
