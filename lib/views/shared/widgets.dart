import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

import '../../utils/themes/theme_extension.dart';
import 'formatters.dart';

class FrostedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final bool floating;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final double? titleSpacing;
  final EdgeInsets? actionsPadding;

  const FrostedAppBar({
    super.key,
    this.title,
    this.floating = false,
    this.actions,
    this.leading,
    this.bottom,
    this.titleSpacing,
    this.actionsPadding,
  });

  static const double _floatingGap = 8;

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight +
        (bottom?.preferredSize.height ?? 0) +
        (floating ? _floatingGap * 2 : 8),
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final appBar = AppBar(
      titleSpacing: 0,
      actionsPadding: actionsPadding,
      title: title,
      leading: leading,
      actions: actions,
      bottom: bottom,
      systemOverlayStyle: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    );

    final pillRadius = BorderRadius.circular(floating ? 999 : 24);

    final pill = ClipRRect(
      borderRadius: floating ? pillRadius : BorderRadius.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: floating ? cs.surface : Colors.transparent,
          borderRadius: floating ? pillRadius : BorderRadius.zero,
        ),
        child: appBar,
      ),
    );

    return ClipRRect(
      borderRadius: floating
          ? BorderRadius.all(Radius.circular(24))
          : const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              cs.primary.withValues(alpha: 0.04),
              cs.surface.withValues(alpha: .35),
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.25),
            ),
          ),
          child: SafeArea(
            top: true,
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                floating ? 16 : 0,
                floating ? _floatingGap : 2,
                floating ? 16 : 0,
                floating ? _floatingGap : 6,
              ),
              child: pill,
            ),
          ),
        ),
      ),
    );
  }
}

Widget buildTextInput(
  TextEditingController controller,
  String hint, {
  String iconType = 'none',
  bool isPassword = false,
  bool activeIcon = false,
  bool enabled = true,
  List<TextInputFormatter>? inputFormatters,
  TextInputType keyboardType = TextInputType.text,
  required BuildContext context,
  FocusNode? currentFocus,
  FocusNode? nextFocus,
  VoidCallback? onIconPressed,
}) {
  activeIcon = isPassword ? isPassword : activeIcon;

  return StatefulBuilder(
    builder: (context, setState) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: TextField(
          controller: controller,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(
            labelText: hint,
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              fontWeight: FontWeight.normal,
            ),
            floatingLabelStyle: TextStyle(
              color: Theme.of(context).colorScheme.inverseSurface,
              fontWeight: FontWeight.bold,
            ),
            hintStyle: Theme.of(context).textTheme.bodyMedium,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                width: 1.5,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                width: 2.0,
                color: Theme.of(context).colorScheme.inverseSurface,
              ),
            ),
            // Use a suffixIcon based on the iconType
            suffixIcon: _buildSuffixIcon(
              iconType,
              activeIcon,
              context,
              onPressed: () {
                if (iconType == 'password') {
                  setState(() {
                    activeIcon = !activeIcon;
                  });
                } else if (onIconPressed != null) {
                  onIconPressed();
                  if (iconType == 'delete') {
                    setState(() {
                      activeIcon = false;
                    });
                  }
                }
              },
            ),
          ),
          autofillHints: _getAutofillHints(iconType),
          keyboardType: keyboardType,
          obscureText: isPassword && activeIcon,
          focusNode: currentFocus,
          enabled: enabled,
          inputFormatters: inputFormatters,
          textInputAction: nextFocus != null
              ? TextInputAction.next
              : TextInputAction.done,
          onEditingComplete: () {
            if (nextFocus != null) {
              FocusScope.of(context).requestFocus(nextFocus);
            } else {
              FocusScope.of(context).unfocus();
            }
          },
        ),
      );
    },
  );
}

Widget buildUserAvatar(
  ThemeData theme,
  String? userName, {
  double? radius = 24,
}) {
  return CircleAvatar(
    radius: radius,
    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
    child: Text(
      getInitials(userName ?? ''),
      style: radius == 16
          ? theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            )
          : radius == 24
          ? theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            )
          : radius == 48
          ? theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            )
          : theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
    ),
  );
}

List<String> _getAutofillHints(String iconType) {
  switch (iconType) {
    case 'email':
      return [AutofillHints.username, AutofillHints.email];
    case 'password':
      return [AutofillHints.password];
    case 'profile':
      return [AutofillHints.name];
    default:
      return [];
  }
}

