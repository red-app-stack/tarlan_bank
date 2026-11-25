// glass.dart
//
// GlassSurface (core), GlassPanel (drop-in for _GlassPanel), GlassCard,
// GlassButton, GlassIconButton.
//
// Two backdrop modes:
//
//   GlassMode.shared (default when a MeshBackground is above)
//     Samples the page's mesh buffer directly. No BackdropFilter, no
//     saveLayer, no blur. Visually identical to blurring the mesh because the
//     mesh is already smooth. Use for anything that sits over the background.
//
//   GlassMode.live
//     Real BackdropFilter.grouped blur, sharing one backdrop capture through
//     the BackdropGroup that MeshBackground installs. Use only when glass sits
//     over something that is NOT the mesh (images, scrolling content). Keep it
//     to 1-2 surfaces at a time.
//
// Everything interactive (hover glow that follows the pointer, press spring,
// focus ring) is painted by repaint-listenables, so hovering never rebuilds
// widgets.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import 'mesh_background.dart';

enum GlassMode { auto, shared, live }

// ---------------------------------------------------------------------------
// Palette (resolved from ColorScheme; record => structural equality for free)
// ---------------------------------------------------------------------------

typedef _Palette = ({
  Color tint,
  Color sheenTop,
  Color sheenBottom,
  Color spot,
  Color rimHi,
  Color rimMid,
  Color rimLo,
  Color rimInner,
  Color rimSpot,
  Color focus,
  Color shadow,
});

_Palette _resolvePalette(ColorScheme cs, Color? accent) {
  final dark = cs.brightness == Brightness.dark;
  const white = Color(0xFFFFFFFF);
  const black = Color(0xFF000000);

  if (accent != null) {
    // Filled / primary glass: tinted body, white rim, colored glow shadow.
    return (
      tint: accent.withValues(alpha: dark ? 0.60 : 0.86),
      sheenTop: white.withValues(alpha: 0.30),
      sheenBottom: black.withValues(alpha: 0.12),
      spot: white.withValues(alpha: 0.22),
      rimHi: white.withValues(alpha: 0.75),
      rimMid: white.withValues(alpha: 0.06),
      rimLo: white.withValues(alpha: 0.22),
      rimInner: white.withValues(alpha: 0.10),
      rimSpot: white.withValues(alpha: 0.95),
      focus: cs.onSurface.withValues(alpha: 0.85),
      shadow: accent.withValues(alpha: dark ? 0.40 : 0.32),
    );
  }

  return (
    tint: white.withValues(alpha: dark ? 0.06 : 0.46),
    sheenTop: white.withValues(alpha: dark ? 0.16 : 0.55),
    sheenBottom: cs.primary.withValues(alpha: dark ? 0.05 : 0.04),
    spot: dark
        ? white.withValues(alpha: 0.10)
        : cs.primary.withValues(alpha: 0.08),
    rimHi: white.withValues(alpha: dark ? 0.40 : 1.0),
    rimMid: cs.outlineVariant.withValues(alpha: 0.12),
    // Light mode needs a darker bottom-right edge or the glass disappears.
    rimLo: dark
        ? white.withValues(alpha: 0.16)
        : cs.outline.withValues(alpha: 0.30),
    rimInner: white.withValues(alpha: dark ? 0.05 : 0.60),
    rimSpot: dark
        ? white.withValues(alpha: 0.90)
        : cs.primary.withValues(alpha: 0.75),
    focus: cs.primary,
    shadow: dark
        ? black.withValues(alpha: 0.45)
        : cs.shadow.withValues(alpha: 0.16),
  );
}

// ---------------------------------------------------------------------------
// GlassSurface
// ---------------------------------------------------------------------------

class GlassSurface extends StatefulWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.padding = EdgeInsets.zero,
    this.mode = GlassMode.auto,
    this.elevation = 1.0,
    this.accent,
    this.openTop = false,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.pressScale = 0.97,
    this.rimWidth = 1.2,
    this.blurSigma = 22,
    this.clipBehavior = Clip.none,
    this.repaintWhen,
    this.semanticLabel,
  });

  final Widget child;

  /// Shape is a superellipse ("squircle") with these radii.
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final GlassMode mode;

  /// 0 = flat, 1 = floating, 2+ = hovering high.
  final double elevation;

  /// Non-null => filled/tinted glass (primary buttons).
  final Color? accent;

  /// Skip the top edge of the rim (panel attached to the top of the screen).
  final bool openTop;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  final double pressScale;
  final double rimWidth;

  /// Only used in GlassMode.live.
  final double blurSigma;

  /// Clip the content to the glass shape (needed for scrollables inside).
  final Clip clipBehavior;

  /// shared mode only: repaint the sampled backdrop when this fires. Pass the
  /// ScrollController / route animation if the surface moves over the mesh.
  final Listenable? repaintWhen;

  final String? semanticLabel;

  @override
  State<GlassSurface> createState() => _GlassSurfaceState();
}

