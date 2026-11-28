import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/utils/themes/theme_extension.dart';
import 'package:tarlan_bank/views/shared/custom_card.dart';
import 'package:tarlan_bank/views/shared/list_item.dart';
import 'package:tarlan_bank/views/shared/service_item.dart';
import 'package:tarlan_bank/views/shared/widgets.dart';
import 'package:tarlan_bank/views/shared/app_icons.dart';
import 'package:tarlan_bank/views/shared/screen_padding.dart';

class ItemData {
  const ItemData({
    required this.path,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.priceChange,
    required this.chageUp,
  });

  final String path;
  final String title;
  final String subtitle;
  final String price;
  final String priceChange;
  final bool chageUp;
}

class InvestmentsScreen extends ConsumerWidget {
  const InvestmentsScreen({super.key});

  static const List<ItemData> _items = [
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final portfolio = [
      ServiceItemData(AppIcons.deposits, l.topUp, 'deposit'),
      ServiceItemData(AppIcons.transfer, l.transfer, 'transfer'),
      ServiceItemData(AppIcons.convert, l.conversion, 'convert'),
    ];

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          edgeOffset: MediaQuery.of(context).padding.top,
          onRefresh: () async =>
              Future<void>.delayed(const Duration(milliseconds: 500)),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: screenPadding,
              child: Column(
                spacing: 24,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildHeader(context, l.investments),
                  CustomCard(
                    label: l.portfolioTenge,
                    labelStyle: theme.textTheme.bodySmall,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '200 000,00 KZT',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Row(
                          children: [
                            for (final e in portfolio)
                              ServiceItem(
                                label: e.label,
                                svgPath: e.iconPath,
                                iconSize: 36,
                              ),
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
                          label: l.statistics,
                          startWidget: SvgPicture.asset(AppIcons.time),
                          labelStyle: theme.textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: CustomCard(
                          label: l.operations,
                          startWidget: SvgPicture.asset(AppIcons.document),
                          labelStyle: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  CustomCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 48,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainer,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(30),
                            ),
                          ),
                          child: TextField(
                            textAlignVertical: TextAlignVertical.center,
                            textInputAction: TextInputAction.search,
                            style: TextStyle(
                              color: theme.extension<Extra>()!.secondaryText,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: true,
                              fillColor: Colors.transparent,
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: SvgPicture.asset(
                                  AppIcons.search,
                                  width: 20,
                                  height: 20,
                                  colorFilter: ColorFilter.mode(
                                    theme.extension<Extra>()!.secondaryText!,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              hintText: l.searchHint,
                              hintStyle: TextStyle(
                                color: theme
                                    .extension<Extra>()!
                                    .secondaryText!
                                    .withValues(alpha: 0.7),
                              ),
                              contentPadding: const EdgeInsets.only(
                                left: 48,
                                right: 16,
                              ),
                            ),
                          ),
                        ),
                        ..._items.map(
                          (item) => _buildFavoriteItem(
                            imagePath: item.path,
                            title: item.title,
                            subtitle: item.subtitle,
                            theme: theme,
                            price: item.price,
                            priceChange: item.priceChange,
                            changeUp: item.chageUp,
                          ),
                        ),
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
          const SizedBox(height: 6),
          Text(
            priceChange,
            style: theme.textTheme.bodySmall?.copyWith(
              color: changeUp
                  ? theme.colorScheme.primary
                  : theme.colorScheme.error,
              fontWeight: FontWeight.w200,
            ),
          ),
        ],
      ),
    );
  }
}
