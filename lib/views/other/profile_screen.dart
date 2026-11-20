import 'dart:async';
import 'package:tarlan_bank/controllers/accounts_controller.dart';
import 'package:tarlan_bank/models/transaction_model.dart';
import 'package:tarlan_bank/models/user_model.dart';
import 'package:tarlan_bank/services/user_repository.dart';
import 'package:tarlan_bank/views/shared/formatters.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import '../shared/custom_card.dart';
import '../shared/list_item.dart';
import '../shared/shared_classes.dart';
import '../shared/widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserRepository _userRepo = Get.find<UserRepository>();
  final AccountsController _accountsCtrl = Get.find<AccountsController>();

  UserModel? _currentUser;
  List<Transaction>? accountOperations;
  List<Transaction>? transferOperations;
  List<Transaction>? paymentOperations;
  List<MenuSection> sections = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    _currentUser = await _userRepo.retrieveLocalUser();
    // await _accountsCtrl.fetchTransactionHistory(); call on refresh

    // 2️⃣ If we have no locally stored user, use the first account as a placeholder
    if (_currentUser == null && _accountsCtrl.accounts.isNotEmpty) {
      final acc = _accountsCtrl.accounts.first;
      _currentUser = UserModel(
        id: acc.id,
        email: '',
        fullName: acc.fullName,
        phoneNumber: acc.phoneNumber,
        role: 'client',
        isVerified: true,
        createdAt: DateTime.now(),
      );
    }
    final txs = _accountsCtrl.paymentHistory;

    accountOperations = txs.where((t) {
      return [
        'deposit',
        'withdrawal',
        'currency_conversion',
        'internal_transfer'
      ].contains(t.type);
    }).toList();

    transferOperations = txs.where((t) {
      return ['phone_transfer', 'card_transfer', 'swift_transfer']
          .contains(t.type);
    }).toList();

    paymentOperations = txs.where((t) => t.type == 'payment_transfer').toList();

    sections = [
      MenuSection(
        title: 'Мои уведомления',
        items: [
          _buildTransactionItem(),
          _buildTransferItem(),
          _buildPaymentItem(),
          _buildSecurityItem(),
        ],
      ),
      MenuSection(
        title: 'Настройки',
        items: [
          MenuItem(
              icon: 'assets/icons/ic_notifications.svg', title: 'Уведомления'),
          MenuItem(
              icon: 'assets/icons/ic_language.svg', title: 'Язык приложения'),
          _buildPhoneNumberItem(),
          MenuItem(
              icon: 'assets/icons/ic_phone.svg',
              title: 'Переводы по номеру телефона'),
        ],
      ),
    ];

    setState(() {});
  }

  MenuItem _buildTransactionItem() {
    final tx =
        accountOperations?.isNotEmpty == true ? accountOperations!.first : null;
    return tx != null
        ? MenuItem(
            icon: 'assets/icons/ic_transactions.svg',
            title: 'Операции по счетам',
            description:
                '${getTypeText(tx.type)} ${formatCurrency(tx.amount, tx.currency, 'RU')}',
            routeArg: '/transferHistory',
          )
        : MenuItem(
            icon: 'assets/icons/ic_transactions.svg',
            title: 'Операции по счетам',
            description: 'Пока нет операций',
            routeArg: '/transferHistory',
          );
  }

  MenuItem _buildTransferItem() {
    final tx = transferOperations?.isNotEmpty == true
        ? transferOperations!.first
        : null;
    return tx != null
        ? MenuItem(
            icon: 'assets/icons/ic_transfers.svg',
            title: 'Переводы',
            description:
                '${getTypeText(tx.type)} ${formatCurrency(tx.amount, tx.currency, 'RU')}',
            routeArg: '/transferHistory',
            args: {'transaction': tx},
          )
        : MenuItem(
            icon: 'assets/icons/ic_transfers.svg',
            title: 'Переводы',
            description: 'Пока нет переводов',
            routeArg: '/transferHistory',
            args: {});
  }

  MenuItem _buildPaymentItem() {
    final tx =
        paymentOperations?.isNotEmpty == true ? paymentOperations!.first : null;
    return tx != null
        ? MenuItem(
            icon: 'assets/icons/ic_payments.svg',
            title: 'Платежи',
            description:
                '${getTypeText(tx.type)} ${formatCurrency(tx.amount, tx.currency, 'RU')}',
            routeArg: '/paymentHistory')
        : MenuItem(
            icon: 'assets/icons/ic_payments.svg',
            title: 'Платежи',
            description: 'Пока нет платежей',
            routeArg: '/paymentHistory',
            args: {'transaction': tx},
          );
  }

  MenuItem _buildSecurityItem() => MenuItem(
        icon: 'assets/icons/ic_security.svg',
        title: 'Безопасность',
        description:
            'Не переходите по непроверенным ссылкам и не вводите свои личные данные на неизвестных сайтах. Мошенники могут использовать поддельные ссылки и страницы для кражи информации. Всегда проверяйте источник сообщений и убедитесь, что адрес веб-сайта принадлежит вашему банку. Помните: сотрудники банка никогда не будут запрашивать ваш пароль или код из SMS.',
      );

  MenuItem _buildPhoneNumberItem() => MenuItem(
        icon: 'assets/icons/ic_smartphone.svg',
        title: '+7 ${formatPhone(_currentUser?.phoneNumber ?? '')}',
        description: 'Ваш доверенный номер',
      );

  bool showNotification(String icon) {
    return switch (icon) {
      'assets/icons/ic_transactions.svg' => false,
      'assets/icons/ic_transfers.svg' => false,
      'assets/icons/ic_payments.svg' => false,
      'assets/icons/ic_security.svg' => false,
      'assets/icons/ic_notifications.svg' => false,
      'assets/icons/ic_language.svg' => false,
      'assets/icons/ic_smartphone.svg' => false,
      'assets/icons/ic_phone.svg' => false,
      _ => false
    };
  }

  void handeItemClick(String icon) {
    switch (icon) {
      case 'assets/icons/ic_notifications.svg':
        break;
      case 'assets/icons/ic_language.svg':
        break;
      case 'assets/icons/ic_smartphone.svg':
        break;
      case 'assets/icons/ic_phone.svg':
        // print('CLICKED');
        // _authController.checkAuthStatus();
        break;
      case 'assets/icons/ic_transactions.svg':
        break;
      case 'assets/icons/ic_transfers.svg':
        break;
      case 'assets/icons/ic_payments.svg':
        break;
      case 'assets/icons/ic_security.svg':
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        appBar: buildHeader(context, 'Профиль'),
        body: SafeArea(
          bottom: false,
          top: false,
          child: RefreshIndicator(
            edgeOffset: MediaQuery.of(context).padding.top,
            onRefresh: () async {
              try {
                await _accountsCtrl.fetchTransactionHistory();
                await _loadProfileData();
                await Future.delayed(const Duration(milliseconds: 500));
              } on TimeoutException {
                print('Refresh operation timed out');
              } catch (e) {
                print('Error during refresh: $e');
              }
              return Future.value();
            },
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 56 + kToolbarHeight),
                child: Column(
                  spacing: 16,
                  children: [
                    SizedBox(
                        width: size.width / 2,
                        child: CustomCard(
                            child: buildUserCard(
                                _userRepo.currentUser?.fullName ?? '',
                                theme,
                                size))),
                    ...sections.map((section) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomCard(
                              padding: const EdgeInsets.symmetric(vertical: 0),
                              topRowPadding: const EdgeInsets.only(
                                  left: 16, right: 16, top: 16),
                              label: section.title,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...section.items.map((item) =>
                                      ListItem.vertical(
                                          svgPath: item.icon,
                                          title: item.title,
                                          subtitle: item.description,
                                          showNotification:
                                              showNotification(item.icon),
                                          onTap: item.routeArg is String
                                              ? () {
                                                  Get.offNamed(item.routeArg!);
                                                }
                                              : () {}))
                                ],
                              ),
                            ),
                          ],
                        )),
                    SizedBox(
                      height: 48,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
