/// All route names live here; both routers and every screen import this file.
class Routes {
  /// Tab roots — order matches StatefulShellBranch order in app_router.dart.
  static const home = '/home';
  static const payments = '/payments';
  static const transfers = '/transfers';
  static const accounts = '/accounts';
  static const menu = '/menu';

  /// Nested routes inside the shell branches.
  static const paymentsHistory = '/payments/history';
  static const transfersPhone = '/transfers/phone';
  static const transfersSelf = '/transfers/self';
  static const transfersCard = '/transfers/card';
  static const transfersConvert = '/transfers/convert';
  static const transfersQr = '/transfers/qr';
  static const transfersHistory = '/transfers/history';
  static const transfersDetails = '/transfers/details';
  static const accountsCreate = '/accounts/create';
  static const accountsDetails = '/accounts/details';
  static const menuSecurity = '/menu/security';
  static const menuInvestments = '/menu/investments';
  static const menuProfile = '/menu/profile';
  static const menuChatbot = '/menu/chatbot';
  static const menuChangePassword = '/menu/changePassword';
  static const menuLinkedAccounts = '/menu/linkedAccounts';

  /// Legacy aliases kept until every caller is migrated.

  static const loading = '/loading';

  static const main = '/main';
  // static const home = '/home';

  static const login = '/login';

  /// Firebase re-confirmation for sensitive actions (e.g. account deletion).
  static const reauth = '/reauth';
  static const codeEntering = '/codeEntering';
  static const biometricSetup = '/biometricSetup';
  static const faceVerify = '/faceVerify';

  /// Firebase App Link callbacks — registered so GetX's Nav2 delegate does
  /// not render its default 'Route not found' page for an incoming link.
  static const verifyLink = '/__/auth/links';
  static const verifyAction = '/__/auth/action';

  static const chatbot = '/chatbot';
  static const profile = '/profile';

  static const cardDetails = '/cardDetails';

  static const paymentHistory = '/paymentHistory';
  static const transferHistory = '/transferHistory';
  static const transferDetails = '/transferDetails';
  static const createAccount = '/createAccount';
  static const investments = '/investments';
  static const changePassword = '/changePassword';
  static const linkedAccounts = '/linkedAccounts';

  static const phoneTransfer = '/phoneTransfer';
  static const selfTransfer = '/selfTransfer';
  static const cardTransfer = '/cardTransfer';
  static const convertation = '/convertation';
  static const qrTransfer = '/qrTransfer';

  static const securitySettings = '/securitySettings';
  // static const userChat = '/userChat';
}

/// Marker on overlay-route pushes so redirect knows the shell is underneath.
const String shellOverlayMarker = 'fromShell';

bool isShellOverlayPush(Object? extra) =>
    extra is Map && extra[shellOverlayMarker] == true;

/// Shell chrome is shown only on the five branch root locations. Every nested
/// path (history, details, settings, placeholders, …) renders its own header.
const branchRootLocations = {
  Routes.payments,
  Routes.transfers,
  Routes.home,
  Routes.accounts,
  Routes.menu,
};

bool showShellTopBarFor(String location) =>
    branchRootLocations.contains(location);
