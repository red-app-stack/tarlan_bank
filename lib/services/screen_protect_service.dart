import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// In-house screen-protection service — a thin replacement for the
/// `screen_protector` package, implemented natively in this app's own
/// platform code (no third-party plugin Kotlin/Swift):
///
/// - Android: [MethodChannel] -> MainActivity.kt sets/clears
///   `WindowManager.LayoutParams.FLAG_SECURE`, which blocks screenshots
///   and screen recording at the OS level.
/// - iOS: no OS-level screenshot-blocking API exists; MainActivity's
///   AppDelegate.swift shows a blurred snapshot overlay over the whole
///   app when it goes to background (app-switcher / lock-screen
///   snapshots), mirroring what `screen_protector` does there.
/// - Web and other platforms: safe no-op — there is no native handler,
///   so calls resolve without throwing (the old package would have
///   thrown MissingPluginException on web).
class ScreenProtect {
  static const MethodChannel _channel = MethodChannel('screen_protect_native');

  /// Turn protection on. Android: FLAG_SECURE added. iOS: blur overlay
  /// armed (applied whenever the app resigns active). Other platforms: no-op.
  static Future<void> enable() => _invoke('enable');

  /// Turn protection off. Android: FLAG_SECURE cleared. iOS: overlay hidden.
  static Future<void> disable() => _invoke('disable');

  static Future<void> _invoke(String method) async {
    if (kIsWeb) return; // no native handler on web — do nothing, don't throw
    try {
      await _channel.invokeMethod(method);
    } on MissingPluginException {
      // Platform without a native handler (e.g. desktop builds) — safe no-op
    }
  }
}
