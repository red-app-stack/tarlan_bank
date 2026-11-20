import 'dart:async';
import 'dart:convert';
import 'package:tarlan_bank/views/shared/formatters.dart';
import 'package:tarlan_bank/views/shared/custom_card.dart';
import 'package:tarlan_bank/views/shared/list_item.dart';
import 'package:tarlan_bank/views/shared/shared_classes.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../models/transaction_model.dart';
import '../../services/secure_store.dart';
import '../shared/widgets.dart';

class TransfersController extends GetxController {
  final SecureStore secureStore = Get.find<SecureStore>();
  RxList<Transaction> favorites = <Transaction>[].obs;
  static const String favoritesKey = 'favorite_transfers';

  @override
  void onInit() {
    super.onInit();
    loadFavorites();
  }

  Future<List<Transaction>> getFavoriteTransfers() async {
    final favoritesJson = await secureStore.read(favoritesKey);
    if (favoritesJson != null) {
      final List<dynamic> decoded = jsonDecode(favoritesJson);
      return decoded.map((json) => Transaction.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> loadFavorites() async {
    favorites.value = await getFavoriteTransfers();
  }

  final List<MenuSection> sections = [
    MenuSection(
      items: [
        MenuItem(
            icon: 'assets/icons/ic_phone.svg',
            title: 'По номеру телефона',
            description: 'Клиентам и предпринимателям',
            routeArg: 'phone'),
        MenuItem(
            icon: 'assets/icons/ic_transfer.svg',
            title: 'Между своими счетами',
            description: 'Картами, счетами, депозитами',
            routeArg: 'self'),
        MenuItem(
            icon: 'assets/icons/ic_geolocation.svg',
            title: 'Внутри Казахстана',
            description: 'На карту, на номер счёта',
            routeArg: 'kz'),
        MenuItem(
            icon: 'assets/icons/ic_worldwide.svg',
            title: 'Международные переводы',
            description: 'В любую точку мира',
            routeArg: 'world'),
        MenuItem(
            icon: 'assets/icons/ic_convert.svg',
            title: 'Конвертация',
            description: 'Конвертация валют',
            routeArg: 'convert'),
        MenuItem(
            icon: 'assets/icons/ic_qr.svg',
            title: 'Bank QR',
            description: 'Создайте QR для получения перевода',
            routeArg: 'qr')
      ],
    )
  ];
}

class TransfersScreen extends StatelessWidget {
  final TransfersController controller = Get.put(TransfersController());

  TransfersScreen({super.key}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshData();
    });
  }
  Future<void> refreshData() async {
    try {
      await controller.loadFavorites();
    } catch (e) {
      print('Error refreshing data: $e');
    }
  }

  void _handleTransferItemTap(BuildContext context, String? type) {
    switch (type) {
      case 'phone':
        Get.toNamed('/phoneTransfer');
        break;
      case 'self':
        Get.toNamed('/selfTransfer');
        break;
      case 'kz':
        Get.toNamed('/cardTransfer');
        break;
      case 'world':
        // Get.find<AccountsController>().addTestMoney();
        break;
      case 'convert':
        Get.toNamed('/convertation');
        break;
      case 'qr':
        Get.toNamed('/qrTransfer');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        top: false,
        child: RefreshIndicator(
          edgeOffset: MediaQuery.of(context).padding.top,
          onRefresh: () async {
            try {
              await refreshData();

              await Future.delayed(const Duration(milliseconds: 500));
            } on TimeoutException {
              print('Refresh operation timed out');
            } catch (e) {
              print('Error during refresh: $e');
            } finally {}
            return Future.value();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24.0, vertical: 56 + kToolbarHeight),
              child: Column(
                spacing: 24,
                children: [
                  CustomCard(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    label: 'Переводы',
                    endWidget: TextButton(
                      onPressed: () {
                        Get.toNamed('/transferHistory');
                      },
                      child:
                          Text('История', style: theme.textTheme.titleMedium),
                    ),
                  ),
                  ...controller.sections.map(
                    (section) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomCard(
                          label: section.title,
                          labelStyle: theme.textTheme.titleLarge,
                          padding: EdgeInsets.zero,
                          topRowPadding: const EdgeInsets.only(
                              left: 16, right: 16, top: 16),
                          child: Column(
                            spacing: 12,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...section.items.map((item) => ListItem.vertical(
                                    svgPath: item.icon,
                                    iconSize: 36,
                                    title: item.title,
                                    subtitle: item.description,
                                    onTap: () => _handleTransferItemTap(
                                        context, item.routeArg),
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Obx(() => controller.favorites.isNotEmpty
                      ? CustomCard(
                          padding: EdgeInsets.zero,
                          topRowPadding: const EdgeInsets.only(
                              left: 16, right: 16, top: 16),
                          label: 'Сохраненные',
                          labelStyle: theme.textTheme.titleLarge,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...controller.favorites.map((transaction) =>
                                  _buildFavoriteItem(
                                    transaction: transaction,
                                    title:
                                        formatFullName(transaction.toUserName),
                                    subtitle:
                                        censorCardNumber(transaction.toAccount),
                                    theme: theme,
                                  )),
                            ],
                          ),
                        )
                      : Container()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteItem({
    required Transaction transaction,
    required String title,
    required String subtitle,
    required ThemeData theme,
    double iconSize = 36,
  }) {
    return ListItem(
      direction: ListItemDirection.vertical,
      title: title,
      subtitle: subtitle,
      iconSize: iconSize,
      borderRadius: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      customLeading: buildUserAvatar(theme, transaction.toUserName),
      trailing: IconButton(
        icon: SvgPicture.asset(
          'assets/icons/ic_other.svg',
          width: iconSize,
          height: iconSize,
          colorFilter: ColorFilter.mode(
            theme.colorScheme.primary,
            BlendMode.srcIn,
          ),
        ),
        onPressed: () {},
      ),
      onTap: () {
        Get.toNamed('/transferDetails', arguments: transaction);
      },
    );
  }
}
