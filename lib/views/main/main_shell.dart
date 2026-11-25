import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassContainer, LiquidRoundedSuperellipse;
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
  _Tab(
    path: Routes.payments,
    icon: 'assets/icons/payments.svg',
    label: lPayments,
    requiresAuth: true,
  ),
  _Tab(
    path: Routes.transfers,
    icon: 'assets/icons/transfers.svg',
    label: lTransfers,
    requiresAuth: true,
  ),
  _Tab(path: Routes.home, icon: 'assets/icons/home.svg', label: lHome),
  _Tab(
    path: Routes.accounts,
    icon: 'assets/icons/card.svg',
    label: lAccounts,
    requiresAuth: true,
  ),
  _Tab(path: Routes.menu, icon: 'assets/icons/menu.svg', label: lMenu),
];

String lPayments(AppLocalizations l) => l.navPayments;
String lTransfers(AppLocalizations l) => l.navTransfers;
String lHome(AppLocalizations l) => l.home;
String lAccounts(AppLocalizations l) => l.navAccounts;
String lMenu(AppLocalizations l) => l.navMenu;

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
          borderRadius: BorderRadius.circular(18),
          splashFactory: InkRipple.splashFactory,
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.10),
          highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
          onTap: () => _onTap(index, isFullUser),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: isSelected ? Curves.easeOutBack : Curves.easeInOutCubic,
            width: 56,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              border: isSelected
                  ? Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.28),
                    )
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.12 : 1.0,
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutBack,
                  child: TweenAnimationBuilder<Color?>(
                    tween: ColorTween(
                      begin: theme.colorScheme.onSurfaceVariant,
                      end: target,
                    ),
                    duration: const Duration(milliseconds: 260),
                    builder: (context, color, _) => SvgPicture.asset(
                      _tabs[index].icon,
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        color ?? target,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    width: isSelected ? 4 : 0,
                    height: isSelected ? 4 : 0,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
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
      seed: selected,
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
            child: GlassContainer(
              width: double.infinity,
              shape: const LiquidRoundedSuperellipse(borderRadius: 24),
              padding: EdgeInsets.zero,
              settings: themedGlassSettings(theme),
              useOwnLayer: true,
              child: SizedBox(
                height: 64,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    _tabs.length,
                    (index) => _navItem(index, selected, theme, l, isFullUser),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
