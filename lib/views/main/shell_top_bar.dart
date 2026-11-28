import 'package:flutter_svg/svg.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart'
    show LiquidGlassBatch, LiquidGlassLens, LiquidGlassShape;
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/utils/themes/glass_settings.dart';
import 'package:tarlan_bank/views/shared/app_icons.dart';

import '../shared/cached_user_avatar.dart';
import '../shared/formatters.dart';
import '../../utils/themes/theme_extension.dart' show Extra;

const double _gap = 8;
const double _controlHeight = 40;

/// Split shell top bar: cached avatar, greeting, a glass search pill and a
/// circular glass notifications button. The bars no longer share one surface.
class ShellTopBar extends StatefulWidget implements PreferredSizeWidget {
  const ShellTopBar({
    super.key,
    required this.searchController,
    required this.displayName,
    required this.photoUrl,
    required this.onProfileTap,
    required this.onNotificationsTap,
    this.isLoggedIn = true,
  });

  final TextEditingController searchController;
  final String displayName;
  final String photoUrl;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationsTap;

  /// Signed-out users get the empty-avatar artwork instead of initials.
  final bool isLoggedIn;

  @override
  Size get preferredSize => const Size.fromHeight(_controlHeight + _gap * 2);

  @override
  State<ShellTopBar> createState() => _ShellTopBarState();
}

class _ShellTopBarState extends State<ShellTopBar> {
  final _searchFocus = FocusNode();
  bool _searchActive = false;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(_updateSearchState);
    widget.searchController.addListener(_updateSearchState);
  }

  @override
  void dispose() {
    _searchFocus.removeListener(_updateSearchState);
    widget.searchController.removeListener(_updateSearchState);
    _searchFocus.dispose();
    super.dispose();
  }

  /// The search icon is "active" while the field is focused or has a query.
  void _updateSearchState() {
    final active =
        _searchFocus.hasFocus || widget.searchController.text.isNotEmpty;
    if (active == _searchActive) return;
    setState(() => _searchActive = active);
  }

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
            controller: widget.searchController,
            focusNode: _searchFocus,
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
            _searchActive ? AppIcons.searchActive : AppIcons.search,
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
    return SizedBox(
      width: _controlHeight,
      height: _controlHeight,
      child: LiquidGlassLens(
        style: themedGlassStyle(
          theme,
          // Half the 40pt control: a full circle.
          shape: const LiquidGlassShape.roundedRectangle(
            cornerRadius: _controlHeight / 2,
          ),
          accent: theme.colorScheme.secondaryContainer,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              tooltip: l.auNotificationsTitle,
              onPressed: widget.onNotificationsTap,
              icon: SizedBox(
                width: 24,
                height: 24,
                child: SvgPicture.asset(
                  AppIcons.notifications,
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
    final avatarSize = _controlHeight - 5;

    return SafeArea(
      top: true,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: _gap),
        // Search pill and bell sit side by side, so they share one backdrop
        // read; the page body has its own batch.
        child: LiquidGlassBatch(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: avatarSize,
                height: avatarSize,
                child: Tooltip(
                  message: l.auProfileTitle,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: widget.onProfileTap,
                      child: widget.isLoggedIn
                          ? CachedUserAvatar(
                              imageUrl: widget.photoUrl,
                              initials: _avatarInitials(widget.displayName),
                              size: avatarSize,
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.12),
                              foregroundColor: theme.colorScheme.primary,
                            )
                          : AppIcons.svg(
                              AppIcons.avatarEmpty,
                              size: avatarSize,
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
                      widget.displayName,
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
                child: SizedBox(
                  height: _controlHeight,
                  child: LiquidGlassLens(
                    style: themedGlassStyle(
                      theme,
                      shape: const LiquidGlassShape.continuousRoundedRectangle(
                        cornerRadius: _controlHeight,
                      ),
                    ),
                    child: _searchField(theme, l),
                  ),
                ),
              ),
              const SizedBox(width: _gap),
              _notificationsButton(theme, l),
            ],
          ),
        ),
      ),
    );
  }
}
