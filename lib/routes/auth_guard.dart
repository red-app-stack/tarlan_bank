import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import '../services/auth_state_service.dart';

class AuthGuard extends StatefulWidget {
  final Widget child;
  final String targetRoute;
  final Map<String, dynamic>? targetArguments;

  const AuthGuard({
    super.key,
    required this.child,
    required this.targetRoute,
    this.targetArguments,
  });

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  final AuthStateService _authService = Get.find();
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    _delayedAuthCheck();
  }

  void _delayedAuthCheck() async {
    // Wait for animation (300ms) + buffer (100ms)
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _performAuthCheck();
  }

  void _performAuthCheck() {
    if (_hasChecked) return;
    _hasChecked = true;

    // Wait for async auth verification to complete
    if (_authService.isCheckingAuth) {
      Future.delayed(const Duration(milliseconds: 100), _delayedAuthCheck);
      return;
    }

    // Now perform the redirect using EXPLICIT route
    if (!_authService.isAuthenticated) {
      _redirectToLogin();
    } else if (!_authService.isLoggedIn) {
      _redirectToPin();
    }
  }

  void _redirectToLogin() {
    // Use the widget's targetRoute, NOT Get.currentRoute
    Get.toNamed('/login', arguments: {
      'targetRoute': widget.targetRoute,
      'targetArguments': widget.targetArguments ?? {},
    });
  }

  void _redirectToPin() {
    Get.toNamed('/codeEntering', arguments: {
      'isCreatingCode': false,
      'targetRoute': widget.targetRoute,
      'targetArguments': widget.targetArguments ?? {},
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isAuthed = _authService.isAuthenticated && _authService.isLoggedIn;
      return isAuthed ? widget.child : _buildPlaceholder();
    });
  }

  Widget _buildPlaceholder() {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}
