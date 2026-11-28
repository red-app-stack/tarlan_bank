import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/core/router/app_navigation.dart';
import 'package:tarlan_bank/core/router/routes.dart' show Routes;
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/views/shared/custom_card.dart';
import 'package:tarlan_bank/views/shared/list_item.dart';
import 'package:tarlan_bank/views/shared/screen_padding.dart';
import 'package:tarlan_bank/views/shared/service_item.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final popular = [
      ServiceItemData('assets/images/phone.png', l.serviceMobile, 'phone'),
      ServiceItemData(
        'assets/images/internet.png',
        l.serviceInternet,
        'internet',
      ),
      ServiceItemData(
        'assets/images/transport.png',
        l.serviceTransport,
        'transport',
      ),
      ServiceItemData(
        'assets/images/utilities.png',
        l.serviceUtilities,
        'utilities',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        top: false,
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
                  CustomCard(
                    label: l.navPayments,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    endWidget: TextButton(
                      onPressed: () =>
                          navigateTo(context, Routes.paymentsHistory),
                      child: Text(
                        l.history,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ),
                  CustomCard(
                    label: l.popular,
                    labelStyle: theme.textTheme.titleLarge,
                    endWidget: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.shadow.withValues(
                              alpha: 0.05,
                            ),
                            blurRadius: 8,
                            offset: Offset.zero,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Text(
                          l.zhambylRegion,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.only(
                      left: 0,
                      right: 0,
                      top: 16,
                      bottom: 0,
                    ),
                    topRowPadding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: popular.length,
                        itemExtent: 100,
                        itemBuilder: (context, index) {
                          final service = popular[index];
                          return ListItem.horizontal(
                            imagePath: service.iconPath,
                            title: service.label,
                            iconSize: 120 * 0.6,
                            onTap: () {},
                          );
                        },
                      ),
                    ),
                  ),
                  CustomCard(
                    padding: EdgeInsets.zero,
                    topRowPadding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                    ),
                    label: l.favorites,
                    labelStyle: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 16,
                    ),
                    child: const SizedBox(height: 8),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
