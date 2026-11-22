import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/features/transactions/providers/transfer_ui_providers.dart';
import 'package:tarlan_bank/features/transactions/widgets/lookup_identity_row.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';

class RecipientIdentity extends StatelessWidget {
  const RecipientIdentity({super.key, required this.state, required this.show});

  final TransferLookupState state;
  final bool show;

  @override
  Widget build(BuildContext context) {
    if (!show) {
      return const SizedBox(height: LookupIdentityRow.rowHeight);
    }
    final l = AppLocalizations.of(context);
    final recipient = state.recipient;

    if (state.pending) {
      return const LookupIdentityRow(loading: true, fallbackText: '');
    }
    if (state.blocked || recipient == null) {
      return LookupIdentityRow(
        loading: false,
        fallbackText: l.recipientLookupLimited,
      );
    }
    return LookupIdentityRow(
      loading: false,
      fullName: recipient.fullName,
      initials: recipient.initials,
      fallbackText: '',
    );
  }
}
