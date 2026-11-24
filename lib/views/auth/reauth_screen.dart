import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/core/errors/app_failure.dart';
import 'package:tarlan_bank/core/router/routes.dart' show Routes;
import 'package:tarlan_bank/features/auth/data/reauth_method.dart';
import 'package:tarlan_bank/features/auth/providers/account_deletion.dart';
import 'package:tarlan_bank/features/auth/providers/auth_providers.dart';
import 'package:tarlan_bank/features/auth/providers/reauth_provider.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';

/// Minimal Firebase re-confirmation for a sensitive action that hit
/// `requires-recent-login`. Deliberately NOT the normal login: no PIN, no face,
/// no registration, no guest sign-in, and the email is fixed to the current
/// account. Field styling mirrors the login page so the two screens feel like
/// one flow.
class ReauthScreen extends ConsumerStatefulWidget {
  const ReauthScreen({super.key});

  @override
  ConsumerState<ReauthScreen> createState() => _ReauthScreenState();
}

class _ReauthScreenState extends ConsumerState<ReauthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  Set<ReauthMethod> _methods = const {};
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email.text = ref.read(currentUserProvider)?.email?.trim() ?? '';
    if (ref.read(pendingReauthActionProvider) == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(Routes.menuSecurity);
      });
      return;
    }
    // availableReauthMethods is async; start it now and rebuild when ready.
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    try {
      final methods = await ref
          .read(authRepositoryProvider)
          .availableReauthMethods();
      if (mounted) setState(() => _methods = methods);
    } on AppFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      await _complete();
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(
        () => _error = switch (e.message) {
          'Invalid email or password' => AppLocalizations.of(
            context,
          ).reauthInvalidPassword,
          _ => e.message,
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).unexpectedError);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitPassword() async {
    if (_formKey.currentState?.validate() != true) return;
    await _run(
      () => ref
          .read(authRepositoryProvider)
          .reauthenticateWithPassword(
            email: _email.text.trim(),
            password: _password.text,
          ),
    );
  }

  Future<void> _submitGoogle() =>
      _run(() => ref.read(authRepositoryProvider).reauthenticateWithGoogle());

  Future<void> _complete() async {
    ref.read(pendingReauthActionProvider.notifier).clear();
    await deleteAccountAndReset(ref);
    if (mounted) context.go(Routes.login);
  }

  void _cancel() {
    ref.read(pendingReauthActionProvider.notifier).clear();
    context.go(Routes.menuSecurity);
  }

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
                        l.reauthTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.reauthBody,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _field(
                        label: l.email,
                        controller: _email,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        enabled: false,
                      ),
                      if (_methods.contains(ReauthMethod.password)) ...[
                        _passwordField(theme, l),
                      ],
                      if (_methods.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            l.reauthNoMethod,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
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
                      if (_methods.contains(ReauthMethod.password))
                        FilledButton(
                          onPressed: _busy ? null : _submitPassword,
                          child: _busy
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l.reauthConfirm),
                        ),
                      if (_methods.contains(ReauthMethod.password) &&
                          _methods.contains(ReauthMethod.google)) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: Divider(color: theme.dividerColor)),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                l.orDivider,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                            Expanded(child: Divider(color: theme.dividerColor)),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (_methods.contains(ReauthMethod.google))
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _submitGoogle,
                          icon: const Icon(Icons.g_mobiledata, size: 28),
                          label: Text(l.signInGoogle),
                        ),
                      TextButton(
                        onPressed: _busy ? null : _cancel,
                        child: Text(l.cancel),
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
      label: l.password,
      controller: _password,
      icon: Icons.lock_outline,
      obscure: _obscure,
      enabled: !_busy,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _submitPassword(),
      suffix: IconButton(
        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
        tooltip: _obscure ? l.showPassword : l.hidePassword,
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
      validator: (v) => (v == null || v.isEmpty) ? l.passwordRequired : null,
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscure = false,
    bool enabled = true,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
    Widget? suffix,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        autocorrect: !obscure,
        enableSuggestions: !obscure,
        enabled: enabled,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          suffixIcon: suffix,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
          ),
          fillColor: theme.colorScheme.surfaceContainerLowest,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
