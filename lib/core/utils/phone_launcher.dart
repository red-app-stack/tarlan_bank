import 'package:url_launcher/url_launcher.dart';

import 'package:tarlan_bank/core/errors/app_failure.dart';

/// Developer-side support number. Dummy +7 range until the real number is
/// confirmed by the user — deliberately not a dialable subscriber number.
const String supportPhone = '+700****0000';

/// Pure URI builder, kept separate so the scheme/path contract is testable.
Uri supportTelUri([String number = supportPhone]) =>
    Uri(scheme: 'tel', path: number);

/// Opens the system dialer with the support number. No confirmation dialog by
/// design for now: `tel:` only fills the number on most dialers, it does not
/// place the call by itself.
Future<void> launchSupportDialer() async {
  final uri = supportTelUri();
  if (!await canLaunchUrl(uri)) throw const DialerUnavailableFailure();
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
