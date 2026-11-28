import 'package:flutter_svg/svg.dart';
import 'package:material_ui/material_ui.dart';

/// Single source of truth for icon asset paths.
///
/// Call sites use these constants, never raw `'assets/icons/...'` strings.
/// Filenames and constant names match one-for-one (snake_case → camelCase).
class AppIcons {
  AppIcons._();

  // ── SHELL (main shell chrome) ────────────────────────────────
  static const String home = 'assets/icons/shell/home.svg';
  static const String homeActive = 'assets/icons/shell/home_active.svg';
  static const String qr = 'assets/icons/shell/qr.svg';
  static const String qrActive = 'assets/icons/shell/qr_active.svg';
  static const String menu = 'assets/icons/shell/menu.svg';
  static const String menuActive = 'assets/icons/shell/menu_active.svg';
  static const String search = 'assets/icons/shell/search.svg';
  static const String searchActive = 'assets/icons/shell/search_active.svg';
  static const String notifications = 'assets/icons/shell/notifications.svg';
  static const String avatarEmpty = 'assets/icons/shell/avatar_empty.svg';

  // ── BUTTON (12px glyphs inside text + icon buttons) ──────────
  static const String add = 'assets/icons/button/add.svg';
  static const String edit = 'assets/icons/button/edit.svg';
  static const String selectAccount = 'assets/icons/button/select_account.svg';
  static const String history = 'assets/icons/button/history.svg';

  // ── WIDGET (dashboard tiles) ──────────────────────────────────
  static const String transfers = 'assets/icons/widget/transfers.svg';
  static const String payments = 'assets/icons/widget/payments.svg';
  static const String deposits = 'assets/icons/widget/deposits.svg';
  static const String credits = 'assets/icons/widget/credits.svg';
  static const String investments = 'assets/icons/widget/investments.svg';
  static const String aiAgent = 'assets/icons/widget/ai_agent.svg';

  // ── SCAN (QR scan tab) ────────────────────────────────────────
  static const String gallery = 'assets/icons/scan/gallery.svg';
  static const String flashlight = 'assets/icons/scan/flashlight.svg';
  static const String flashlightOn = 'assets/icons/scan/flashlight_on.svg';

  // ── ACTION (standalone controls) ─────────────────────────────
  static const String attention = 'assets/icons/action/attention.svg';
  static const String back = 'assets/icons/action/back.svg';
  static const String biometry = 'assets/icons/action/biometry.svg';
  static const String clear = 'assets/icons/action/clear.svg';
  static const String convert = 'assets/icons/action/convert.svg';
  static const String document = 'assets/icons/action/document.svg';
  static const String emptyList = 'assets/icons/action/empty_list.svg';
  static const String exit = 'assets/icons/action/exit.svg';
  static const String filter = 'assets/icons/action/filter.svg';
  static const String geolocation = 'assets/icons/action/geolocation.svg';
  static const String lock = 'assets/icons/action/lock.svg';
  static const String other = 'assets/icons/action/other.svg';
  static const String settings = 'assets/icons/action/settings.svg';
  static const String time = 'assets/icons/action/time.svg';
  static const String transfer = 'assets/icons/action/transfer.svg';
  static const String user = 'assets/icons/action/user.svg';
  static const String withdraw = 'assets/icons/action/withdraw.svg';
  static const String worldwide = 'assets/icons/action/worldwide.svg';

  // ── WIDGET (product / service icons; artwork still pending) ─
  static const String accessCode = 'assets/icons/widget/access_code.svg';
  static const String accounts = 'assets/icons/widget/accounts.svg';
  static const String atm = 'assets/icons/widget/atm.svg';
  static const String branch = 'assets/icons/widget/branch.svg';
  static const String card = 'assets/icons/widget/card.svg';
  static const String face = 'assets/icons/widget/face.svg';
  static const String fingerprint = 'assets/icons/widget/fingerprint.svg';
  static const String installment = 'assets/icons/widget/installment.svg';
  static const String language = 'assets/icons/widget/language.svg';
  static const String limits = 'assets/icons/widget/limits.svg';
  static const String phone = 'assets/icons/widget/phone.svg';
  static const String screenProtect = 'assets/icons/widget/screen_protect.svg';
  static const String security = 'assets/icons/widget/security.svg';
  static const String smartphone = 'assets/icons/widget/smartphone.svg';
  static const String subscriptions = 'assets/icons/widget/subscriptions.svg';
  static const String support = 'assets/icons/widget/support.svg';
  static const String transactions = 'assets/icons/widget/transactions.svg';

  // ── CHAT (chatbot screen) ────────────────────────────────────
  static const String chatBot = 'assets/icons/chat/chatbot.svg';
  static const String chatBubble = 'assets/icons/chat/chat_bubble.svg';
  static const String chatRestart = 'assets/icons/chat/restart_square.svg';
  static const String chatSend = 'assets/icons/chat/send.svg';

  // ── BRAND (payment marks) ────────────────────────────────────
  static const String visa = 'assets/icons/brand/visa.svg';
  static const String googlePay = 'assets/icons/brand/google_pay.svg';

  /// Tinted SVG helper. Pass no [color] to keep the artwork's own colours.
  static Widget svg(String asset, {double? size, Color? color, Key? key}) =>
      SvgPicture.asset(
        key: key,
        asset,
        width: size,
        height: size,
        colorFilter: color == null
            ? null
            : ColorFilter.mode(color, BlendMode.srcIn),
      );
}
