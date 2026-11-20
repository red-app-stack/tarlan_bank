import 'dart:async';
import 'package:tarlan_bank/views/shared/app_snack_bar.dart';
import 'package:tarlan_bank/views/shared/list_item.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../shared/custom_card.dart';
import '../shared/service_item.dart';

class FavoriteItemData {
  final String svgPath;
  final String title;
  final String subtitle;

  FavoriteItemData({
    required this.svgPath,
    required this.title,
    required this.subtitle,
  });
}

class PaymentsController extends GetxController {
  final List<ServiceItemData> popularServices = [
    ServiceItemData('assets/images/phone.png', 'Связь', 'phone'),
    ServiceItemData('assets/images/internet.png', 'Интернет', 'internet'),
    ServiceItemData('assets/images/transport.png', 'Транспорт', 'transport'),
    ServiceItemData('assets/images/utilities.png', 'Ком. услуги', 'utilities'),
  ];

  final List<String> favoriteInonPaths = [
    'assets/icons/ic_smartphone.svg',
    'assets/icons/ic_internet.svg',
    'assets/icons/ic_transport.svg',
    'assets/icons/ic_utilities.svg',
  ];
}

final List<FavoriteItemData> favoriteItemsData = [
  // FavoriteItemData(
  //   svgPath: 'assets/icons/ic_smartphone.svg',
  //   title: 'Мобильная связь',
  //   subtitle: '+7 707 276 6705',
  // ),
  // FavoriteItemData(
  //   svgPath: 'assets/icons/ic_internet.svg',
  //   title: 'Домашний интернет',
  //   subtitle: 'ID: 1234567890',
  // ),
  // FavoriteItemData(
  //   svgPath: 'assets/icons/ic_transport.svg',
  //   title: 'Общественный транспорт',
  //   subtitle: 'TulparCard 5465345466',
  // ),
  // FavoriteItemData(
  //   svgPath: 'assets/icons/ic_utilities.svg',
  //   title: 'Коммунальные услуги',
  //   subtitle: '+7 707 276 6705',
  // ),
];

class PaymentsScreen extends StatelessWidget {
  final PaymentsController controller = Get.put(PaymentsController());

  PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        top: false,
        child: RefreshIndicator(
          edgeOffset: MediaQuery.of(context).padding.top,
          onRefresh: () async {
            try {
              await Future.delayed(const Duration(milliseconds: 500));
            } on TimeoutException {
              print('Refresh operation timed out');
            } catch (e) {
              print('Error during refresh: $e');
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24.0, vertical: 56 + kToolbarHeight),
              child: Column(
                spacing: 24,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomCard(
                    label: 'Платежи',
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    endWidget: TextButton(
                      onPressed: () {
                        Get.toNamed('/paymentHistory');
                      },
                      child:
                          Text('История', style: theme.textTheme.titleMedium),
                    ),
                  ),
                  CustomCard(
                    label: 'Популярное',
                    labelStyle: theme.textTheme.titleLarge,
                    endWidget: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.shadow
                                .withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: Offset(0, 0),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Text('Жамбылская обл.',
                            style: theme.textTheme.labelMedium
                                ?.copyWith(color: theme.colorScheme.secondary)),
                      ),
                    ),
                    padding: const EdgeInsets.only(
                        left: 0, right: 0, top: 16, bottom: 0),
                    topRowPadding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.popularServices.length,
                        itemExtent: 100,
                        itemBuilder: (context, index) {
                          final service = controller.popularServices[index];
                          return ListItem.horizontal(
                            imagePath: service.iconPath,
                            title: service.label,
                            iconSize: 120 * 0.6,
                            onTap: () {
                              showAppSnackBar(context, message: 'Message');
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  CustomCard(
                    padding: EdgeInsets.zero,
                    topRowPadding:
                        const EdgeInsets.only(left: 16, right: 16, top: 16),
                    label: 'Избранное',
                    labelStyle:
                        theme.textTheme.titleLarge?.copyWith(fontSize: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...List.generate(favoriteItemsData.length, (index) {
                          final item = favoriteItemsData[index];
                          return _buildFavoriteItem(
                            svgPath: item.svgPath,
                            title: item.title,
                            subtitle: item.subtitle,
                            theme: theme,
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteItem({
    required String svgPath,
    required String title,
    required String subtitle,
    required ThemeData theme,
    double iconSize = 36,
  }) {
    return ListItem(
      direction: ListItemDirection.vertical,
      svgPath: svgPath,
      title: title,
      subtitle: subtitle,
      iconSize: iconSize,
      borderRadius: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
      onTap: () {},
    );
  }
}
