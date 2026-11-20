// utils/overlay_helper.dart
import 'package:material_ui/material_ui.dart';

class OverlayHelper {
  static final OverlayHelper _instance = OverlayHelper._internal();
  factory OverlayHelper() => _instance;
  OverlayHelper._internal();
  OverlayEntry? _loadingOverlay;

  void showLoading(BuildContext context) {
    if (_loadingOverlay != null) return;

    _loadingOverlay = OverlayEntry(
      builder: (_) => Material(
        color: Colors.black.withValues(alpha: 0.4),
        child: Center(
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_loadingOverlay!);
  }

  void hideLoading() {
    _loadingOverlay?.remove();
    _loadingOverlay = null;
  }
}
