import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarlan_bank/core/services/app_services.dart';
import 'package:tarlan_bank/core/security/user_data_recovery.dart';
import 'package:tarlan_bank/services/auth_service.dart';
import 'package:tarlan_bank/services/auth_state_service.dart';
import 'package:tarlan_bank/services/dio_manager.dart';
import 'package:tarlan_bank/services/secure_store.dart';
import 'package:tarlan_bank/services/server_service.dart';
import 'package:tarlan_bank/services/user_repository.dart';
import 'package:tarlan_bank/services/verification_service.dart';

/// Single read seam for every long-lived service created in AppServices.init.
/// No service reaches for a global service locator; constructors take their
/// dependencies explicitly. These providers are the only swap point.
final secureStorageProvider = Provider((ref) => AppServices.secureStorage);
final serverProvider = Provider<Server>((ref) => AppServices.server);
final dioManagerProvider = Provider<DioManager>(
  (ref) => AppServices.dioManager,
);
final secureStoreProvider = Provider<SecureStore>(
  (ref) => AppServices.secureStore,
);

final authStateServiceProvider = Provider<AuthStateService>(
  (ref) => AppServices.authStateService,
);

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => AppServices.userRepository,
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AppServices.authService,
);

final verificationServiceProvider = Provider<VerificationService>(
  (ref) => AppServices.verificationService,
);

final userDataRecoveryProvider = Provider<UserDataRecovery>((ref) {
  return UserDataRecovery(
    ref.watch(secureStoreProvider),
    onCleared: () => ref.read(userRepositoryProvider).currentUser = null,
  );
});
