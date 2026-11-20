import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'app_colors.dart';
import 'app_colors_light.dart';
import 'app_colors_dark.dart';
import 'theme_extension.dart';

class AppTheme {
  static ThemeData lightTheme =
      _buildAppTheme(isDark: false, colors: AppColorsLight());
  static ThemeData darkTheme =
      _buildAppTheme(isDark: true, colors: AppColorsDark());

  static const String _fontFamily = 'OpenSans';

  static final OutlinedBorder _pill =
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(30));
  static final ShapeBorder _rounded12 =
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  static const EdgeInsets _btnPadding =
      EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0);
  static const Size _btnMinFull = Size(double.infinity, 36);
  static const Size _iconButtonMin = Size(36, 36);

  static TextStyle _h1(Color color) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle _h2(Color color,
          {double size = 16, FontWeight weight = FontWeight.w600}) =>
      TextStyle(
        fontFamily: _fontFamily,
        fontSize: size,
        fontWeight: weight,
        height: 1.2,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle _body(Color color,
          {double size = 12, FontWeight weight = FontWeight.w400}) =>
      TextStyle(
        fontFamily: _fontFamily,
        fontSize: size,
        fontWeight: weight,
        height: 1.4,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle _label(Color color,
          {double size = 10, FontWeight weight = FontWeight.w300}) =>
      TextStyle(
        fontFamily: _fontFamily,
        fontSize: size,
        fontWeight: weight,
        height: 1.2,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle _buttonPrimaryText(Color color) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle _buttonSecondaryText(Color color) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static WidgetStateProperty<T> _all<T>(T value) =>
      WidgetStateProperty.all<T>(value);

  static WidgetStateProperty<T?> _resolve<T>(T? Function(Set<WidgetState>) f) =>
      WidgetStateProperty.resolveWith<T?>(f);

  static ButtonStyle _elevatedPrimaryStyle(AppColors colors) {
    final primary = colors.primary;
    final onPrimary = colors.onPrimary;
    final outline = colors.outline;
    final outlineVariant = colors.outlineVariant;

    return ButtonStyle(
      shadowColor:
          WidgetStateProperty.all(colors.shadow.withValues(alpha: 0.4)),
      padding: _all(_btnPadding),
      shape: _all(_pill),
      minimumSize: _all(_btnMinFull),
      textStyle: _all(_buttonPrimaryText(onPrimary)),
      backgroundColor: _resolve<Color>((states) {
        if (states.contains(WidgetState.disabled)) return outline;
        if (states.contains(WidgetState.pressed)) {
          return primary.withValues(alpha: 0.85);
        }
        return primary;
      }),
      foregroundColor: _resolve<Color>((states) {
        if (states.contains(WidgetState.disabled)) return outlineVariant;
        return onPrimary;
      }),
      overlayColor: _resolve<Color?>((states) {
        if (states.contains(WidgetState.pressed)) {
          return onPrimary.withValues(alpha: 0.18);
        }
        if (states.contains(WidgetState.hovered)) {
          return onPrimary.withValues(alpha: 0.08);
        }
        return null;
      }),
      elevation: _resolve<double>((states) {
        if (states.contains(WidgetState.pressed)) return 0.0;
        if (states.contains(WidgetState.hovered)) return 8.0;
        return 4.0;
      }),
    );
  }

  static ButtonStyle _outlinedStyle(AppColors colors) => ButtonStyle(
        padding: _all(_btnPadding),
        shape: _all(_pill),
        minimumSize: _all(_btnMinFull),
        side: _all(BorderSide(color: colors.primary, width: 1.5)),
        foregroundColor: _all(colors.primary),
        textStyle: _all(_buttonSecondaryText(colors.primary)),
        overlayColor: _resolve<Color?>((states) {
          if (states.contains(WidgetState.pressed)) {
            return colors.primary.withValues(alpha: 0.06);
          }
          if (states.contains(WidgetState.hovered)) {
            return colors.primary.withValues(alpha: 0.04);
          }
          return null;
        }),
      );

  static ButtonStyle _textButtonStyle(AppColors colors) => ButtonStyle(
        foregroundColor: _all(colors.primary),
        textStyle: _all(_buttonSecondaryText(colors.primary)),
        padding:
            _all(const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0)),
        overlayColor: _resolve<Color?>((states) {
          if (states.contains(WidgetState.pressed)) {
            return colors.primary.withValues(alpha: 0.06);
          }
          return null;
        }),
      );

  static ButtonStyle _filledButtonStyle(AppColors colors) => ButtonStyle(
        backgroundColor: _resolve<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.primary.withValues(alpha: 0.18);
          }
          if (states.contains(WidgetState.pressed)) {
            return colors.primary.withValues(alpha: 0.9);
          }
          return colors.primary;
        }),
        foregroundColor: _all(colors.onPrimary),
        minimumSize: _all(const Size(120, 40)),
        padding: _all(const EdgeInsets.symmetric(horizontal: 16)),
        shape: _all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        textStyle: _all(_buttonSecondaryText(colors.onPrimary)),
      );

  static InputDecorationTheme _inputDecoration(AppColors colors) =>
      InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLowest,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: TextStyle(
            color: colors.onSurfaceVariant,
            fontFamily: _fontFamily,
            fontSize: 14),
      );

  static ChipThemeData _chipTheme(AppColors colors) => ChipThemeData(
        backgroundColor: colors.surfaceContainerLow,
        labelStyle: TextStyle(
            fontSize: 14, fontFamily: _fontFamily, color: colors.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        secondaryLabelStyle: TextStyle(
            fontSize: 14, fontFamily: _fontFamily, color: colors.onSurface),
      );

  static CardThemeData _cardTheme(AppColors colors) => CardThemeData(
        color: colors.surfaceContainer,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      );

  static SnackBarThemeData _snackBarTheme(AppColors colors) =>
      SnackBarThemeData(
        backgroundColor: colors.surfaceContainer,
        contentTextStyle:
            TextStyle(color: colors.onSurface, fontFamily: _fontFamily),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );

  static DialogThemeData _dialogTheme(AppColors colors) => DialogThemeData(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: TextStyle(
            fontFamily: _fontFamily,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colors.onSurface),
        contentTextStyle: TextStyle(
            fontFamily: _fontFamily, fontSize: 15, color: colors.onSurface),
      );

  static TextTheme _buildTextTheme(AppColors colors) => TextTheme(
        headlineLarge: _h1(colors.primaryText),
        headlineMedium: TextStyle(
            fontFamily: _fontFamily,
            fontSize: 24,
            fontWeight: FontWeight.w400,
            height: 1.2,
            color: colors.primaryText),
        headlineSmall: TextStyle(
            fontFamily: _fontFamily,
            fontSize: 24,
            fontWeight: FontWeight.w400,
            height: 1.2,
            color: colors.secondaryText),
        titleLarge: _h2(colors.primaryText),
        titleMedium: _h2(colors.secondary),
        titleSmall:
            _h2(colors.secondaryText, size: 16, weight: FontWeight.w400),
        bodyLarge: _body(colors.secondary, size: 16),
        bodyMedium: _body(colors.secondary, size: 12),
        bodySmall: _body(colors.secondaryText, size: 12),
        labelLarge:
            _label(colors.primaryText, size: 10, weight: FontWeight.w600),
        labelMedium:
            _label(colors.secondaryText, size: 10, weight: FontWeight.w400),
        labelSmall:
            _label(colors.tertiaryText, size: 10, weight: FontWeight.w400),
      );

  static NavigationBarThemeData _navigationBar(AppColors colors) =>
      NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.all(TextStyle(
            fontFamily: _fontFamily, fontSize: 12, color: colors.onSurface)),
      );

  static BottomNavigationBarThemeData _bottomNav(AppColors colors) =>
      BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.onSurfaceVariant,
      );

  static TabBarThemeData _tabBar(AppColors colors) => TabBarThemeData(
        labelStyle: TextStyle(
            fontFamily: _fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.onSurface),
        unselectedLabelStyle: TextStyle(
            fontFamily: _fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: colors.onSurfaceVariant),
      );

  static SliderThemeData _slider(AppColors colors) => SliderThemeData(
        activeTrackColor: colors.primary,
        inactiveTrackColor: colors.onSurfaceVariant,
        thumbColor: colors.primary,
        overlayColor: colors.primary.withValues(alpha: 0.12),
      );

  static CheckboxThemeData _checkbox(AppColors colors) => CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.outlineVariant;
          }
          return colors.primary;
        }),
        checkColor: WidgetStateProperty.all(colors.onPrimary),
        overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return Colors.transparent;
          }
          return colors.primary.withOpacity(0.1);
        }),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.standard,
      );

  static SwitchThemeData _switch(AppColors colors) => SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.outlineVariant;
          }
          return colors.primary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.surfaceContainerLow;
          }
          return colors.primary.withValues(alpha: 0.36);
        }),
      );

  static PopupMenuThemeData _popupMenu(AppColors colors) => PopupMenuThemeData(
        color: colors.surface,
        textStyle: TextStyle(fontFamily: _fontFamily, color: colors.onSurface),
      );

  static AppBarTheme _appBar(AppColors colors) => AppBarTheme(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        elevation: 0,
      );

  static ThemeData _buildAppTheme(
      {required bool isDark, required AppColors colors}) {
    final scheme = ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: colors.primary,
        onPrimary: colors.onPrimary,
        primaryContainer: colors.primaryContainer,
        onPrimaryContainer: colors.onPrimaryContainer,
        secondary: colors.secondary,
        onSecondary: colors.onSecondary,
        secondaryContainer: colors.secondaryContainer,
        onSecondaryContainer: colors.onSecondaryContainer,
        tertiary: colors.tertiary,
        onTertiary: colors.onTertiary,
        tertiaryContainer: colors.tertiaryContainer,
        onTertiaryContainer: colors.onTertiaryContainer,
        error: colors.error,
        onError: colors.onError,
        errorContainer: colors.errorContainer,
        onErrorContainer: colors.onErrorContainer,
        surface: colors.surface,
        surfaceDim: colors.surfaceDim,
        surfaceBright: colors.surfaceBright,
        onSurface: colors.onSurface,
        onSurfaceVariant: colors.onSurfaceVariant,
        outline: colors.outline,
        outlineVariant: colors.outlineVariant,
        surfaceContainerLowest: colors.surfaceContainerLowest,
        surfaceContainerLow: colors.surfaceContainerLow,
        surfaceContainer: colors.surfaceContainer,
        surfaceContainerHigh: colors.surfaceContainerHigh,
        surfaceContainerHighest: colors.surfaceContainerHighest,
        inversePrimary: colors.inversePrimary,
        inverseSurface: colors.inverseSurface,
        onInverseSurface: colors.onInverseSurface,
        shadow: colors.shadow,
        background: colors.background);

    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      colorScheme: scheme,
      extensions: [
        Extra(
          primaryText: colors.primaryText,
          secondaryText: colors.secondaryText,
          tertiaryText: colors.tertiaryText,
          backgroundGradientStart: colors.primaryVariant,
          backgroundGradientEnd: colors.onSecondary,
          primaryVariant: colors.primaryVariant,
          // background: colors.background,
          notifications: colors.notifications,
          primaryCardBg: colors.primaryCardBg,
          primaryCardFg: colors.primaryCardFg,
          secondaryCardBg: colors.secondaryCardBg,
          secondaryCardFg: colors.secondaryCardFg,
          tertiaryCardBg: colors.tertiaryCardBg,
          tertiaryCardFg: colors.tertiaryCardFg,
          grayCardBg: colors.grayCardBg,
          grayCardFg: colors.grayCardFg,
          yellowCardBg: colors.yellowCardBg,
          yellowCardFg: colors.yellowCardFg,
          purpleCardBg: colors.purpleCardBg,
          purpleCardFg: colors.purpleCardFg,
          goldCardBg: colors.goldCardBg,
          goldCardFg: colors.goldCardFg,
          redCardBg: colors.redCardBg,
          redCardFg: colors.redCardFg,
        ),
      ],
      textTheme: _buildTextTheme(colors),
      appBarTheme: _appBar(colors),
      elevatedButtonTheme:
          ElevatedButtonThemeData(style: _elevatedPrimaryStyle(colors)),
      outlinedButtonTheme:
          OutlinedButtonThemeData(style: _outlinedStyle(colors)),
      textButtonTheme: TextButtonThemeData(style: _textButtonStyle(colors)),
      filledButtonTheme:
          FilledButtonThemeData(style: _filledButtonStyle(colors)),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: _all(_iconButtonMin),
          shape: _all(const CircleBorder()),
          backgroundColor: _all(Colors.transparent),
          foregroundColor: _all(colors.primary),
          overlayColor: _resolve<Color?>((states) {
            if (states.contains(WidgetState.pressed)) {
              return colors.primary.withValues(alpha: 0.12);
            }
            if (states.contains(WidgetState.hovered)) {
              return colors.primary.withValues(alpha: 0.06);
            }
            return null;
          }),
        ),
      ),
      cardTheme: _cardTheme(colors),
      inputDecorationTheme: _inputDecoration(colors),
      chipTheme: _chipTheme(colors),
      snackBarTheme: _snackBarTheme(colors),
      dialogTheme: _dialogTheme(colors),
      bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: colors.surface,
          modalBackgroundColor: colors.surface,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)))),
      dividerTheme: DividerThemeData(
          color: colors.outlineVariant, thickness: 1, space: 1),
      tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
              color: colors.inverseSurface,
              borderRadius: BorderRadius.circular(4)),
          textStyle: TextStyle(
              color: colors.onInverseSurface,
              fontFamily: _fontFamily,
              fontSize: 12)),
      navigationBarTheme: _navigationBar(colors),
      bottomNavigationBarTheme: _bottomNav(colors),
      tabBarTheme: _tabBar(colors),
      sliderTheme: _slider(colors),
      checkboxTheme: _checkbox(colors),
      switchTheme: _switch(colors),
      popupMenuTheme: _popupMenu(colors),
      scaffoldBackgroundColor: colors.background,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder()
      }),
      scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(colors.surfaceContainerHigh)),
    );
  }
}
