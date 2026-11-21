import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/core/router/routes.dart'
    show Routes, shellOverlayMarker, showShellTopBarFor;
import 'package:tarlan_bank/core/router/auth_intent.dart';
import 'package:tarlan_bank/core/router/shell_index_provider.dart';
import 'package:tarlan_bank/features/auth/providers/auth_providers.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';

import '../../utils/themes/theme_extension.dart';
import '../shared/widgets.dart';

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

  Widget _searchField(ThemeData theme) {
    final extra = theme.extension<Extra>();
    final color = extra?.secondaryText ?? theme.colorScheme.onSurfaceVariant;
    return TextField(
      controller: _searchController,
      textAlignVertical: TextAlignVertical.center,
      textInputAction: TextInputAction.search,
      style: TextStyle(color: color),
      decoration: InputDecoration(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: true,
        fillColor: Colors.transparent,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(14),
          child: SvgPicture.asset(
            'assets/icons/ic_search.svg',
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        hintText: AppLocalizations.of(context).searchHint,
        hintStyle: TextStyle(color: color.withValues(alpha: 0.7)),
        contentPadding: const EdgeInsets.only(left: 48, right: 16),
      ),
    );
  }

  CurvedNavigationBarItem _tabIcon(int index, int selected, ThemeData theme) {
    final isSelected = index == selected;
    final color = isSelected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.inverseSurface;
    return CurvedNavigationBarItem(
      child: AnimatedContainer(
        duration: Duration(milliseconds: isSelected ? 300 : 150),
        curve: isSelected ? Curves.easeOutCubic : Curves.easeInOut,
        width: isSelected ? 40 : 30,
        height: isSelected ? 40 : 30,
        child: SvgPicture.asset(
          _tabs[index].icon,
          width: isSelected ? 26 : 22,
          height: isSelected ? 26 : 22,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final isFullUser = ref.watch(isFullUserProvider);
    final selected = widget.navigationShell.currentIndex.clamp(
      0,
      _tabs.length - 1,
    );
    final showTopBar = showShellTopBarFor(_currentPath);

    return Scaffold(
      appBar: showTopBar
          ? FrostedAppBar(
              leading: IconButton(
                tooltip: l.menu,
                icon: SizedBox(
                  width: 38,
                  height: 38,
                  child: SvgPicture.asset(
                    'assets/icons/ic_user.svg',
                    colorFilter: ColorFilter.mode(
                      theme.colorScheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                onPressed: () => _pushOverlay(Routes.profile),
              ),
              actionsPadding: const EdgeInsets.only(right: 8),
              actions: [
                IconButton(
                  tooltip: l.investments,
                  icon: SvgPicture.asset(
                    'assets/icons/ic_chatbot.svg',
                    width: 32,
                    height: 32,
                    colorFilter: ColorFilter.mode(
                      theme.colorScheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                  onPressed: () => _pushOverlay(Routes.chatbot),
                ),
              ],
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _searchField(theme),
              ),
            )
          : null,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: SafeArea(top: false, bottom: false, child: widget.navigationShell),
      bottomNavigationBar: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.35),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 12 + kBottomNavigationBarHeight,
                ),
              ),
            ),
          ),
          CurvedNavigationBar(
            color: theme.colorScheme.surfaceContainer,
            buttonBackgroundColor: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.surface.withValues(alpha: 0),
            index: selected,
            items: List.generate(
              _tabs.length,
              (index) => _tabIcon(index, selected, theme),
            ),
            letIndexChange: (index) => true,
            onTap: (index) => _onTap(index, isFullUser),
            animationDuration: const Duration(milliseconds: 300),
            animationCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}
