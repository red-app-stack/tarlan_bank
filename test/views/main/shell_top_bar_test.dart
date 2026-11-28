import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart'
    show LiquidGlassBatch, LiquidGlassEngine, LiquidGlassLens;
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/utils/themes/app_theme.dart';
import 'package:tarlan_bank/utils/themes/glass_settings.dart'
    show diagonalGlassLightAngle;
import 'package:tarlan_bank/views/main/shell_top_bar.dart';
import 'package:tarlan_bank/views/shared/app_icons.dart';
import 'package:tarlan_bank/views/shared/cached_user_avatar.dart';
import 'package:tarlan_bank/views/shared/formatters.dart';

void main() {
  test('greeting name keeps first name and one last-name initial', () {
    expect(formatGreetingName('John Doe Smith'), 'John S.');
    expect(formatGreetingName('John Doe'), 'John D.');
    expect(formatGreetingName('John'), 'John');
    expect(formatGreetingName('  '), isEmpty);
  });

  late TextEditingController controller;

  // Same switch main() flips through initGlass: no shader under flutter test.
  setUpAll(() => LiquidGlassEngine.liteGlassOnSkia = true);
  setUp(() => controller = TextEditingController());
  tearDown(() => controller.dispose());

  Widget bar({
    required ThemeData theme,
    required VoidCallback onProfileTap,
    required VoidCallback onNotificationsTap,
    bool isLoggedIn = true,
  }) {
    return MaterialApp(
      theme: theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        appBar: ShellTopBar(
          searchController: controller,
          displayName: 'John S.',
          photoUrl: '',
          isLoggedIn: isLoggedIn,
          onProfileTap: onProfileTap,
          onNotificationsTap: onNotificationsTap,
        ),
        body: const SizedBox.shrink(),
      ),
    );
  }

  testWidgets(
    'split top bar has cached avatar, 12/16 greeting and glass pills',
    (tester) async {
      var profileTaps = 0;
      var notificationTaps = 0;
      await tester.pumpWidget(
        bar(
          theme: AppTheme.lightTheme,
          onProfileTap: () => profileTaps++,
          onNotificationsTap: () => notificationTaps++,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Greetings,'), findsOneWidget);
      expect(find.text('John S.'), findsOneWidget);
      final greetingStyle = tester.widget<Text>(find.text('Greetings,')).style;
      expect(greetingStyle?.fontSize, 12);
      expect(greetingStyle?.height, closeTo(16 / 12, 0.001));

      final avatar = tester.widget<CachedUserAvatar>(
        find.byType(CachedUserAvatar),
      );
      expect(avatar.size, 35);
      expect(avatar.imageUrl, isEmpty);

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration?.prefixIcon, isNull);
      expect(field.textAlignVertical, TextAlignVertical.center);
      expect(field.decoration?.isDense, isTrue);
      final fieldCenter = tester.getCenter(find.byType(TextField)).dy;
      final pillCenter = tester
          .getCenter(find.byType(LiquidGlassLens).first)
          .dy;
      expect((fieldCenter - pillCenter).abs(), lessThan(1));

      // Zoom icon is 20px, bell 24px; the accent is not painted on the bell.
      final icons = tester
          .widgetList<SvgPicture>(
            find.byWidgetPredicate(
              (w) => w is SvgPicture && (w.width == 20 || w.width == 24),
            ),
          )
          .toList();
      expect(icons.length, 2);
      expect(icons.where((icon) => icon.width == 20).length, 1);
      expect(icons.where((icon) => icon.width == 24).length, 1);
      expect(
        icons.any(
          (icon) =>
              icon.colorFilter ==
              const ColorFilter.mode(Color(0xFFC3D600), BlendMode.srcIn),
        ),
        isFalse,
      );

      final badge = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).color == const Color(0xFFC3D600),
      );
      expect(badge, findsOneWidget);

      final glass = tester
          .widgetList<LiquidGlassLens>(find.byType(LiquidGlassLens))
          .toList();
      expect(glass.length, 2);
      // The bell is a full circle: corner radius is half the 40pt control.
      expect(glass.last.style.shape?.cornerRadius, 20);
      expect(glass.every((g) => g.style.color.a != 0), isTrue);
      expect(
        glass.every((g) => g.style.specular?.angle == diagonalGlassLightAngle),
        isTrue,
      );
      expect(glass.every((g) => g.style.adaptivity == null), isTrue);
      // Search pill and bell share one backdrop read.
      expect(find.byType(LiquidGlassBatch), findsOneWidget);

      await tester.tap(find.byType(InkWell).first);
      await tester.pump();
      expect(profileTaps, 1);

      await tester.tap(find.byType(IconButton).first);
      await tester.pump();
      expect(notificationTaps, 1);
    },
  );

  testWidgets('notification accent stays #C3D600 in dark theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      bar(
        theme: AppTheme.darkTheme,
        onProfileTap: () {},
        onNotificationsTap: () {},
      ),
    );
    await tester.pumpAndSettle();

    final badge = find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration! as BoxDecoration).color == const Color(0xFFC3D600),
    );
    expect(badge, findsOneWidget);
  });

  testWidgets('search icon uses active artwork while focused or querying', (
    tester,
  ) async {
    await tester.pumpWidget(
      bar(
        theme: AppTheme.lightTheme,
        onProfileTap: () {},
        onNotificationsTap: () {},
      ),
    );
    await tester.pumpAndSettle();

    SvgPicture searchIcon() => tester
        .widgetList<SvgPicture>(
          find.byWidgetPredicate((w) => w is SvgPicture && w.width == 20),
        )
        .single;
    expect(
      (searchIcon().bytesLoader as SvgAssetLoader).assetName,
      AppIcons.search,
    );

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(
      (searchIcon().bytesLoader as SvgAssetLoader).assetName,
      AppIcons.searchActive,
    );

    controller.text = 'kzt';
    await tester.pumpAndSettle();
    expect(
      (searchIcon().bytesLoader as SvgAssetLoader).assetName,
      AppIcons.searchActive,
    );

    controller.clear();
    await tester.pumpAndSettle();
    // Still focused after clearing the query.
    expect(
      (searchIcon().bytesLoader as SvgAssetLoader).assetName,
      AppIcons.searchActive,
    );
  });

  testWidgets('signed-out top bar uses the empty avatar artwork', (
    tester,
  ) async {
    await tester.pumpWidget(
      bar(
        theme: AppTheme.lightTheme,
        isLoggedIn: false,
        onProfileTap: () {},
        onNotificationsTap: () {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CachedUserAvatar), findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is SvgPicture &&
            (w.bytesLoader as SvgAssetLoader).assetName == AppIcons.avatarEmpty,
      ),
      findsOneWidget,
    );
  });
}
