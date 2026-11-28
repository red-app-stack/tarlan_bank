import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/core/errors/app_failure.dart';
import 'package:tarlan_bank/core/router/auth_navigation.dart'
    show destinationAfterAuth;
import 'package:tarlan_bank/core/router/routes.dart' show Routes;
import 'package:tarlan_bank/core/utils/phone_number.dart';
import 'package:tarlan_bank/features/auth/data/password_rule_labels.dart'
    show PasswordRuleLabel;
import 'package:tarlan_bank/features/auth/data/password_validation.dart';
import 'package:tarlan_bank/features/auth/providers/auth_providers.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/views/shared/auth_text_field.dart';

/// Completion step for Google sign-in (and for existing accounts that an app
/// update left with missing profile fields). Same fields as registration, but
/// the password is optional: Google users already have an Auth account and
/// may add an email/password credential if they want email login.
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider).value;
    final user = ref.read(currentUserProvider);
    _name.text = profile?.fullName ?? '';
    _phone.text = profile?.phoneNumber ?? '';
    _email.text = profile?.email.trim().isNotEmpty ?? false
        ? profile!.email
        : (user?.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .completeProfile(
            fullName: _name.text.trim(),
            phoneNumber: _phone.text.trim(),
            email: _email.text.trim(),
            password: _password.text.isEmpty ? null : _password.text,
          );
      if (!mounted) return;
      final target =
          GoRouterState.of(context).uri.queryParameters['target'] ??
          Routes.home;
      final destination = await destinationAfterAuth(ref, target: target);
      if (mounted) context.go(destination);
    } on AppFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = l.unexpectedError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l.completeProfileTitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.completeProfileBody,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 28),
                        AuthTextField(
                          label: l.fullName,
                          controller: _name,
                          icon: Icons.person_outline,
                          validator: (v) =>
                              (v?.trim().split(' ').length ?? 0) < 2
                              ? l.fullNameInvalid
                              : null,
                        ),
                        AuthTextField(
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
                        AuthTextField(
                          label: l.email,
                          controller: _email,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          // Firebase Auth owns the address; only type it
                          // when the provider did not supply one.
                          readOnly: _email.text.trim().isNotEmpty,
                          validator: (v) =>
                              RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                  .hasMatch(v?.trim() ?? '')
                              ? null
                              : l.emailInvalid,
                        ),
                        AuthTextField(
                          label: l.password,
                          controller: _password,
                          icon: Icons.lock_outline,
                          obscure: _obscure,
                          validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            return validateNewPassword(v)?.label(l);
                          },
                          suffix: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            tooltip: _obscure ? l.showPassword : l.hidePassword,
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        AuthTextField(
                          label: l.confirmPassword,
                          controller: _confirm,
                          icon: Icons.lock_outline,
                          obscure: true,
                          validator: (v) =>
                              _password.text.isEmpty || v == _password.text
                              ? null
                              : l.passwordsMismatch,
                        ),
                        Text(
                          l.passwordOptionalHint,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
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
                        FilledButton(
                          onPressed: _busy ? null : _submit,
                          child: _busy
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l.done),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
