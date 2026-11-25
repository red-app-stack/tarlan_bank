import 'package:flutter_svg/svg.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassContainer, LiquidOval, LiquidRoundedSuperellipse;
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/utils/themes/glass_settings.dart';

import '../shared/cached_user_avatar.dart';
import '../shared/formatters.dart';
import '../../utils/themes/theme_extension.dart' show Extra;

/// Split shell top bar: cached avatar, greeting, a glass search pill and a
/// circular glass notifications button. The bars no longer share one surface.
class ShellTopBar extends StatelessWidget implements PreferredSizeWidget {
  const ShellTopBar({
    super.key,
    required this.searchController,
    required this.displayName,
    required this.photoUrl,
    required this.onProfileTap,
    required this.onNotificationsTap,
  });

  final TextEditingController searchController;
  final String displayName;
  final String photoUrl;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationsTap;

  static const double _gap = 8;
  static const double _controlHeight = 40;

  @override
  Size get preferredSize => const Size.fromHeight(_controlHeight + _gap * 2);

  String _avatarInitials(String name) {
    final initials = getInitials(name);
    if (initials.isNotEmpty) return initials;
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }

  /// bodyMedium at 12/16 for both greeting lines.
  TextStyle _greetingStyle(
    ThemeData theme,
    Color color, {
    FontWeight? fontWeight,
  }) {
    return (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
      color: color,
      fontSize: 12,
      height: 16 / 12,
      fontWeight: fontWeight,
    );
  }

  Widget _searchField(ThemeData theme, AppLocalizations l) {
    final extra = theme.extension<Extra>();
    final color = extra?.secondaryText ?? theme.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            textAlignVertical: TextAlignVertical.center,
            textInputAction: TextInputAction.search,
            style: _greetingStyle(theme, color),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: true,
              fillColor: Colors.transparent,
              hintText: l.searchHint,
              hintStyle: _greetingStyle(theme, color.withValues(alpha: 0.7)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            ),
          ),
        ),
        // Zoom (search) icon sits on the right edge of the pill.
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: SvgPicture.asset(
            'assets/icons/ic_search.svg',
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
        ),
      ],
    );
  }

  Widget _notificationsButton(ThemeData theme, AppLocalizations l) {
    final iconColor = theme.colorScheme.primary;
    final badgeColor = notificationColor(theme);
    return GlassContainer(
      width: _controlHeight,
      height: _controlHeight,
      shape: const LiquidOval(),
      padding: EdgeInsets.zero,
      settings: themedGlassSettings(
        theme,
        accent: theme.colorScheme.secondaryContainer,
      ),
      useOwnLayer: true,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            tooltip: l.auNotificationsTitle,
            onPressed: onNotificationsTap,
            icon: SizedBox(
              width: 24,
              height: 24,
              child: SvgPicture.asset(
                'assets/icons/ic_notifications.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
            ),
          ),
          // The accent marks unread notifications, not the bell itself.
          Positioned(
            top: 10,
            right: 10,
            child: IgnorePointer(
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: badgeColor.withValues(alpha: 0.45),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final extra = theme.extension<Extra>();
    final greetingColor =
        extra?.secondaryText ?? theme.colorScheme.onSurfaceVariant;

    return SafeArea(
      top: true,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: _gap),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: _controlHeight - 5,
              height: _controlHeight - 5,
              child: Tooltip(
                message: l.auProfileTitle,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onProfileTap,
                    child: CachedUserAvatar(
                      imageUrl: photoUrl,
                      initials: _avatarInitials(displayName),
                      size: _controlHeight - 5,
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.12,
                      ),
                      foregroundColor: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.topBarGreeting,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _greetingStyle(theme, greetingColor),
                  ),
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _greetingStyle(
                      theme,
                      theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GlassContainer(
                quality: .premium,
                height: _controlHeight,
                shape: const LiquidRoundedSuperellipse(
                  borderRadius: _controlHeight,
                ),
                padding: EdgeInsets.zero,
                settings: themedGlassSettings(theme),
                useOwnLayer: true,
                child: _searchField(theme, l),
              ),
            ),
            const SizedBox(width: _gap),
            _notificationsButton(theme, l),
          ],
        ),
      ),
    );
  }
}
