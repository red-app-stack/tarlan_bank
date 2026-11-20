import 'dart:async';
import 'package:tarlan_bank/utils/themes/theme_extension.dart';
import 'package:tarlan_bank/views/shared/list_item.dart';
import 'package:tarlan_bank/views/shared/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../shared/custom_card.dart';
import '../shared/service_item.dart';

class ItemData {
  final String path;
  final String title;
  final String subtitle;
  final String price;
  final String priceChange;
  final bool chageUp;

  ItemData({
    required this.path,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.priceChange,
    required this.chageUp,
  });
}

class InvestmentsController extends GetxController {
  final List<ServiceItemData> portfolioIconPaths = [
    ServiceItemData('assets/icons/ic_deposit.svg', 'Пополнить', 'deposit'),
    ServiceItemData('assets/icons/ic_transfer.svg', 'Перевести', 'transfer'),
    ServiceItemData('assets/icons/ic_convert.svg', 'Конвертация', 'convert'),
  ];

  final List<ItemData> itemsData = [
    ItemData(
      path: 'assets/images/google.png',
      title: 'ALPHABET INC',
      subtitle: 'GOOGL • USM',
      price: '325,41 USD',
      priceChange: '+0,55 USD (+0,17%)',
      chageUp: true,
    ),
    ItemData(
      path: 'assets/images/pinterest.png',
      title: 'Pinterest Inc',
      subtitle: 'PINS • USM ',
      price: '25,14 USD',
      priceChange: '+0,02 USD (+0,08%)',
      chageUp: true,
    ),
    ItemData(
      path: 'assets/images/amazon.png',
      title: 'Amazon.com, Inc',
      subtitle: 'AMZN • USM ',
      price: '226,92 USD',
      priceChange: '-0,16 USD (-0,07%)',
      chageUp: false,
    ),
  ];
}

class InvestmentsScreen extends StatelessWidget {
  final InvestmentsController controller = Get.put(InvestmentsController());

  InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
              child: Column(
                spacing: 24,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildHeader(context, 'Инвестиции'),
                  CustomCard(
                    label: 'Портфель в тенге',
                    labelStyle: theme.textTheme.bodySmall,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '200 000,00 KZT',
                          style: theme.textTheme.headlineLarge?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.w700),
                        ),
                        Row(
                          children: [
                            ...controller.portfolioIconPaths.map(
                              (e) {
                                return ServiceItem(
                                  label: e.label,
                                  svgPath: e.iconPath,
                                  iconSize: 36,
                                );
                              },
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: CustomCard(
                          label: 'Статистика',
                          startWidget:
                              SvgPicture.asset('assets/icons/ic_time.svg'),
                          labelStyle: theme.textTheme.titleMedium,
                        ),
                      ),
                      SizedBox(
                        width: 24,
                      ),
                      Expanded(
                        child: CustomCard(
                          label: 'Операции',
                          startWidget:
                              SvgPicture.asset('assets/icons/ic_document.svg'),
                          labelStyle: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  CustomCard(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 48,
                          margin: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.all(Radius.circular(30)),
                          ),
                          child: TextField(
                            textAlignVertical: TextAlignVertical.center,
                            textInputAction: TextInputAction.search,
                            style: TextStyle(
                                color:
                                    theme.extension<Extra>()!.secondaryText!),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: true,
                              fillColor: Colors.transparent,
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: SvgPicture.asset(
                                  'assets/icons/ic_search.svg',
                                  width: 20,
                                  height: 20,
                                  colorFilter: ColorFilter.mode(
                                    theme.extension<Extra>()!.secondaryText!,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              prefixIconConstraints: BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              hintText: 'Поиск...',
                              hintStyle: TextStyle(
                                  color: theme
                                      .extension<Extra>()!
                                      .secondaryText!
                                      .withValues(alpha: 0.7)),
                              contentPadding:
                                  EdgeInsets.only(left: 48, right: 16),
                            ),
                          ),
                        ),
                        ...controller.itemsData
                            .map((item) => _buildFavoriteItem(
                                  imagePath: item.path,
                                  title: item.title,
                                  subtitle: item.subtitle,
                                  theme: theme,
                                  price: item.price,
                                  priceChange: item.priceChange,
                                  changeUp: item.chageUp,
                                ))
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
    required String imagePath,
    required String title,
    required String subtitle,
    required String price,
    required String priceChange,
    required bool changeUp,
    required ThemeData theme,
    double iconSize = 36,
  }) {
    return ListItem(
        direction: ListItemDirection.vertical,
        imagePath: imagePath,
        title: title,
        subtitle: subtitle,
        iconSize: iconSize,
        borderRadius: 48,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(price, style: theme.textTheme.titleLarge),
            SizedBox(
              height: 6,
            ),
            Text(
              priceChange,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: changeUp
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                  fontWeight: FontWeight.w200),
            ),
          ],
        ));
  }
}
