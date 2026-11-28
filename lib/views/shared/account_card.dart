import 'package:flutter_svg/svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tarlan_bank/views/shared/app_icons.dart';

/// Aspect ratio (width / height) for a single account: a full-width banner.
const double singleAccountAspectRatio = 347 / 180;

/// Two accounts share the strip: the banner shrinks by one step.
const double twoAccountAspectRatio = 250 / 180;

/// Three or more accounts keep the compact tile so the strip scrolls.
const double compactAccountAspectRatio = 150 / 180;

/// Tile width follows the number of accounts in the strip.
double accountCardAspectRatio(int accountCount) => switch (accountCount) {
  1 => singleAccountAspectRatio,
  2 => twoAccountAspectRatio,
  _ => compactAccountAspectRatio,
};

/// Reusable account/card tile: image background, VISA mark and bottom-aligned
/// details. No shadow or extra effects; reuse it with a different aspect ratio
/// (e.g. 350/180 for a banner) elsewhere.
class AccountCard extends StatelessWidget {
  const AccountCard({
    super.key,
    required this.imagePath,
    required this.cardType,
    required this.accountNumber,
    required this.expiry,
    this.balance,
    this.showBalance = true,
    this.aspectRatio = compactAccountAspectRatio,
    this.height = 180,
    this.visaLogoPath = AppIcons.visa,
    this.onTap,
  });

  final String imagePath;
  final String cardType;
  final String accountNumber;
  final String expiry;
  final String? balance;
  final bool showBalance;
  final double aspectRatio;
  final double height;
  final String visaLogoPath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onContainer = theme.colorScheme.onPrimaryContainer;
    final bodyMedium = (theme.textTheme.bodyMedium ?? const TextStyle())
        .copyWith(fontSize: 12, height: 16 / 12, color: onContainer);
    final bodyLarge = (theme.textTheme.bodyLarge ?? const TextStyle()).copyWith(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.bold,
      color: onContainer,
    );
    final bodySmall = (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
      fontSize: 10,
      height: 12 / 10,
      color: onContainer,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashFactory: InkRipple.splashFactory,
        child: SizedBox(
          height: height,
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(imagePath, fit: BoxFit.cover),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SvgPicture.asset(
                          visaLogoPath,
                          height: 8,
                          colorFilter: ColorFilter.mode(
                            onContainer,
                            BlendMode.srcIn,
                          ),
                        ),
                        const Spacer(),
                        Text(cardType, style: bodyMedium),
                        if (showBalance && balance != null) ...[
                          const SizedBox(height: 2),
                          Text(balance!, style: bodyLarge),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          spacing: 8,
                          children: [
                            Expanded(
                              child: Text(
                                accountNumber,
                                style: bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(expiry, style: bodySmall),
                          ],
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
}
