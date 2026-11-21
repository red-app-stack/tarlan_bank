import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/core/router/app_navigation.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/core/router/routes.dart' show Routes;

/// Shown to the GetX router when Android delivers a Firebase verification
/// App Link as the initial route. The real work is done by `handleEmailLink`
/// (oobCode → applyActionCode → reload → offAllNamed('/main')); this screen
/// only prevents the default GetX "Route not found" page and gives the user a
/// way out if the link could not be applied.
class VerificationLinkScreen extends ConsumerWidget {
  const VerificationLinkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l.verifyTitle),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => navigateResetGlobal(Routes.main),
              child: Text(l.openApp),
            ),
          ],
        ),
      ),
    );
  }
}
