import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tarlan_bank/core/router/routes.dart' show Routes;
import 'package:tarlan_bank/views/shared/widgets.dart';

/// Frosted header matching the legacy `buildHeader`, but navigation goes
/// through go_router (`context.canPop()` / `context.pop()` / `context.go`).
PreferredSizeWidget buildTransferHeader(BuildContext context, String label) {
  return FrostedAppBar(
    floating: true,
    leading: IconButton(
      icon: SvgPicture.asset(
        'assets/icons/ic_back.svg',
        width: 36,
        height: 36,
        colorFilter: ColorFilter.mode(
          Theme.of(context).colorScheme.primary,
          BlendMode.srcIn,
        ),
      ),
      onPressed: () {
        FocusScope.of(context).unfocus();
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(Routes.transfers);
        }
      },
    ),
    title: Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 20),
    ),
  );
}

SliverPersistentHeader buildFrostedSliverHeader(
  BuildContext context,
  String label,
) {
  return SliverPersistentHeader(
    pinned: true,
    floating: true,
    delegate: _FrostedSliverHeaderDelegate(buildTransferHeader(context, label)),
  );
}

class _FrostedSliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _FrostedSliverHeaderDelegate(this.child);

  final PreferredSizeWidget child;

  @override
  double get minExtent => child.preferredSize.height;

  @override
  double get maxExtent => child.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(height: maxExtent, width: double.infinity, child: child);
  }

  @override
  bool shouldRebuild(covariant _FrostedSliverHeaderDelegate oldDelegate) =>
      child != oldDelegate.child;
}
