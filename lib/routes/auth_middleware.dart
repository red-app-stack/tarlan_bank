// middleware/auth_middleware.dart
import 'package:tarlan_bank/services/auth_state_service.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final state = Get.find<AuthStateService>();
    final originalArgs = state.targetArguments ?? {};

    if (!state.isAuthenticated) {
      return RouteSettings(
        name: '/login',
        arguments: {
          'targetRoute': route,
          ...originalArgs,
        },
      );
    }

    if (route != '/codeEntering' && !state.isLoggedIn) {
      return RouteSettings(
        name: '/codeEntering',
        arguments: {
          'targetRoute': route,
          ...originalArgs,
        },
      );
    }

    return null;
  }
}
