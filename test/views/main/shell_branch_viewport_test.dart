import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/views/main/main_shell.dart';
import 'package:tarlan_bank/views/shared/screen_padding.dart';

void main() {
  testWidgets('real router branches stay full size inside the viewport', (
    tester,
  ) async {
    late StatefulNavigationShell shell;
    final router = GoRouter(
      initialLocation: '/a',
      routes: [
        StatefulShellRoute(
          builder: (context, state, navigationShell) {
            shell = navigationShell;
            return Scaffold(
              appBar: AppBar(title: const Text('shell')),
              bottomNavigationBar: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SizedBox(width: 736, height: 64),
                      ),
                    ],
                  ),
                ),
              ),
              body: ShellBranchViewport(child: navigationShell),
            );
          },
          // Mirror app_router.dart's custom container: a Stack of
          // AnimatedOpacity children, not IndexedStack.
          navigatorContainerBuilder: (context, navigationShell, children) =>
              Stack(
                children: List.generate(children.length, (index) {
                  return AnimatedOpacity(
                    opacity: index == navigationShell.currentIndex ? 1 : 0,
                    duration: Duration.zero,
                    child: IgnorePointer(
                      ignoring: index != navigationShell.currentIndex,
                      child: children[index],
                    ),
                  );
                }),
              ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/a',
                  builder: (_, _) =>
                      const ColoredBox(key: Key('branch-a'), color: Colors.red),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/b',
                  builder: (_, _) => const ColoredBox(
                    key: Key('branch-b'),
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    // Branch content fills the space between app bar and bottom nav, minus
    // the shared 32/16 inset.
    final expected = Size(
      800 - screenPadding.horizontal,
      600 - kToolbarHeight - 80 - screenPadding.vertical,
    );
    expect(tester.getSize(find.byKey(const Key('branch-a'))), expected);

    shell.goBranch(1);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(const Key('branch-b'))), expected);

    router.dispose();
  });
}
