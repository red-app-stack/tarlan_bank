import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

class RightCenterFloatingButtonLocation extends FloatingActionButtonLocation {
  final double verticalOffset; // 0.5 → center, 1.0 → bottom
  final double horizontalOffset; // distance from the right edge

  RightCenterFloatingButtonLocation({
    this.verticalOffset = 0.5,
    this.horizontalOffset = 16.0,
  });

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Size of the FAB and content area.
    final fabSize = scaffoldGeometry.floatingActionButtonSize;
    final contentSize = scaffoldGeometry.scaffoldSize;

    // Compute horizontal position – stay `horizontalOffset` from the right.
    final double x = contentSize.width - fabSize.width - horizontalOffset;

    // Compute vertical position using a helper that mirrors
    // `StandardFabLocation.getOffsetY`.
    final double y = _computeFloatYOffset(scaffoldGeometry, verticalOffset);

    return Offset(x, y);
  }

  /// Returns the Y‑offset for a *float* FAB.  The logic is taken from
  /// Flutter’s own implementation of `centerFloat` and friends.
  double _computeFloatYOffset(
    ScaffoldPrelayoutGeometry scaffoldGeometry,
    double adjustment,
  ) {
    final double contentBottom = scaffoldGeometry.contentBottom;
    final double bottomContentHeight =
        scaffoldGeometry.scaffoldSize.height - contentBottom;
    final double bottomSheetHeight = scaffoldGeometry.bottomSheetSize.height;
    final double fabHeight = scaffoldGeometry.floatingActionButtonSize.height;
    final double snackBarHeight = scaffoldGeometry.snackBarSize.height;

    // Safe margin that keeps the FAB above system UI or keyboard.
    final double safeMargin = math.max(
      kFloatingActionButtonMargin,
      scaffoldGeometry.minViewPadding.bottom -
          bottomContentHeight +
          kFloatingActionButtonMargin,
    );

    double fabY = contentBottom - fabHeight - safeMargin;

    // Keep the FAB from overlapping a snackbar.
    if (snackBarHeight > 0.0) {
      fabY = math.min(
        fabY,
        contentBottom -
            snackBarHeight -
            fabHeight -
            kFloatingActionButtonMargin,
      );
    }

    // Keep the FAB from covering an open bottom sheet.
    if (bottomSheetHeight > 0.0) {
      fabY = math.min(fabY, contentBottom - bottomSheetHeight - fabHeight / 2);
    }

    return fabY + adjustment;
  }
}

class SafeOffsetFab extends StatelessWidget {
  final Widget child;
  final double offsetY;

  const SafeOffsetFab({super.key, required this.child, this.offsetY = 0.0});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: offsetY),
      child: child,
    );
  }
}
