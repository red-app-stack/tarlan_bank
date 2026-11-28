import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart'
    show
        LiquidGlassLens,
        LiquidGlassPillMode,
        LiquidGlassShape,
        LiquidGlassTabBar,
        LiquidGlassTabBarItem,
        LiquidGlassTabItemStyle,
        LiquidGlassTabPillStyle;
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/core/router/routes.dart'
    show Routes, shellOverlayMarker, showShellTopBarFor;
import 'package:tarlan_bank/core/router/auth_intent.dart';
import 'package:tarlan_bank/core/router/shell_index_provider.dart';
import 'package:tarlan_bank/features/auth/providers/auth_providers.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/views/shared/app_icons.dart';

import '../../utils/themes/glass_settings.dart';
import '../shared/formatters.dart';
import '../shared/mesh_background.dart';
import '../shared/screen_padding.dart';
import 'shell_top_bar.dart';

class _Tab {
  final String path;
  final String icon;
  final String activeIcon;
  final String Function(AppLocalizations) label;
  final bool requiresAuth;

  const _Tab({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.requiresAuth = false,
  });
}

/// Order MUST match StatefulShellBranch order in app_router.dart.
const _tabs = [
  _Tab(
    path: Routes.home,
    icon: AppIcons.home,
    activeIcon: AppIcons.homeActive,
    label: lHome,
  ),
  _Tab(
    path: Routes.qr,
    icon: AppIcons.qr,
    activeIcon: AppIcons.qrActive,
    label: lQr,
    requiresAuth: true,
  ),
  _Tab(
    path: Routes.menu,
    icon: AppIcons.menu,
    activeIcon: AppIcons.menuActive,
    label: lServices,
  ),
];

/// Full-capsule outline of the 64pt bottom bar.
const LiquidGlassShape _navBarShape =
    LiquidGlassShape.continuousRoundedRectangle(cornerRadius: 64);

/// The sliding selection capsule sits 6pt inside the bar.
const LiquidGlassShape _navCapsuleShape =
    LiquidGlassShape.continuousRoundedRectangle(cornerRadius: 26);

String lQr(AppLocalizations l) => l.bankQr;
String lHome(AppLocalizations l) => l.home;
String lServices(AppLocalizations l) => l.navServices;

String _tabIcon(int index, bool selected) =>
    selected ? _tabs[index].activeIcon : _tabs[index].icon;

typedef _BottomNavBuilder = Widget Function(
  _MainShellState shell,
  ThemeData theme,
  AppLocalizations l,
  bool isFullUser,
  int selected,
);

/// ONE-LINE SWITCH — swap this function name to compare stored variants:
/// `_buildRoundGlassNav` (old per-item round box),
/// `_buildGlassSelectionNav` (glass pill behind the selected tab), or
/// `_buildPackageGlassNav` (package LiquidGlassTabBar).
_BottomNavBuilder get _bottomNavVariant => _buildGlassSelectionNav;

/// All stored variants, kept so any of them can be switched in above.
final List<_BottomNavBuilder> _allBottomNavVariants = [
  _buildRoundGlassNav,
  _buildGlassSelectionNav,
  _buildPackageGlassNav,
];

