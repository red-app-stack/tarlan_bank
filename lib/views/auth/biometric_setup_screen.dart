import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

import 'package:tarlan_bank/core/providers/service_providers.dart';
import 'package:tarlan_bank/core/router/pin_gate.dart';
import 'package:tarlan_bank/core/router/routes.dart' show Routes;
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/views/shared/app_snack_bar.dart';
import 'package:tarlan_bank/views/shared/user_settings.dart';

/// One-time full-screen offer shown right after the access code is created.
/// Declining or continuing both land in the app; enabling runs a real
/// biometric prompt before the setting is saved.
class BiometricSetupScreen extends ConsumerStatefulWidget {
  const BiometricSetupScreen({super.key, this.targetRoute});

  final String? targetRoute;

  @override
  ConsumerState<BiometricSetupScreen> createState() =>
      _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends ConsumerState<BiometricSetupScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _enabled = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await ref.read(secureStoreProvider).loadSettings();
    if (!mounted || settings?.useBiometrics != true) return;
    setState(() => _enabled = true);
  }

  Future<void> _enable() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l = AppLocalizations.of(context);
    try {
      final ok = await _auth.authenticate(
        localizedReason: l.bioSetupReason,
        biometricOnly: true,
        sensitiveTransaction: true,
        authMessages: <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: l.bioSetupTitle,
            cancelButton: l.cancel,
            signInHint: ' ',
          ),
          IOSAuthMessages(
            localizedFallbackTitle: l.bioSetupSkip,
            cancelButton: l.cancel,
          ),
        ],
      );
      if (!mounted || !ok) return;
      final store = ref.read(secureStoreProvider);
      final current = await store.loadSettings() ?? UserSettings.defaults();
      await store.saveSettings(current.copyWith(useBiometrics: true));
      if (mounted) setState(() => _enabled = true);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(
          context,
          fromTop: true,
          endPositionOffset: 1,
          title: AppLocalizations.of(context).error,
          message: AppLocalizations.of(context).bioSetupFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _finish() {
    final target = resumablePinTarget(widget.targetRoute ?? '') ?? Routes.home;
    if (context.mounted) context.go(target);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    // Opaque tint: alpha on the primary stop let the scaffold background
    // bleed through. Keep the accent band narrow but fully opaque.
    final accent =
        Color.lerp(
          theme.colorScheme.surface,
          theme.colorScheme.primary,
          0.08,
        ) ??
        theme.colorScheme.surface;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          gradient: _enabled
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.surface,
                    theme.colorScheme.surface,
                    accent,
                    theme.colorScheme.surface,
                    theme.colorScheme.surface,
                  ],
                  stops: const [0.0, 0.35, 0.4, 0.5, 1.0],
                )
              : null,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _enabled
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : theme.colorScheme.surfaceContainer.withValues(
                            alpha: 0.1,
                          ),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
                    child: Center(
                      child: Icon(
                        Icons.fingerprint_rounded,
                        // SvgPicture.asset(AppIcons.biometry,
                        size: 96,
                        color: _enabled
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  _enabled ? l.bioSetupDoneTitle : l.bioSetupTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _enabled ? l.bioSetupDoneBody : l.bioSetupBody,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : (_enabled ? _finish : _enable),
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _enabled ? l.bioSetupContinue : l.bioSetupEnable,
                          ),
                  ),
                ),
                if (!_enabled)
                  TextButton(
                    onPressed: _busy ? null : _finish,
                    child: Text(l.bioSetupSkip),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
