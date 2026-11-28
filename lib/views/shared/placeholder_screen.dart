import 'package:flutter_svg/svg.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/views/shared/widgets.dart';
import 'package:tarlan_bank/views/shared/screen_padding.dart';

import 'custom_card.dart';

import 'package:tarlan_bank/views/shared/app_icons.dart';

/// Small consistent screen for menu items that are not implemented yet.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: buildHeader(context, title),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: screenPadding,
            child: CustomCard(
              label: title,
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    AppIcons.settings,
                    width: 56,
                    height: 56,
                    colorFilter: ColorFilter.mode(
                      theme.colorScheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
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
