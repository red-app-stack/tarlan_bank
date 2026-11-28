import 'package:material_ui/material_ui.dart';

/// App-wide screen inset: 32px horizontal, 16px vertical (top and bottom).
///
/// `MainShell` applies this to the active branch content, so screens that live
/// inside the shell must NOT add a second outer inset of their own. Top-level
/// routes (pushed outside the shell) apply it directly to their body.
const EdgeInsets screenPadding = EdgeInsets.symmetric(
  horizontal: 32,
  vertical: 16,
);

/// Side margins reserved for the bottom nav's `easeOutBack` capsule overshoot.
const double screenSideMargin = 32;

/// Extra top inset for branch roots whose content scrolls under `ShellTopBar`.
/// Together with `screenPadding.top` (16) this preserves the previous
/// `56 + kToolbarHeight` (112) top clearance.
const double shellTopBarExtraTop = 96;

/// Width of the horizontally centered bottom bar: screen width minus the two
/// 32px side margins. The capsule may overshoot into those margins.
double bottomNavWidth(double screenWidth) => screenWidth - screenSideMargin * 2;
