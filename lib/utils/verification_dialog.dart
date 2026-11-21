import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/core/providers/service_providers.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/views/shared/app_snack_bar.dart';

/// Email code confirmation dialog used by the code-entry and security flows.
/// The service comes from [verificationServiceProvider]; the dialog itself is
/// a plain showDialog + ConsumerStatefulWidget (kitaphub style), no GetX.
Future<bool> showEmailConfirmationDialog({
  required String email,
  required BuildContext context,
}) async {
  var verified = false;
  await showDialog<void>(
    context: context,
    builder: (_) =>
        _EmailCodeDialog(email: email, onVerified: () => verified = true),
  );
  return verified;
}

class _EmailCodeDialog extends ConsumerStatefulWidget {
  const _EmailCodeDialog({required this.email, required this.onVerified});

  final String email;
  final VoidCallback onVerified;

  @override
  ConsumerState<_EmailCodeDialog> createState() => _EmailCodeDialogState();
}

class _EmailCodeDialogState extends ConsumerState<_EmailCodeDialog> {
  final TextEditingController _codeCtrl = TextEditingController();
  String? _error;
  bool _sending = true;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _send();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (mounted) setState(() => _sending = true);
    try {
      await ref.read(verificationServiceProvider).sendCode(widget.email);
    } catch (_) {
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      showAppSnackBar(
        context,
        endPositionOffset: 1,
        title: l.error,
        message: l.auVerificationSendFailed,
      );
      Navigator.of(context).pop();
      return;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verify() async {
    final l = AppLocalizations.of(context);
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      showAppSnackBar(
        context,
        endPositionOffset: 1,
        title: l.error,
        message: l.auVerificationCodeLengthInvalid,
      );
      return;
    }

    if (_verifying) return;
    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      final result = await ref
          .read(verificationServiceProvider)
          .verifyRemoteCode(code, widget.email, false);
      if (!mounted) return;
      if (result['message'] == 'Code verified successfully') {
        widget.onVerified();
        Navigator.of(context).pop();
        return;
      }
      setState(() {
        _error = result['error'] != null
            ? l.auVerificationInvalidCode
            : l.auVerificationCheckFailed;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = l.auVerificationCheckFailed);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l.auVerificationTitle, style: theme.textTheme.titleLarge),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: theme.textTheme.titleLarge,
            decoration: InputDecoration(
              labelText: l.auVerificationCodeLabel,
              hintText: l.auVerificationCodeHint,
              prefixIcon: const Icon(Icons.security),
              border: const OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          if (_sending) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: _sending || _verifying ? null : _verify,
          child: _verifying
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l.confirm),
        ),
      ],
    );
  }
}
