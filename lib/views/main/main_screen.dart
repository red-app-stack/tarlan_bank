import 'dart:ui';

import 'package:tarlan_bank/controllers/auth_controller.dart';
import 'package:tarlan_bank/controllers/theme_controller.dart';
import 'package:tarlan_bank/controllers/verification_controller.dart';
import 'package:tarlan_bank/routes/auth_guard.dart';
import 'package:tarlan_bank/services/auth_service.dart';
import 'package:tarlan_bank/services/auth_state_service.dart';
import 'package:tarlan_bank/services/user_repository.dart';
import 'package:tarlan_bank/services/verification_service.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../utils/themes/theme_extension.dart';
import '../shared/widgets.dart';
import 'accounts_screen.dart';
import 'home_screen.dart';
import 'menu_screen.dart';
import 'payments_screen.dart';
import 'transfers_screen.dart';

class MainScreenController extends GetxController {
  late final AuthController _authController;
  late final ThemeController _themeController;

  @override
  void onInit() {
    super.onInit();

    _themeController = Get.find<ThemeController>();

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    Get.put(AuthStateService(), permanent: true);
    Get.put(UserRepository(secureStore: Get.find()));
    Get.put(AuthService(dio: Get.find(), secureStore: Get.find()),
        permanent: true);
    _authController = Get.put(AuthController(), permanent: true);
    await Future.wait([
      _themeController.loadSavedSettings(),
      _authController.checkAuthStatus(),
    ]);
    Get.put(
        VerificationService(
          dio: Get.find(),
          secureStore: Get.find(),
        ),
        permanent: true);
    Get.lazyPut(
      () => VerificationController(),
      fenix: true,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 2;
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  late PageController _pageController;
  final MainScreenController _controller =
      Get.put(MainScreenController(), permanent: true);

  final List<String> _iconPaths = [
    'assets/icons/payments.svg',
    'assets/icons/transfers.svg',
    'assets/icons/home.svg',
    'assets/icons/card.svg',
    'assets/icons/menu.svg',
  ];

  static const Map<String, int> _routeToIndex = {
    '/payments': 0,
    '/transfers': 1,
    '/home': 2,
    '/accounts': 3,
    '/menu': 4,
  };

  static const _routes = {
    0: '/payments',
    1: '/transfers',
    2: '/home',
    3: '/accounts',
    4: '/menu',
  };

  late final List<Widget> _screens = [
    AuthGuard(targetRoute: _routes[0]!, child: PaymentsScreen()),
    AuthGuard(targetRoute: _routes[1]!, child: TransfersScreen()),
    HomeScreen(),
    AuthGuard(targetRoute: _routes[3]!, child: AccountsScreen()),
    MenuScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = _initialTabFromArgs();
    _pageController = PageController(initialPage: _selectedIndex);

    Get.find<AuthStateService>().targetRouteStream.listen((route) {
      print('GOT ROUTE FROM STATE $route');
      if (route != null && route.isNotEmpty) {
        final idx = _routeToIndex[route] ?? _selectedIndex;
        onItemTapped(idx);
        Get.find<AuthStateService>().clearTarget();
      }
    });
  }

  int _initialTabFromArgs() {
    final args = Get.arguments;
    if (args is Map && args['targetRoute'] is String) {
      return _routeToIndex[args['targetRoute']] ?? 2;
    }
    return 2;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Duration _calculateAnimationDuration(int currentIndex, int newIndex) {
    int distance = (currentIndex - newIndex).abs();
    int duration = 100 + (distance * 100);
    return Duration(milliseconds: duration.clamp(100, 500));
  }

  void onItemTapped(int index) {
    _navigateToPage(index);
  }

  void _navigateToPage(int index) {
    if (index == _selectedIndex) return;

    final duration = _calculateAnimationDuration(_selectedIndex, index);

    setState(() {
      _selectedIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: duration,
      curve: Curves.easeInOut,
    );
  }

  Widget _buildTopBarIcons(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.all(Radius.circular(30)),
            ),
            child: TextField(
              textAlignVertical: TextAlignVertical.center,
              textInputAction: TextInputAction.search,
              style: TextStyle(color: theme.extension<Extra>()!.secondaryText!),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: true,
                fillColor: Colors.transparent,
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: SvgPicture.asset(
                    'assets/icons/ic_search.svg',
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      theme.extension<Extra>()!.secondaryText!,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                prefixIconConstraints: BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                hintText: 'Поиск...',
                hintStyle: TextStyle(
                    color: theme
                        .extension<Extra>()!
                        .secondaryText!
                        .withValues(alpha: 0.7)),
                contentPadding: EdgeInsets.only(left: 48, right: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  CurvedNavigationBarItem _buildIcon(int index) {
    final bool isSelected = index == _selectedIndex;
    final String iconPath = _iconPaths[index];
    final animDuration = isSelected ? 300 : 150;

    return CurvedNavigationBarItem(
      child: AnimatedContainer(
        duration: Duration(milliseconds: animDuration),
        curve: isSelected ? Curves.easeOutCubic : Curves.easeInOut,
        width: isSelected ? 40 : 30,
        height: isSelected ? 40 : 30,
        child: TweenAnimationBuilder<Color?>(
          duration: Duration(milliseconds: animDuration),
          curve: isSelected ? Curves.easeOutCubic : Curves.easeOutCubic,
          tween: ColorTween(
            begin: index == 2
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.inverseSurface,
            end: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.inverseSurface,
          ),
          key: ValueKey('icon_$index'),
          builder: (BuildContext context, Color? color, Widget? child) {
            return SvgPicture.asset(
              iconPath,
              colorFilter: ColorFilter.mode(
                color!,
                BlendMode.srcIn,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: FrostedAppBar(
        leading: IconButton(
          icon: SizedBox(
            width: 32,
            height: 32,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                );
              },
              child: SvgPicture.asset(
                'assets/icons/ic_user.svg',
                width: 38,
                height: 38,
                colorFilter: ColorFilter.mode(
                  theme.colorScheme.primary,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          onPressed: () {
            Get.toNamed('/profile');
          },
        ),
        actionsPadding: const EdgeInsets.only(right: 8),
        actions: [
          IconButton(
            icon: Stack(
              alignment: Alignment.topRight,
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                    );
                  },
                  child: SvgPicture.asset(
                    'assets/icons/ic_chatbot.svg',
                    width: 32,
                    height: 32,
                    colorFilter: ColorFilter.mode(
                      theme.colorScheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                // if (_controller.gotMessage.value)
                // Positioned(
                //   top: 3,
                //   right: 3,
                //   child: Container(
                //     width: 8,
                //     height: 8,
                //     decoration: BoxDecoration(
                //       color: theme.extension<Extra>()!.notifications,
                //       shape: BoxShape.circle,
                //     ),
                //   ),
                // ),
              ],
            ),
            onPressed: () {
              Get.toNamed('/chatbot');
            },
          ),
        ],
        title: _buildTopBarIcons(theme),
      ),
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        bottom: false,
        top: false,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: _screens,
        ),
      ),
      bottomNavigationBar: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: .35),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 12 + kBottomNavigationBarHeight,
                ),
              ),
            ),
          ),
          CurvedNavigationBar(
            key: _bottomNavigationKey,
            color: theme.colorScheme.surfaceContainer,
            buttonBackgroundColor: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.background.withValues(alpha: .0),
            index: _selectedIndex,
            items: List.generate(
              _iconPaths.length,
              (index) => _buildIcon(index),
            ),
            letIndexChange: (index) => true,
            onTap: onItemTapped,
            animationDuration: Duration(milliseconds: 300),
            animationCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}
