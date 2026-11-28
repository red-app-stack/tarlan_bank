import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/core/errors/app_failure.dart';
import 'package:tarlan_bank/core/utils/phone_number.dart';
import 'package:tarlan_bank/features/auth/data/password_validation.dart';
import 'package:tarlan_bank/features/auth/data/password_rule_labels.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/features/auth/providers/auth_providers.dart';
import 'package:tarlan_bank/core/router/auth_navigation.dart'
    show destinationAfterAuth;
import 'package:tarlan_bank/core/router/routes.dart' show Routes;
import 'package:tarlan_bank/core/router/shell_index_provider.dart'
    show pendingAuthIntentProvider;
import 'package:tarlan_bank/views/shared/auth_text_field.dart';

import 'email_verification_dialog.dart';

/// Firebase Auth login (email/password + Google + anonymous guest).
///
/// Replaces the old phone → code → name → password GetX staging flow: the OTP
/// stage belonged to the retired custom-JWT server. Registration keeps the
/// phone/fullName data but collects it in one form (Firebase owns credentials).
///
/// Navigation goes through go_router directly after a successful sign-in.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();

  bool _registering = false;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _fullName.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<bool> _run(Future<void> Function() action) async {
    if (_busy) return false;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      return true;
    } on AppFailure catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).unexpectedError);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
    return false;
  }

  /// Registration requires verification before entering the app; on login we
  /// prompt but allow "Позже" so existing test accounts are not locked out.
  Future<void> _verifyAfterAuth({required bool register}) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null || user.isAnonymous || user.emailVerified) return;
    final verified = await showEmailVerificationDialog(
      context: context,
      email: user.email?.trim().isNotEmpty == true
          ? user.email!.trim()
          : _email.text.trim(),
      required: register,
    );
    if (!verified && register) return; // dialog already signed out
    await _done();
  }

  Future<void> _done({bool anonymous = false}) async {
    final intent = ref.read(pendingAuthIntentProvider);
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    final target = anonymous
        ? (intent?.origin ?? Routes.home)
        : (intent?.target ?? from ?? Routes.home);
    ref.read(pendingAuthIntentProvider.notifier).clear();
    if (!mounted) return;
    var destination = target;
    if (!anonymous) {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user != null && !user.isAnonymous) {
        // Google's first sign-in writes only the fields it knows, and an app
        // update can add a field to existing accounts. Send those users to
        // the completion form before entering the app.
        bool complete;
        try {
          complete = await ref
              .read(authRepositoryProvider)
              .isProfileComplete(user.uid);
        } catch (_) {
          complete = true; // offline must not lock a signed-in user out
        }
        if (!complete && mounted) {
          context.go(
            Uri(
              path: Routes.completeProfile,
              queryParameters: {'target': target},
            ).toString(),
          );
          return;
        }
      }
      destination = await destinationAfterAuth(ref, target: target);
    }
    if (mounted) context.go(destination);
  }

  Future<void> _submitEmail() async {
    final l = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final register = _registering;
    if (register) {
      final rule = validateNewPassword(_password.text);
      if (rule != null || _password.text != _confirm.text) {
        setState(
          () => _error = rule != null ? rule.label(l) : l.passwordsMismatch,
        );
        return;
      }
    }
    final ok = await _run(() async {
      final repo = ref.read(authRepositoryProvider);
      if (register) {
        // Validate the phone before creating any Auth account.
        normalizePhone(_phone.text);
        await repo.register(
          email: _email.text.trim(),
          password: _password.text,
          fullName: _fullName.text.trim(),
          phoneNumber: _phone.text.trim(),
        );
      } else {
        await repo.login(email: _email.text.trim(), password: _password.text);
      }
    });
    if (ok && mounted) await _verifyAfterAuth(register: register);
  }

  Future<void> _submitGoogle() => _run(() async {
    await ref.read(authRepositoryProvider).signInWithGoogle();
    await _done();
  });

  Future<void> _submitGuest() => _run(() async {
    await ref.read(authRepositoryProvider).signInAnonymously();
    await _done(anonymous: true);
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.account_balance_rounded,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l.appName,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _registering ? l.registerTitle : l.loginTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (_registering) ...[
                        _field(
                          label: l.fullName,
                          controller: _fullName,
                          icon: Icons.person_outline,
                          validator: (v) =>
                              (v?.trim().split(' ').length ?? 0) < 2
                              ? l.fullNameInvalid
                              : null,
                        ),
                        _field(
                          label: l.phone,
                          controller: _phone,
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            try {
                              normalizePhone(v ?? '');
                              return null;
                            } on ValidationFailure {
                              return l.phoneInvalid;
                            }
                          },
                        ),
                      ],
                      _field(
                        label: l.email,
                        controller: _email,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(v?.trim() ?? '')
                            ? null
                            : l.emailInvalid,
                      ),
                      _passwordField(theme, l),
                      if (_registering) ...[
                        _field(
                          label: l.confirmPassword,
                          controller: _confirm,
                          icon: Icons.lock_outline,
                          obscure: true,
                          validator: (v) =>
                              v == _password.text ? null : l.passwordsMismatch,
                        ),
                        _passwordHint(theme, l),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _busy ? null : _submitEmail,
                        child: _busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(_registering ? l.signUp : l.signIn),
                      ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                _registering = !_registering;
                                _error = null;
                              }),
                        child: Text(_registering ? l.haveAccount : l.noAccount),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: Divider(color: theme.dividerColor)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              l.orDivider,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          Expanded(child: Divider(color: theme.dividerColor)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _submitGoogle,
                        icon: const Icon(Icons.g_mobiledata, size: 28),
                        label: Text(l.signInGoogle),
                      ),
                      const SizedBox(height: 4),
                      TextButton.icon(
                        onPressed: _busy ? null : _submitGuest,
                        icon: const Icon(Icons.person_off_outlined),
                        label: Text(l.continueGuest),
                      ),
                      Text(
                        l.guestHint,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordField(ThemeData theme, AppLocalizations l) {
    return _field(
      label: _registering ? l.passwordRegister : l.password,
      controller: _password,
      icon: Icons.lock_outline,
      obscure: _obscure,
      onChanged: _registering ? (_) => setState(() {}) : null,
      suffix: IconButton(
        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
        tooltip: _obscure ? l.showPassword : l.hidePassword,
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
      validator: (v) => (v == null || v.isEmpty) ? l.passwordRequired : null,
    );
  }

  Widget _passwordHint(ThemeData theme, AppLocalizations l) {
    final failed = passwordRuleFailures(_password.text);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        failed.isEmpty
            ? l.passwordStrong
            : (" • ${failed.map((rule) => rule.label(l)).join('\n • ')}"),
        style: theme.textTheme.bodySmall?.copyWith(
          color: failed.isEmpty
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscure = false,
    void Function(String)? onChanged,
    Widget? suffix,
  }) {
    return AuthTextField(
      label: label,
      controller: controller,
      icon: icon,
      validator: validator,
      keyboardType: keyboardType,
      obscure: obscure,
      onChanged: onChanged,
      suffix: suffix,
    );
  }
}
