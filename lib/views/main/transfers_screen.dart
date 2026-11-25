import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tarlan_bank/core/router/app_navigation.dart';
import 'package:tarlan_bank/core/router/routes.dart' show Routes;
import 'package:tarlan_bank/features/payments/providers/favorite_transfers_provider.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/views/shared/custom_card.dart';
import 'package:tarlan_bank/views/shared/formatters.dart';
import 'package:tarlan_bank/views/shared/list_item.dart';
import 'package:tarlan_bank/views/shared/shared_classes.dart';
import 'package:tarlan_bank/views/shared/widgets.dart';

class TransfersScreen extends ConsumerWidget {
  const TransfersScreen({super.key});

  void _handleTransferItemTap(BuildContext context, String? type) {
    switch (type) {
      case 'phone':
        navigateTo(context, Routes.transfersPhone);
      case 'self':
        navigateTo(context, Routes.transfersSelf);
      case 'kz':
        navigateTo(context, Routes.transfersCard);
      case 'world':
        // International transfers are not wired to a route yet.
        break;
      case 'convert':
        navigateTo(context, Routes.transfersConvert);
      case 'qr':
        navigateTo(context, Routes.transfersQr);
    }
  }

  List<MenuSection> _sections(AppLocalizations l) => [
    MenuSection(
      items: [
        MenuItem(
          icon: 'assets/icons/ic_phone.svg',
          title: l.transferByPhone,
          description: l.transferByPhoneDesc,
          routeArg: 'phone',
        ),
        MenuItem(
          icon: 'assets/icons/ic_transfer.svg',
          title: l.transferBetweenOwn,
          description: l.transferBetweenOwnDesc,
          routeArg: 'self',
        ),
        MenuItem(
          icon: 'assets/icons/ic_geolocation.svg',
          title: l.transferKz,
          description: l.transferKzDesc,
          routeArg: 'kz',
        ),
        MenuItem(
          icon: 'assets/icons/ic_worldwide.svg',
          title: l.transferInternational,
          description: l.transferInternationalDesc,
          routeArg: 'world',
        ),
        MenuItem(
          icon: 'assets/icons/ic_convert.svg',
          title: l.conversion,
          description: l.conversionDesc,
          routeArg: 'convert',
        ),
        MenuItem(
          icon: 'assets/icons/ic_qr.svg',
          title: l.bankQr,
          description: l.bankQrDesc,
          routeArg: 'qr',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final favoritesAsync = ref.watch(favoriteTransfersProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        top: false,
        child: RefreshIndicator(
          edgeOffset: MediaQuery.of(context).padding.top,
          onRefresh: () async {
            ref.invalidate(favoriteTransfersProvider);
            await Future<void>.delayed(const Duration(milliseconds: 300));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 56 + kToolbarHeight,
              ),
              child: Column(
                spacing: 24,
                children: [
                  CustomCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    label: l.navTransfers,
                    endWidget: TextButton(
                      onPressed: () =>
                          navigateTo(context, Routes.transfersHistory),
                      child: Text(
                        l.history,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ),
                  ..._sections(l).map(
                    (section) => CustomCard(
                      label: section.title,
                      labelStyle: theme.textTheme.titleLarge,
                      padding: EdgeInsets.zero,
                      topRowPadding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                      ),
                      child: Column(
                        spacing: 12,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...section.items.map(
                            (item) => ListItem.vertical(
                              svgPath: item.icon,
                              iconSize: 36,
                              title: item.title,
                              subtitle: item.description,
                              onTap: () => _handleTransferItemTap(
                                context,
                                item.routeArg,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  favoritesAsync.when(
                    data: (favorites) => favorites.isEmpty
                        ? const SizedBox.shrink()
                        : CustomCard(
                            padding: EdgeInsets.zero,
                            topRowPadding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top: 16,
                            ),
                            label: l.saved,
                            labelStyle: theme.textTheme.titleLarge,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...favorites.map(
                                  (favorite) => _buildFavoriteItem(
                                    context: context,
                                    favorite: favorite,
                                    theme: theme,
                                  ),
                                ),
                              ],
                            ),
                          ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
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
    required BuildContext context,
    required FavoriteTransfer favorite,
    required ThemeData theme,
    double iconSize = 36,
  }) {
    return ListItem(
      direction: ListItemDirection.vertical,
      title: formatFullName(favorite.name),
      subtitle: censorCardNumber(favorite.accountNumber),
      iconSize: iconSize,
      borderRadius: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      customLeading: buildUserAvatar(theme, favorite.name),
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
      onTap: () =>
          navigateTo(context, Routes.transfersDetails, arguments: favorite),
    );
  }
}