/// App shell: one router-driven navigation shell instead of a PageView and a
/// GetX controller. Each tab owns its own StatefulShellBranch, so nested routes
/// (e.g. /transfers/phone → /transfers/history) keep their own stack.
class MainShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  final _searchController = TextEditingController();
  late final GoRouter _router;
  String _currentPath = Routes.home;
  bool _routeUpdateScheduled = false;

  @override
  void initState() {
    super.initState();
    assert(_allBottomNavVariants.length == 3);
    _router = GoRouter.of(context);
    _currentPath = _router.routerDelegate.currentConfiguration.uri.path;
    _router.routerDelegate.addListener(_onRouteChanged);
    ref.listenManual<int>(shellIndexProvider, (_, next) {
      if (next != widget.navigationShell.currentIndex) {
        widget.navigationShell.goBranch(next);
      }
    });
    // Honour a target tab requested from auth/create-account flows.
    final tab = ref.read(pendingShellTabProvider);
    if (tab != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final index = _tabs.indexWhere((t) => t.path == tab);
        if (index >= 0) {
          widget.navigationShell.goBranch(index, initialLocation: true);
          ref.read(shellIndexProvider.notifier).setIndex(index);
        }
        ref.read(pendingShellTabProvider.notifier).clear();
      });
    }
    final overlay = ref.read(pendingOverlayRouteProvider);
    if (overlay != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.push(overlay, extra: const {shellOverlayMarker: true});
        ref.read(pendingOverlayRouteProvider.notifier).clear();
      });
    }
    // Existing accounts can be missing fields after an app update. Check
    // once per shell lifetime (cold start, or returning from login) so they
    // cannot use the app with an incomplete profile.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final user = ref.read(currentUserProvider);
      if (user == null || user.isAnonymous) return;
      bool complete;
      try {
        complete = await ref
            .read(authRepositoryProvider)
            .isProfileComplete(user.uid);
      } catch (_) {
        return; // offline / rules hiccup: never lock the user out
      }
      if (!mounted || complete || !ref.read(isFullUserProvider)) return;
      final location = GoRouterState.of(context).uri.toString();
      if (location.startsWith(Routes.completeProfile)) return;
      context.go(
        Uri(
          path: Routes.completeProfile,
          queryParameters: {'target': location},
        ).toString(),
      );
    });
  }

  @override
  void dispose() {
    _router.routerDelegate.removeListener(_onRouteChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _pushOverlay(String route) {
    if (!ref.read(isFullUserProvider)) {
      final origin = _router.routerDelegate.currentConfiguration.uri.path;
      ref
          .read(pendingAuthIntentProvider.notifier)
          .request(AuthIntent(target: route, origin: origin));
    }
    context.push(route, extra: const {shellOverlayMarker: true});
  }

  void _onRouteChanged() {
    if (_routeUpdateScheduled || !mounted) return;
    _routeUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _routeUpdateScheduled = false;
      if (!mounted) return;
      final latest = _router.routerDelegate.currentConfiguration.uri.path;
      final selected = widget.navigationShell.currentIndex;
      if (ref.read(shellIndexProvider) != selected) {
        ref.read(shellIndexProvider.notifier).setIndex(selected);
      }
      if (latest == _currentPath) return;
      setState(() => _currentPath = latest);
    });
  }

  void _onTap(int index, bool isFullUser) {
    final tab = _tabs[index];
    if (tab.requiresAuth && !isFullUser) {
      final origin = _router.routerDelegate.currentConfiguration.uri.path;
      ref
          .read(pendingAuthIntentProvider.notifier)
          .request(AuthIntent(target: tab.path, origin: origin));
      context.push(Routes.login);
      return;
    }
    if (index == widget.navigationShell.currentIndex) {
      widget.navigationShell.goBranch(index, initialLocation: true);
      return;
    }
    widget.navigationShell.goBranch(index);
    ref.read(shellIndexProvider.notifier).setIndex(index);
  }

  Widget _navItem(
    int index,
    int selected,
    ThemeData theme,
    AppLocalizations l,
    bool isFullUser,
  ) {
    final isSelected = index == selected;
    final target = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Tooltip(
      message: _tabs[index].label(l),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(64),
          splashFactory: InkRipple.splashFactory,
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.10),
          highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
          onTap: () => _onTap(index, isFullUser),
          child: SizedBox(
            child: LiquidGlassLens(
              style: themedGlassStyle(theme, shape: _navBarShape),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: isSelected ? Curves.easeOutBack : Curves.easeInOutCubic,
                height: 48,
                width: 90,
                // decoration: BoxDecoration(
                //   color: isSelected
                //       ? theme.colorScheme.primary.withValues(alpha: 0.12)
                //       : Colors.transparent,
                //   borderRadius: BorderRadius.circular(64),
                //   border: isSelected
                //       ? Border.all(
                //           color: theme.colorScheme.primary.withValues(alpha: 0.28),
                //         )
                //       : null,
                // ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedScale(
                      scale: isSelected ? 1.12 : 1.0,
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutBack,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            _tabIcon(index, isSelected),
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(
                              target,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _tabs[index].label(l),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: target,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Positioned(
                    //   bottom: 0,
                    //   child: AnimatedContainer(
                    //     duration: const Duration(milliseconds: 260),
                    //     width: isSelected ? 4 : 0,
                    //     height: isSelected ? 4 : 0,
                    //     decoration: BoxDecoration(
                    //       color: theme.colorScheme.primary,
                    //       shape: BoxShape.circle,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final isFullUser = ref.watch(isFullUserProvider);
    final profile = ref.watch(userProfileProvider).value;
    final authUser = ref.watch(currentUserProvider);
    final displayName = formatGreetingName(
      profile?.fullName ?? authUser?.email ?? l.unknown,
    );
    final selected = widget.navigationShell.currentIndex.clamp(
      0,
      _tabs.length - 1,
    );
    final showTopBar = showShellTopBarFor(_currentPath);

    return MeshBackground(
      // Constant seed: changing it on tab taps re-rasterises the backdrop and
      // makes every glass surface look like it changes colour under a finger.
      seed: 999999,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // The nav owns its own bottom slot, so branch content only needs the
        // shared 16px inset — no hidden-content clearance behind the bar.
        extendBody: true,
        extendBodyBehindAppBar: true,
        appBar: showTopBar
            ? ShellTopBar(
                searchController: _searchController,
                displayName: displayName,
                photoUrl: profile?.photoUrl ?? '',
                isLoggedIn: isFullUser,
                onProfileTap: () => _pushOverlay(Routes.profile),
                // The profile screen owns the notification settings section.
                onNotificationsTap: () => _pushOverlay(Routes.profile),
              )
            : null,
        body: SafeArea(
          top: false,
          bottom: false,
          // The shell owns the 32/16 inset for every branch. SizedBox.expand
          // restores tight constraints: the router's branch Stack needs them
          // or it collapses to zero and every tab renders empty.
          child: ShellBranchViewport(child: widget.navigationShell),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          // Align in a Scaffold.bottomNavigationBar expands to the full loose
          // height and steals all space from the body. A full-width Row
          // centers horizontally while keeping the bar's own 64+16 height.
          child: SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: screenSideMargin / 2),
                  child: SizedBox(
                    width: bottomNavWidth(MediaQuery.sizeOf(context).width),
                    child: _bottomNavVariant(
                      this,
                      theme,
                      l,
                      isFullUser,
                      selected,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Variant 1 — the old per-item round glass boxes, kept for comparison.
Widget _buildRoundGlassNav(
  _MainShellState shell,
  ThemeData theme,
  AppLocalizations l,
  bool isFullUser,
  int selected,
) {
  return SizedBox(
    width: double.infinity,
    child: LiquidGlassLens(
      style: themedGlassStyle(theme, shape: _navBarShape),
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            _tabs.length,
            (index) => shell._navItem(index, selected, theme, l, isFullUser),
          ),
        ),
      ),
    ),
  );
}

Widget _plainNavItem(
  _MainShellState shell,
  int index,
  int selected,
  ThemeData theme,
  AppLocalizations l,
  bool isFullUser,
) {
  final isSelected = index == selected;
  final color = isSelected
      ? theme.colorScheme.onPrimaryContainer
      : theme.colorScheme.onSurfaceVariant;
  return Tooltip(
    message: _tabs[index].label(l),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        splashFactory: InkRipple.splashFactory,
        splashColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        highlightColor: theme.colorScheme.primaryContainer.withValues(
          alpha: 0.2,
        ),
        onTap: () => shell._onTap(index, isFullUser),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 2,
          children: [
            SvgPicture.asset(
              _tabIcon(index, isSelected),
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            Text(
              _tabs[index].label(l),
              style: theme.textTheme.labelMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Variant 2 — one 64pt glass bar with a second glass capsule sliding behind
/// the selected tab instead of a round box around every tab.
///
/// The capsule is glass on glass, so it is deliberately not in a batch: it
/// takes a read of its own and refracts the bar under it.
Widget _buildGlassSelectionNav(
  _MainShellState shell,
  ThemeData theme,
  AppLocalizations l,
  bool isFullUser,
  int selected,
) {
  return GlassSelectionBar(
    selected: selected,
    itemCount: _tabs.length,
    theme: theme,
    itemBuilder: (index) =>
        _plainNavItem(shell, index, selected, theme, l, isFullUser),
  );
}

/// Variant 3 — package `LiquidGlassTabBar`, in its plain-capsule mode.
///
/// The bar's moving glass pill is a full-screen overlay that places itself, so
/// it cannot live in a `bottomNavigationBar` slot; `LiquidGlassPillMode.none`
/// is the form the caller places, with a soft sliding highlight. The style is
/// passed in full so the bar does not depend on `Theme.of` for light/dark.
Widget _buildPackageGlassNav(
  _MainShellState shell,
  ThemeData theme,
  AppLocalizations l,
  bool isFullUser,
  int selected,
) {
  return LayoutBuilder(
    builder: (context, constraints) => LiquidGlassTabBar(
      items: [
        for (var i = 0; i < _tabs.length; i++)
          LiquidGlassTabBarItem(
            label: _tabs[i].label(l),
            iconBuilder: (context, glyph) => SvgPicture.asset(
              _tabIcon(i, i == selected),
              width: glyph.size,
              height: glyph.size,
              colorFilter: ColorFilter.mode(glyph.color, BlendMode.srcIn),
            ),
          ),
      ],
      selectedIndex: selected,
      onChanged: (index) => shell._onTap(index, isFullUser),
      width: constraints.maxWidth,
      height: 64,
      margin: EdgeInsets.zero,
      style: themedGlassStyle(theme, shape: _navBarShape),
      itemStyle: LiquidGlassTabItemStyle(
        selectedColor: theme.colorScheme.onPrimaryContainer,
        unselectedColor: theme.colorScheme.onSurfaceVariant,
      ),
      pillStyle: LiquidGlassTabPillStyle(
        mode: LiquidGlassPillMode.none,
        color: theme.colorScheme.primaryContainer,
        animated: true,
      ),
    ),
  );
}

/// The router's branch container is a `Stack` with non-positioned navigators.
/// `Padding` alone gives it loose constraints, so it collapses to zero size
/// and every tab renders blank. `SizedBox.expand` restores tight constraints
/// after the shared 32/16 inset has been applied.
class ShellBranchViewport extends StatelessWidget {
  const ShellBranchViewport({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: screenPadding,
    child: SizedBox.expand(child: child),
  );
}

/// Glass bar + sliding capsule. The two lenses are siblings inside an
/// unclipped Stack: a glass lens clips its children, so a capsule nested in
/// the bar glass disappears at the edge tabs. `Curves.easeOutBack` overshoot
/// is allowed to hover into the shell's 32px side margins.
class GlassSelectionBar extends StatelessWidget {
  const GlassSelectionBar({
    super.key,
    required this.selected,
    required this.itemCount,
    required this.theme,
    required this.itemBuilder,
  });

  final int selected;
  final int itemCount;
  final ThemeData theme;
  final Widget Function(int index) itemBuilder;

  static const double barHeight = 64;
  static const double inset = 6;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / itemCount;
        return SizedBox(
          width: double.infinity,
          height: barHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Positioned.fill(
                child: LiquidGlassLens(
                  style: themedGlassStyle(theme, shape: _navBarShape),
                  child: const SizedBox.expand(),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 340),
                curve: Curves.easeOutBack,
                left: selected * itemWidth + inset,
                top: inset,
                bottom: inset,
                width: itemWidth - inset * 2,
                child: LiquidGlassLens(
                  // Tint only: the bar under it is already frosted.
                  style: themedGlassStyle(
                    theme,
                    shape: _navCapsuleShape,
                    accent: theme.colorScheme.primaryContainer,
                    blur: 0,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              Row(
                children: List.generate(
                  itemCount,
                  (index) => SizedBox(
                    width: itemWidth,
                    height: barHeight,
                    child: itemBuilder(index),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
