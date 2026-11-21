import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/features/transactions/providers/transfer_ui_providers.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';

class RecipientIdentity extends StatelessWidget {
  const RecipientIdentity({super.key, required this.state, required this.show});

  final TransferLookupState state;
  final bool show;

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (state.blocked || (state.recipient == null && !state.pending)) {
      return Text(
        l.recipientLookupLimited,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
        ),
      );
    }
    final recipient = state.recipient;
    if (recipient == null) return const SizedBox.shrink();
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          child: Text(recipient.initials, style: theme.textTheme.labelLarge),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            recipient.fullName,
            style: theme.textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
