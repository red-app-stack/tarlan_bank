import 'package:tarlan_bank/controllers/auth_controller.dart';
import 'package:tarlan_bank/services/auth_state_service.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../shared/custom_card.dart';
import '../shared/list_item.dart';
import '../shared/shared_classes.dart';

class MenuScreen extends StatelessWidget {
  final AuthController _authController = Get.find<AuthController>();
  final AuthStateService _authStateService = Get.find<AuthStateService>();

  MenuScreen({super.key});

  final List<MenuSection> sections = [
    MenuSection(items: [
      MenuItem(
        icon: 'assets/icons/ic_settings.svg',
        title: 'Настройки безопасности',
        routeArg: 'securitySettings',
      )
    ]),
    MenuSection(
      title: 'Продукты',
      items: [
        MenuItem(
            icon: 'assets/icons/ic_card.svg', title: 'Карты', routeArg: 'card'),
        MenuItem(
            icon: 'assets/icons/ic_deposit.svg',
            title: 'Депозиты',
            routeArg: 'deposit'),
        MenuItem(
            icon: 'assets/icons/ic_credit.svg',
            title: 'Кредиты',
            routeArg: 'credit'),
        MenuItem(
            icon: 'assets/icons/ic_installment.svg',
            title: 'Рассрочка',
            routeArg: 'transfer'),
        MenuItem(
            icon: 'assets/icons/ic_invest.svg',
            title: 'Инвестиции',
            routeArg: 'investments'),
      ],
    ),
    MenuSection(
      title: 'Банк',
      items: [
        MenuItem(icon: 'assets/icons/ic_atm.svg', title: 'Банкоматы'),
        MenuItem(icon: 'assets/icons/ic_branch.svg', title: 'Отделения'),
        MenuItem(icon: 'assets/icons/ic_phone.svg', title: 'Позвонить в Bank'),
        MenuItem(
            icon: 'assets/icons/ic_support.svg',
            title: 'Мои обращения в поддержку'),
      ],
    ),
  ];
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        top: false,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
              horizontal: 24.0, vertical: 56 + kToolbarHeight),
          child: Column(
            spacing: 24,
            children: [
              CustomCard(
                label: 'Меню',
                padding: EdgeInsetsGeometry.all(18),
              ),
              ...sections.map((section) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomCard(
                        label: section.title,
                        labelStyle: theme.textTheme.titleLarge,
                        padding: EdgeInsets.zero,
                        topRowPadding:
                            const EdgeInsets.only(left: 16, right: 16, top: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...section.items.map((item) => ListItem.vertical(
                                  svgPath: item.icon,
                                  iconSize: 36,
                                  title: item.title,
                                  subtitle: item.description,
                                  onTap: () => handleItemClick(item.routeArg),
                                )),
                          ],
                        ),
                      ),
                    ],
                  )),
              _authStateService.isLoggedIn
                  ? Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _authController.logout(),
                        borderRadius: BorderRadius.circular(30),
                        splashFactory: InkRipple.splashFactory,
                        splashColor:
                            theme.colorScheme.primary.withValues(alpha: 0.08),
                        highlightColor:
                            theme.colorScheme.primary.withValues(alpha: 0.04),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/ic_exit.svg',
                                width: 36,
                                height: 36,
                                colorFilter: ColorFilter.mode(
                                  theme.colorScheme.error,
                                  BlendMode.srcIn,
                                ),
                              ),
                              Text('Выход',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.error)),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SizedBox(),
              SizedBox(height: size.height * 0.02),
            ],
          ),
        ),
      ),
    );
  }

  bool shouldShowNotification(String icon) {
    return false;
  }

  void handleItemClick(String? routeArg) {
    switch (routeArg) {
      case 'securitySettings':
        Get.toNamed('/securitySettings');
      case 'investments':
        Get.toNamed('/investments');
      case '':
        Get.find<AuthStateService>().setTarget('/accounts');
      case null:
        Get.find<AuthStateService>().setTarget('/accounts');
      default:
        Get.toNamed('/createAccount', arguments: routeArg);
    }
  }
}
