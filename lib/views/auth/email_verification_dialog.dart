import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/core/errors/app_failure.dart';
import 'package:tarlan_bank/features/auth/providers/auth_providers.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';

/// Verification UI adapted from the old Node `showEmailConfirmationDialog`
/// (same 60s resend countdown and Russian strings). Firebase owns the letter:
/// there is no 6-digit code to type — the user confirms the link inemail.
/// Returns true only after Firebase reports `emailVerified == true`.
Future<bool> showEmailVerificationDialog({
  required BuildContext context,
  required String email,
  required bool required,
}) async {
  var verified = false;
  await showDialog<void>(
    context: context,
    barrierDismissible: !required,
    builder: (_) => _EmailVerificationDialog(
      email: email,
      required: required,
      onVerified: () => verified = true,
    ),
  );
  return verified;
}

class _EmailVerificationDialog extends ConsumerStatefulWidget {
  const _EmailVerificationDialog({
    required this.email,
    required this.required,
    required this.onVerified,
  });

  final String email;
  final bool required;
  final VoidCallback onVerified;

  @override
  ConsumerState<_EmailVerificationDialog> createState() =>
      _EmailVerificationDialogState();
}

class _EmailVerificationDialogState
    extends ConsumerState<_EmailVerificationDialog> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _sending = false;
  bool _checking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    final store = await ref.read(verificationCooldownStoreProvider.future);
    if (!mounted) return;
    final left = await store.remaining(widget.email);
    if (!mounted) return;
    setState(() => _remaining = left);
    if (left == Duration.zero) await _send();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remaining = _remaining > const Duration(seconds: 1)
            ? _remaining - const Duration(seconds: 1)
            : Duration.zero;
      });
      if (_remaining == Duration.zero) timer.cancel();
    });
  }

  Future<void> _send() async {
    if (_sending) return;
    if (mounted) {
      setState(() {
        _sending = true;
        _error = null;
      });
    }
    try {
      final store = await ref.read(verificationCooldownStoreProvider.future);
      final left = await store.remaining(widget.email);
      if (left > Duration.zero) {
        if (mounted) setState(() => _remaining = left);
        return;
      }
      await ref.read(authRepositoryProvider).sendEmailVerification();
      await store.recordSend(widget.email);
      if (mounted) setState(() => _remaining = const Duration(seconds: 60));
      _startTimer();
    } on AppFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _check() async {
    if (_checking) return;
    final l = AppLocalizations.of(context);
    if (mounted) {
      setState(() {
        _checking = true;
        _error = null;
      });
    }
    try {
      final verified = await ref
          .read(authRepositoryProvider)
          .refreshEmailVerification();
      if (!mounted) return;
      if (verified) {
        ref.invalidate(authStateProvider);
        Navigator.of(context).pop();
        widget.onVerified();
      } else {
        setState(() => _error = l.verifyNotConfirmed);
      }
    } on AppFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _cancel() async {
    if (widget.required) {
      await ref.read(authRepositoryProvider).logout();
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.verifyTitle, style: theme.textTheme.titleLarge),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.verifyBody(widget.email)),
          const SizedBox(height: 12),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton(
            onPressed: _checking ? null : _check,
            child: _checking
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l.verifyCheck),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: (_sending || _remaining > Duration.zero) ? null : _send,
            child: Text(
              _remaining > Duration.zero
                  ? l.verifyResendIn(_remaining.inSeconds)
                  : l.verifyResend,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _cancel,
          child: Text(widget.required ? l.verifySignOut : l.verifyLater),
        ),
      ],
    );
  }
}