Widget? _buildSuffixIcon(
  String iconType,
  bool activeIcon,
  BuildContext context, {
  required VoidCallback onPressed,
}) {
  switch (iconType) {
    case 'password':
      return IconButton(
        icon: Icon(
          activeIcon ? Icons.visibility_off : Icons.visibility,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        onPressed: onPressed,
      );
    case 'profile':
      return IconButton(
        icon: Icon(
          Icons.person,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        onPressed: onPressed,
      );
    case 'edit':
      return IconButton(
        icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.onSurface),
        onPressed: onPressed,
      );
    case 'email':
      return IconButton(
        icon: Icon(Icons.email, color: Theme.of(context).colorScheme.onSurface),
        onPressed: onPressed,
      );
    case 'delete':
      return activeIcon
          ? IconButton(
              icon: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.error,
              ),
              onPressed: onPressed,
            )
          : IconButton(
              icon: Icon(
                Icons.edit,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: onPressed,
            );
    case 'search':
      return IconButton(
        icon: Icon(
          Icons.search,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        onPressed: onPressed,
      );
    case 'clear':
      return IconButton(
        icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.onSurface),
        onPressed: onPressed,
      );
    case 'check':
      return IconButton(
        icon: Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
        onPressed: onPressed,
      );
    case 'dropdown':
      return IconButton(
        icon: Icon(
          Icons.arrow_drop_down,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        onPressed: onPressed,
      );
    case 'camera':
      return IconButton(
        icon: Icon(
          Icons.camera_alt,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        onPressed: onPressed,
      );
    case 'attach':
      return IconButton(
        icon: Icon(
          Icons.attach_file,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        onPressed: onPressed,
      );
    case 'mic':
      return IconButton(
        icon: Icon(Icons.mic, color: Theme.of(context).colorScheme.onSurface),
        onPressed: onPressed,
      );
    case 'send':
      return IconButton(
        icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
        onPressed: onPressed,
      );
    case 'calendar':
      return IconButton(
        icon: Icon(
          Icons.calendar_today,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        onPressed: onPressed,
      );
    case 'none':
    default:
      return null;
  }
}

Widget buildSignInText(
  String text,
  String actionText,
  BuildContext context,
  VoidCallback onSignInPressed,
) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(text, style: Theme.of(context).textTheme.bodyMedium),
      TextButton(
        onPressed: onSignInPressed,
        child: Text(
          actionText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    ],
  );
}

Widget buildBackground(BuildContext context) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Theme.of(context).extension<Extra>()!.backgroundGradientStart!,
          Theme.of(context).extension<Extra>()!.backgroundGradientEnd!,
        ],
      ),
    ),
  );
}

Widget fakeHero({required String tag, required Widget child}) {
  return Hero(
    tag: tag,
    child: Material(color: Colors.transparent, child: child),
    flightShuttleBuilder: (_, _, _, _, _) {
      return Material(color: Colors.transparent, child: child);
    },
  );
}

Widget buildUserCard(
  String fullName,
  ThemeData theme,
  Size size, {
  String? photoUrl,
  String? subtitle,
}) {
  final initials = getInitials(fullName);
  final initialsWidget = Text(
    initials,
    style: theme.textTheme.headlineMedium?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.bold,
    ),
  );
  final hasPhoto = photoUrl != null && photoUrl.trim().isNotEmpty;

  return Column(
    children: [
      ClipOval(
        child: SizedBox(
          width: 96,
          height: 96,
          child: hasPhoto
              ? Image.network(
                  photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    alignment: Alignment.center,
                    child: initialsWidget,
                  ),
                )
              : Container(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  alignment: Alignment.center,
                  child: initialsWidget,
                ),
        ),
      ),
      SizedBox(height: size.height * 0.02),
      Text(
        fullName,
        textAlign: TextAlign.center,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      if (subtitle != null && subtitle.isNotEmpty) ...[
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ],
  );
}

PreferredSizeWidget buildHeader(BuildContext context, String label) {
  return FrostedAppBar(
    floating: true,
    leading: IconButton(
      icon:
          // SvgPicture.asset(
          //   'assets/icons/ic_back.svg',
          //   width: 36,
          //   height: 36,
          //   colorFilter: ColorFilter.mode(
          //     Theme.of(context).colorScheme.primary,
          //     BlendMode.srcIn,
          //   ),
          Icon(
            Icons.arrow_back_ios_rounded,
            size: 24,
            color: Theme.of(context).colorScheme.primary,
          ),
      onPressed: () {
        FocusScope.of(context).unfocus();
        Navigator.of(context).pop();
      },
    ),
    title: Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 20),
    ),
  );
}