class _GlassSurfaceState extends State<GlassSurface>
    with TickerProviderStateMixin {
  static final SpringDescription _spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 520,
    ratio: 0.6,
  );

  late final AnimationController _hover = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    reverseDuration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _hoverCurve = CurvedAnimation(
    parent: _hover,
    curve: Curves.easeOutCubic,
  );
  // Unbounded so the spring may overshoot (tiny "pop" on release).
  late final AnimationController _press = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _focus = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );
  final ValueNotifier<Offset?> _pointer = ValueNotifier<Offset?>(null);

  bool _mouseInside = false;
  bool _pressed = false;

  bool get _interactive =>
      widget.enabled && (widget.onTap != null || widget.onLongPress != null);

  @override
  void dispose() {
    _hover.dispose();
    _press.dispose();
    _focus.dispose();
    _pointer.dispose();
    super.dispose();
  }

  void _pressTo(double target) {
    _press.animateWith(
      SpringSimulation(_spring, _press.value, target, _press.velocity),
    );
  }

  void _setHover(bool v) {
    _mouseInside = v;
    if (v) {
      _hover.forward();
    } else if (!_pressed) {
      _hover.reverse();
    }
  }

  void _tapDown(TapDownDetails d) {
    _pressed = true;
    _pointer.value = d.localPosition; // touch gets the spotlight too
    _hover.forward();
    _pressTo(1);
  }

  void _tapEnd() {
    _pressed = false;
    _pressTo(0);
    if (!_mouseInside) _hover.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final backdrop = widget.mode == GlassMode.live
        ? null
        : MeshBackdrop.maybeOf(context);
    final shared = backdrop != null;
    final shape = RoundedSuperellipseBorder(borderRadius: widget.borderRadius);
    final palette = _resolvePalette(cs, widget.accent);

    final repaint = Listenable.merge([
      _hoverCurve,
      _pointer,
      ?backdrop,
      ?widget.repaintWhen,
    ]);

    Widget content = Padding(padding: widget.padding, child: widget.child);
    if (shared && widget.clipBehavior != Clip.none) {
      content = ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        clipBehavior: widget.clipBehavior,
        child: content,
      );
    }

    Widget fill = _GlassFill(
      backdrop: backdrop,
      shape: shape,
      palette: palette,
      hover: _hoverCurve,
      pointer: _pointer,
      repaint: repaint,
      child: content,
    );

    if (!shared) {
      // Live mode: grouped backdrop blur, clipped to the glass shape.
      fill = ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: BackdropFilter.grouped(
          filter: ui.ImageFilter.blur(
            sigmaX: widget.blurSigma,
            sigmaY: widget.blurSigma,
          ),
          child: fill,
        ),
      );
    }

    Widget surface = RepaintBoundary(
      child: CustomPaint(
        painter: _GlassShadowPainter(
          shape: shape,
          color: palette.shadow,
          elevation: widget.elevation,
          press: _press,
          clipInside: !shared,
        ),
        foregroundPainter: _GlassBorderPainter(
          shape: shape,
          palette: palette,
          width: widget.rimWidth,
          openTop: widget.openTop,
          hover: _hoverCurve,
          pointer: _pointer,
          focus: _focus,
        ),
        child: fill,
      ),
    );

    if (_interactive) {
      surface = AnimatedBuilder(
        animation: _press,
        child: surface,
        builder: (context, child) => Transform.scale(
          scale: 1 - (1 - widget.pressScale) * _press.value,
          child: child,
        ),
      );
      surface = MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _setHover(true),
        onExit: (_) => _setHover(false),
        onHover: (e) => _pointer.value = e.localPosition,
        child: surface,
      );
      surface = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _tapDown,
        onTapUp: (_) => _tapEnd(),
        onTapCancel: _tapEnd,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: surface,
      );
      surface = FocusableActionDetector(
        onShowFocusHighlight: (v) => v ? _focus.forward() : _focus.reverse(),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap?.call();
              return null;
            },
          ),
        },
        child: surface,
      );
    }

    return Semantics(
      container: true,
      button: _interactive,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      child: surface,
    );
  }
}

