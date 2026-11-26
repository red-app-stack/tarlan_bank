import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassContainer, GlassTab, GlassTabBar, LiquidRoundedSuperellipse;
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/core/router/routes.dart'
    show Routes, shellOverlayMarker, showShellTopBarFor;
import 'package:tarlan_bank/core/router/auth_intent.dart';
import 'package:tarlan_bank/core/router/shell_index_provider.dart';
import 'package:tarlan_bank/features/auth/providers/auth_providers.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';

import '../../utils/themes/glass_settings.dart';
import '../shared/formatters.dart';
import '../shared/mesh_background.dart';
import 'shell_top_bar.dart';

class _Tab {
  final String path;
  final String icon;
  final String Function(AppLocalizations) label;
  final bool requiresAuth;

  const _Tab({
    required this.path,
    required this.icon,
    required this.label,
    this.requiresAuth = false,
  });
}

/// Order MUST match StatefulShellBranch order in app_router.dart.
const _tabs = [
  _Tab(path: Routes.home, icon: 'assets/icons/home.svg', label: lHome),
  _Tab(
    path: Routes.qr,
    icon: 'assets/icons/ic_qr.svg',
    label: lQr,
    requiresAuth: true,
  ),
  _Tab(path: Routes.menu, icon: 'assets/icons/menu.svg', label: lServices),
];

String lQr(AppLocalizations l) => l.bankQr;
String lHome(AppLocalizations l) => l.home;
String lServices(AppLocalizations l) => l.navServices;

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
/// `_buildPackageGlassNav` (package GlassTabBar.bottom).
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
            child: GlassContainer(
              quality: .minimal,
              shape: const LiquidRoundedSuperellipse(borderRadius: 64),
              padding: EdgeInsets.zero,
              settings: themedGlassSettings(theme),
              useOwnLayer: true,
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
                            _tabs[index].icon,
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
      seed: 0,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        extendBodyBehindAppBar: true,
        appBar: showTopBar
            ? ShellTopBar(
                searchController: _searchController,
                displayName: displayName,
                photoUrl: profile?.photoUrl ?? '',
                onProfileTap: () => _pushOverlay(Routes.profile),
                // The profile screen owns the notification settings section.
                onNotificationsTap: () => _pushOverlay(Routes.profile),
              )
            : null,
        body: SafeArea(
          top: false,
          bottom: false,
          child: widget.navigationShell,
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _bottomNavVariant(this, theme, l, isFullUser, selected),
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
  return GlassContainer(
    quality: .minimal,
    width: double.infinity,
    shape: const LiquidRoundedSuperellipse(borderRadius: 64),
    padding: EdgeInsets.zero,
    settings: themedGlassSettings(theme),
    useOwnLayer: true,
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
              _tabs[index].icon,
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
Widget _buildGlassSelectionNav(
  _MainShellState shell,
  ThemeData theme,
  AppLocalizations l,
  bool isFullUser,
  int selected,
) {
  return LayoutBuilder(
    builder: (context, constraints) {
      const barHeight = 64.0;
      final itemWidth = constraints.maxWidth / _tabs.length;
      return GlassContainer(
        quality: .premium,
        width: double.infinity,
        height: barHeight,
        shape: const LiquidRoundedSuperellipse(borderRadius: 64),
        padding: EdgeInsets.zero,
        settings: themedGlassSettings(theme),
        useOwnLayer: true,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 340),
              curve: Curves.easeOutBack,
              left: selected * itemWidth + 6,
              top: 6,
              bottom: 6,
              width: itemWidth - 12,
              child: GlassContainer(
                quality: .premium,
                shape: const LiquidRoundedSuperellipse(borderRadius: 26),
                padding: EdgeInsets.zero,
                settings: themedGlassSettings(
                  theme,
                  accent: theme.colorScheme.primaryContainer,
                ),
                useOwnLayer: true,
                child: const SizedBox.expand(),
              ),
            ),
            Row(
              children: List.generate(
                _tabs.length,
                (index) => SizedBox(
                  width: itemWidth,
                  height: barHeight,
                  child: _plainNavItem(
                    shell,
                    index,
                    selected,
                    theme,
                    l,
                    isFullUser,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Variant 3 — package `GlassTabBar.bottom` (native-style jelly indicator).
Widget _buildPackageGlassNav(
  _MainShellState shell,
  ThemeData theme,
  AppLocalizations l,
  bool isFullUser,
  int selected,
) {
  return GlassTabBar.bottom(
    tabs: [
      for (var i = 0; i < _tabs.length; i++)
        GlassTab(
          icon: SvgPicture.asset(_tabs[i].icon, width: 24, height: 24),
          label: _tabs[i].label(l),
        ),
    ],
    selectedIndex: selected,
    onTabSelected: (index) => shell._onTap(index, isFullUser),
    barHeight: 64,
    settings: themedGlassSettings(theme),
    indicatorColor: theme.colorScheme.primaryContainer,
    indicatorSettings: themedGlassSettings(
      theme,
      accent: theme.colorScheme.primaryContainer,
    ),
    selectedIconColor: theme.colorScheme.onPrimaryContainer,
    selectedLabelColor: theme.colorScheme.onPrimaryContainer,
    unselectedIconColor: theme.colorScheme.onSurfaceVariant,
    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
    quality: .premium,
  );
}
