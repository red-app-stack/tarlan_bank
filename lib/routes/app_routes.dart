import 'package:tarlan_bank/routes/auth_middleware.dart';
import 'package:tarlan_bank/views/auth/code_entering_screen.dart';
import 'package:tarlan_bank/views/auth/login_screen.dart';
import 'package:tarlan_bank/views/other/card_details_screen.dart';
import 'package:tarlan_bank/views/shared/animations.dart';
import 'package:tarlan_bank/views/transactions/card_transfer_screen.dart';
import 'package:tarlan_bank/views/other/chatbot_screen.dart';
import 'package:tarlan_bank/views/other/create_account_screen.dart';
import 'package:tarlan_bank/views/other/investments_screen.dart';
import 'package:tarlan_bank/views/payments/payment_history_screen.dart';
import 'package:tarlan_bank/views/other/profile_screen.dart';
import 'package:tarlan_bank/views/transactions/transfer_history_screen.dart';
import 'package:tarlan_bank/views/transactions/phone_transfer_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';

import '../views/transactions/convert_screen.dart';
import '../views/transactions/qr_transfer_screen.dart';
import '../views/other/security_settings_screen.dart';
import '../views/transactions/self_transfer_screen.dart';
import '../views/transactions/transaction_details_screen.dart';
import '../views/main/main_screen.dart';

String _createAccountType() {
  final args = Get.arguments;
  if (args is Map) return args['extra']?.toString() ?? 'card';
  return args?.toString() ?? 'card';
}

class Routes {
  static const loading = '/loading';

  static const main = '/main';
  // static const home = '/home';

  static const login = '/login';
  static const codeEntering = '/codeEntering';

  static const chatbot = '/chatbot';
  static const profile = '/profile';

  static const cardDetails = '/cardDetails';

  static const paymentHistory = '/paymentHistory';
  static const transferHistory = '/transferHistory';
  static const transferDetails = '/transferDetails';
  static const createAccount = '/createAccount';
  static const investments = '/investments';

  static const phoneTransfer = '/phoneTransfer';
  static const selfTransfer = '/selfTransfer';
  static const cardTransfer = '/cardTransfer';
  static const convertation = '/convertation';
  static const qrTransfer = '/qrTransfer';

  static const securitySettings = '/securitySettings';
  // static const userChat = '/userChat';
}

class AppRoutes {
  static final routes = [
    GetPage(
      name: Routes.loading,
      page: () => Scaffold(body: Center(child: CircularProgressIndicator())),
    ),
    GetPage(
      name: Routes.main,
      page: () => const MainScreen(),
      customTransition: ZoomFadeTransition(),
      transitionDuration: Duration(milliseconds: 800),
    ),
    GetPage(
      name: Routes.chatbot,
      page: () => ChatBotScreen(),
      customTransition: CustomSlideTransition(),
      transitionDuration: Duration(milliseconds: 300),
    ),
    GetPage(
      name: Routes.profile,
      page: () => ProfileScreen(),
      customTransition: CustomSlideTransitionLeft(),
      transitionDuration: Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.login,
      page: () => LoginPage(),
      customTransition: CustomSlideTransition(),
      transitionDuration: Duration(milliseconds: 300),
    ),
    GetPage(
      name: Routes.codeEntering,
      page: () => CodeEnteringScreen(),
      customTransition: ZoomFadeTransition(),
      transitionDuration: Duration(milliseconds: 300),
    ),
    GetPage(
      name: Routes.cardDetails,
      page: () => CardDetailsScreen(),
      customTransition: ZoomFadeTransition(),
      transitionDuration: Duration(milliseconds: 400),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.phoneTransfer,
      page: () => PhoneTransferScreen(),
      customTransition: ZoomFadeTransition(),
      transitionDuration: Duration(milliseconds: 400),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.cardTransfer,
      page: () => CardTransferScreen(),
      customTransition: ZoomFadeTransition(),
      transitionDuration: Duration(milliseconds: 400),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.selfTransfer,
      page: () => SelfTransferScreen(),
      customTransition: ZoomFadeTransition(),
      transitionDuration: Duration(milliseconds: 400),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.convertation,
      page: () => ConvertScreen(),
      customTransition: ZoomFadeTransition(),
      transitionDuration: Duration(milliseconds: 400),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.qrTransfer,
      page: () => QRTransferScreen(),
      customTransition: ZoomFadeTransition(),
      transitionDuration: Duration(milliseconds: 400),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.paymentHistory,
      page: () => PaymentHistoryScreen(),
      customTransition: ZoomFadeTransition(),
      transitionDuration: Duration(milliseconds: 400),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.transferHistory,
      page: () => TransferHistoryScreen(),
      customTransition: ZoomFadeTransition(),
      transitionDuration: Duration(milliseconds: 400),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.transferDetails,
      page: () => TransactionDetailsScreen(),
      customTransition: ZoomFadeTransition(),
      transitionDuration: Duration(milliseconds: 400),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.createAccount,
      // No Bind.lazyPut: the screen is a Riverpod ConsumerStatefulWidget with
      // local state; a route-pop could previously dispose the GetX controller
      // and reopening the page crashed on Get.find().
      page: () => CreateAccountScreen(accountType: _createAccountType()),
      customTransition: ZoomFadeTransition(),
      transitionDuration: Duration(milliseconds: 400),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.securitySettings,
      page: () => SecuritySettingsScreen(),
      customTransition: CustomSlideTransition(),
      transitionDuration: Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.investments,
      page: () => InvestmentsScreen(),
      customTransition: ZoomFadeTransition(),
      transitionDuration: Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