// ---------------------------------------------------------------------------
// Fill: samples the shared mesh, adds tint + sheen + pointer spotlight
// ---------------------------------------------------------------------------

class _GlassFill extends SingleChildRenderObjectWidget {
  const _GlassFill({
    required this.backdrop,
    required this.shape,
    required this.palette,
    required this.hover,
    required this.pointer,
    required this.repaint,
    super.child,
  });

  final MeshBackdropController? backdrop; // null => live mode, no sampling
  final ShapeBorder shape;
  final _Palette palette;
  final Animation<double> hover;
  final ValueListenable<Offset?> pointer;
  final Listenable repaint;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderGlassFill(
    backdrop: backdrop,
    shape: shape,
    palette: palette,
    hover: hover,
    pointer: pointer,
    repaint: repaint,
  );

  @override
  void updateRenderObject(BuildContext context, _RenderGlassFill r) {
    r
      ..backdrop = backdrop
      ..shape = shape
      ..palette = palette
      ..hover = hover
      ..pointer = pointer
      ..repaint = repaint;
  }
}

class _RenderGlassFill extends RenderProxyBox {
  _RenderGlassFill({
    required this._backdrop,
    required this._shape,
    required this._palette,
    required this._hover,
    required this._pointer,
    required this._repaint,
  });

  MeshBackdropController? _backdrop;
  ShapeBorder _shape;
  _Palette _palette;
  Animation<double> _hover;
  ValueListenable<Offset?> _pointer;
  Listenable _repaint;

  set backdrop(MeshBackdropController? v) {
    if (identical(v, _backdrop)) return;
    _backdrop = v;
    markNeedsPaint();
  }

  set shape(ShapeBorder v) {
    if (_shape == v) return;
    _shape = v;
    _path = null;
    markNeedsPaint();
  }

  set palette(_Palette v) {
    if (_palette == v) return;
    _palette = v;
    markNeedsPaint();
  }

  set hover(Animation<double> v) {
    if (identical(v, _hover)) return;
    _hover = v;
    markNeedsPaint();
  }

  set pointer(ValueListenable<Offset?> v) {
    if (identical(v, _pointer)) return;
    _pointer = v;
    markNeedsPaint();
  }

  set repaint(Listenable v) {
    if (identical(v, _repaint)) return;
    if (attached) _repaint.removeListener(markNeedsPaint);
    _repaint = v;
    if (attached) _repaint.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _repaint.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _repaint.removeListener(markNeedsPaint);
    super.detach();
  }

  Path? _path;
  Size? _pathSize;
  Path _outline() {
    final cached = _path;
    if (cached != null && _pathSize == size) return cached;
    _pathSize = size;
    return _path = _shape.getOuterPath(Offset.zero & size);
  }

  final Paint _fillPaint = Paint();
  final Paint _sheenPaint = Paint();
  final Paint _spotPaint = Paint();
  final Paint _meshPaint = Paint();
  ui.Shader? _sheen;
  (Size, Color, Color)? _sheenKey;

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final p = _palette;
    final rect = Offset.zero & size;

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.clipPath(_outline());

    // 1) Sample the shared mesh at this surface's position on the page.
    final b = _backdrop;
    final bg = b?.backgroundBox;
    if (b != null && bg != null) {
      final origin = localToGlobal(Offset.zero, ancestor: bg);
      canvas.save();
      canvas.translate(-origin.dx, -origin.dy);
      canvas.scale(bg.size.width, bg.size.height);
      canvas.drawVertices(b.frostedVertices, BlendMode.dst, _meshPaint);
      canvas.restore();
    }

    // 2) Tint.
    canvas.drawRect(rect, _fillPaint..color = p.tint);

    // 3) Diagonal sheen (cached shader).
    final key = (size, p.sheenTop, p.sheenBottom);
    if (_sheenKey != key) {
      _sheenKey = key;
      _sheen = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
        [p.sheenTop, p.sheenTop.withValues(alpha: 0), p.sheenBottom],
        const [0.0, 0.55, 1.0],
      );
    }
    canvas.drawRect(rect, _sheenPaint..shader = _sheen);

    // 4) Pointer spotlight.
    final h = _hover.value;
    final pt = _pointer.value;
    if (h > 0.001 && pt != null) {
      final r = (math.max(size.width, size.height) * 0.8).clamp(140.0, 380.0);
      canvas.drawRect(
        rect,
        _spotPaint
          ..shader = ui.Gradient.radial(pt, r, [
            p.spot.withValues(alpha: p.spot.a * h),
            p.spot.withValues(alpha: 0),
          ]),
      );
    }

    canvas.restore();
    super.paint(context, offset);
  }
}

// ---------------------------------------------------------------------------
// Rim: gradient border, inner hairline, pointer-lit edge, focus ring
// ---------------------------------------------------------------------------

class _GlassBorderPainter extends CustomPainter {
  _GlassBorderPainter({
    required this.shape,
    required this.palette,
    required this.width,
    required this.openTop,
    required this.hover,
    required this.pointer,
    required this.focus,
  }) : super(repaint: Listenable.merge([hover, pointer, focus]));

  final ShapeBorder shape;
  final _Palette palette;
  final double width;
  final bool openTop;
  final Animation<double> hover;
  final ValueListenable<Offset?> pointer;
  final Animation<double> focus;

  @override
  void paint(Canvas canvas, Size size) {
    final w = width;
    final rect = Offset.zero & size;
    // Open-top: lay the path out above the visible area and clip, so only the
    // sides + bottom get a rim.
    final bounds = openTop
        ? Rect.fromLTRB(0, -size.height, size.width, size.height)
        : rect;

    canvas.save();
    if (openTop) canvas.clipRect(rect);

    // Main rim: bright top-left, faint middle, defined bottom-right.
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..shader = ui.Gradient.linear(
        rect.topLeft,
        rect.bottomRight,
        [palette.rimHi, palette.rimMid, palette.rimLo],
        const [0.0, 0.5, 1.0],
      );
    final outer = shape.getOuterPath(bounds.deflate(w / 2));
    canvas.drawPath(outer, rim);

    // Inner hairline: gives the glass a thickness.
    final inner = shape.getOuterPath(bounds.deflate(w + 0.75));
    canvas.drawPath(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.75
        ..color = palette.rimInner,
    );

    // Edge that lights up where the pointer is.
    final h = hover.value;
    final pt = pointer.value;
    if (h > 0.001 && pt != null) {
      final r = math.min(260.0, math.max(size.width, size.height) * 0.6);
      canvas.drawPath(
        outer,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w + 0.6
          ..shader = ui.Gradient.radial(pt, r, [
            palette.rimSpot.withValues(alpha: palette.rimSpot.a * h),
            palette.rimSpot.withValues(alpha: 0),
          ]),
      );
    }
    canvas.restore();

    // Keyboard focus ring (outside the shape).
    final f = focus.value;
    if (f > 0.001) {
      canvas.drawPath(
        shape.getOuterPath(rect.inflate(3)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = palette.focus.withValues(alpha: palette.focus.a * f),
      );
    }
  }

  @override
  bool shouldRepaint(_GlassBorderPainter old) =>
      old.shape != shape ||
      old.palette != palette ||
      old.width != width ||
      old.openTop != openTop;
}

// ---------------------------------------------------------------------------
// Shadow: two soft layers, shrinks while pressed
// ---------------------------------------------------------------------------

class _GlassShadowPainter extends CustomPainter {
  _GlassShadowPainter({
    required this.shape,
    required this.color,
    required this.elevation,
    required this.press,
    required this.clipInside,
  }) : super(repaint: press);

  final ShapeBorder shape;
  final Color color;
  final double elevation;
  final Animation<double> press;

  /// Live (translucent) glass must not show the shadow through its body.
  /// Shared glass is opaque, so it just paints over it (cheaper).
  final bool clipInside;

  @override
  void paint(Canvas canvas, Size size) {
    if (elevation <= 0 || color.a == 0) return;
    final e = elevation * (1 - 0.55 * press.value.clamp(0.0, 1.0));
    final rect = Offset.zero & size;
    final path = shape.getOuterPath(rect);

    canvas.save();
    if (clipInside) {
      canvas.clipPath(
        Path.combine(
          ui.PathOperation.difference,
          Path()..addRect(rect.inflate(80 * e + 40)),
          path,
        ),
      );
    }
    _soft(canvas, path, color.a * 0.55, dy: 14 * e, blur: 30 * e);
    _soft(canvas, path, color.a * 0.90, dy: 3 * e, blur: 8 * e);
    canvas.restore();
  }

  void _soft(
    Canvas canvas,
    Path path,
    double alpha, {
    required double dy,
    required double blur,
  }) {
    canvas.drawPath(
      path.shift(Offset(0, dy)),
      Paint()
        ..color = color.withValues(alpha: alpha.clamp(0.0, 1.0))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur / 2),
    );
  }

  @override
  bool shouldRepaint(_GlassShadowPainter old) =>
      old.shape != shape ||
      old.color != color ||
      old.elevation != elevation ||
      old.clipInside != clipInside;
}

// ---------------------------------------------------------------------------
// Public widgets
// ---------------------------------------------------------------------------

/// Drop-in replacement for the old `_GlassPanel`.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.floating = true,
    this.padding,
    this.mode = GlassMode.auto,
    this.elevation = 1.0,
    this.repaintWhen,
  });

  final Widget child;
  final bool floating;
  final EdgeInsetsGeometry? padding;
  final GlassMode mode;
  final double elevation;
  final Listenable? repaintWhen;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: floating
          ? const BorderRadius.all(Radius.circular(24))
          : const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
      padding:
          padding ??
          (floating
              ? const EdgeInsets.all(20)
              : const EdgeInsets.fromLTRB(20, 4, 8, 8)),
      openTop: !floating,
      elevation: floating ? elevation : elevation * 0.7,
      mode: mode,
      repaintWhen: repaintWhen,
      child: child,
    );
  }
}

/// Glass replacement for the old FrostedAppBar, with the same sizing contract.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.bottom,
    this.actionsPadding,
    this.floating = false,
    this.mode = GlassMode.auto,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final EdgeInsets? actionsPadding;
  final bool floating;
  final GlassMode mode;

  static const double _gap = 8;

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight +
        (bottom?.preferredSize.height ?? 0) +
        (floating ? _gap * 2 : 8),
  );

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      titleSpacing: 0,
      actionsPadding: actionsPadding,
      title: title,
      leading: leading,
      actions: actions,
      bottom: bottom,
      systemOverlayStyle: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    );

    return SafeArea(
      top: true,
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          floating ? 16 : 0,
          floating ? _gap : 2,
          floating ? 16 : 0,
          floating ? _gap : 6,
        ),
        child: GlassSurface(
          borderRadius: floating
              ? const BorderRadius.all(Radius.circular(24))
              : const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
          openTop: !floating,
          padding: EdgeInsets.zero,
          elevation: 0,
          mode: mode,
          child: appBar,
        ),
      ),
    );
  }
}

/// Tappable glass card: pointer-lit rim + spotlight, spring press, focus ring.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.mode = GlassMode.auto,
    this.elevation = 1.0,
    this.repaintWhen,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final GlassMode mode;
  final double elevation;
  final Listenable? repaintWhen;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => GlassSurface(
    onTap: onTap,
    onLongPress: onLongPress,
    padding: padding,
    borderRadius: borderRadius,
    mode: mode,
    elevation: elevation,
    repaintWhen: repaintWhen,
    semanticLabel: semanticLabel,
    child: child,
  );
}

/// Pill button. `filled: true` gives the tinted primary variant.
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.filled = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
    this.mode = GlassMode.auto,
    this.repaintWhen,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool filled;
  final EdgeInsetsGeometry padding;
  final GlassMode mode;
  final Listenable? repaintWhen;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    final base = filled ? cs.onPrimary : cs.onSurface;
    final fg = enabled ? base : base.withValues(alpha: 0.45);

    return GlassSurface(
      onTap: onPressed,
      enabled: enabled,
      accent: filled ? cs.primary : null,
      // 24 = half of the default 48px height => pill. Avoid oversized radii
      // (e.g. 999): superellipse radii are not guaranteed to be auto-clamped.
      borderRadius: const BorderRadius.all(Radius.circular(24)),
      padding: padding,
      mode: mode,
      elevation: enabled ? 0.8 : 0.3,
      pressScale: 0.95,
      repaintWhen: repaintWhen,
      semanticLabel: semanticLabel,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 15),
        child: IconTheme.merge(
          data: IconThemeData(color: fg, size: 20),
          child: Center(widthFactor: 1, heightFactor: 1, child: child),
        ),
      ),
    );
  }
}

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 44,
    this.filled = false,
    this.mode = GlassMode.auto,
    this.semanticLabel,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final double size;
  final bool filled;
  final GlassMode mode;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    final base = filled ? cs.onPrimary : cs.onSurface;
    final fg = enabled ? base : base.withValues(alpha: 0.45);

    return GlassSurface(
      onTap: onPressed,
      enabled: enabled,
      accent: filled ? cs.primary : null,
      borderRadius: BorderRadius.all(Radius.circular(size / 2)),
      mode: mode,
      elevation: 0.7,
      pressScale: 0.92,
      semanticLabel: semanticLabel,
      child: SizedBox.square(
        dimension: size,
        child: IconTheme.merge(
          data: IconThemeData(color: fg, size: size * 0.5),
          child: Center(child: icon),
        ),
      ),
    );
  }
}
