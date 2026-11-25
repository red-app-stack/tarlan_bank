// mesh_background.dart
//
// Mesh-gradient background + the shared "backdrop" that glass surfaces sample.
//
// Why this exists
// ---------------
// A mesh gradient is already low-frequency: blurring it changes nothing you
// can see. So glass panels over it do NOT need a BackdropFilter (one
// saveLayer + full-screen read-back + blur passes each). Instead:
//
//   * the mesh is built ONCE into a ui.Vertices buffer (rebuilt only while it
//     animates, ~425 vertices),
//   * the background draws that buffer,
//   * every glass surface draws the same buffer (a slightly "frosted" copy),
//     clipped to its own shape and offset to its position on the page.
//
// Cost per glass surface: one clipped drawVertices (~770 triangles) + a few
// rect fills. No saveLayer, no blur, no extra texture. 5 panels ≈ free.
//
// Caveat: sampling assumes the panel doesn't move relative to the background
// without repainting (scrolling lists, sliding route transitions). For those,
// pass `repaintWhen:` (e.g. the ScrollController) or use GlassMode.live.

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

// ---------------------------------------------------------------------------
// Spec: control points + colors
// ---------------------------------------------------------------------------

/// Role colors for the mesh. `light` / `dark` are the brand presets.
@immutable
class MeshPalette {
  const MeshPalette({
    required this.coreMint,
    required this.coreMintAlt,
    required this.midEmerald,
    required this.midEmeraldAlt,
    required this.deepForest,
    required this.deepForestAlt,
    required this.canvas,
    required this.canvasAlt,
  });

  final Color coreMint; // peak
  final Color coreMintAlt;
  final Color midEmerald;
  final Color midEmeraldAlt;
  final Color deepForest;
  final Color deepForestAlt;
  final Color canvas;
  final Color canvasAlt;

  static const light = MeshPalette(
    // Main mint, darker side, soft pale accent, then the mist.
    coreMint: Color(0xFF7CE2C0),
    coreMintAlt: Color(0xFF03C689),
    midEmerald: Color(0xFF03C689),
    midEmeraldAlt: Color(0xFFAEEAD4),
    deepForest: Color(0xFFC2F1E1),
    deepForestAlt: Color(0xFFE6F7F1),
    canvas: Color(0xFFFFFFFF),
    canvasAlt: Color(0xFFFFFFFF),
  );

  static const dark = MeshPalette(
    coreMint: Color(0xFF168564),
    coreMintAlt: Color(0xFF289675),
    midEmerald: Color(0xFF006038),
    midEmeraldAlt: Color(0xFF12694E),
    deepForest: Color(0xFF152C24),
    deepForestAlt: Color(0xFF0C2A21),
    canvas: Color(0xFF0A1310),
    canvasAlt: Color(0xFF0A1310),
  );

  /// Theme contribution: canvas follows the surface colors, and the greens are
  /// pulled toward `primary` (strongest on the peak, barely on the deep tones).
  MeshPalette themed(ColorScheme cs, {double accentMix = 0.0}) {
    Color a(Color c, double m) => Color.lerp(c, cs.primary, m)!;
    return MeshPalette(
      coreMint: a(coreMint, accentMix),
      coreMintAlt: a(coreMintAlt, accentMix),
      midEmerald: a(midEmerald, accentMix * 0.8),
      midEmeraldAlt: a(midEmeraldAlt, accentMix * 0.8),
      deepForest: a(deepForest, accentMix * 0.3),
      deepForestAlt: a(deepForestAlt, accentMix * 0.3),
      canvas: cs.surface,
      canvasAlt: cs.surfaceContainerLow,
    );
  }
}

/// A grid of control points (normalized 0..1) with one color each.
@immutable
class MeshSpec {
  const MeshSpec({
    required this.cols,
    required this.rows,
    required this.points,
    required this.colors,
  }) : assert(points.length == cols * rows),
       assert(colors.length == cols * rows);

  final int cols;
  final int rows;
  final List<Offset> points;
  final List<Color> colors;

  /// Layout traced from the reference image: a bright core near the top-left,
  /// a dark emerald strip on its left edge, quick falloff down and to the
  /// right, and plain canvas below ~45% of the height.
  ///
  /// [palette] gives the role colors (defaults to the light/dark presets);
  /// the theme then contributes: canvas = surface, canvasAlt =
  /// surfaceContainerLow, and the greens are pulled toward `primary` by
  /// [accentMix]. [intensity] (0..1) fades the whole glow toward the canvas.
  /// [seed] nudges the blob sideways and jitters points a little per page.
  factory MeshSpec.fromScheme(
    ColorScheme cs, {
    MeshPalette? palette,
    double accentMix = 0.0,
    int seed = 0,
    double intensity = 1.0,
    double drift = 0.08,
  }) {
    final dark = cs.brightness == Brightness.dark;
    final p = (palette ?? (dark ? MeshPalette.dark : MeshPalette.light)).themed(
      cs,
      accentMix: accentMix,
    );
    const xs = <double>[0.0, 0.20, 0.58, 1.0];
    const ys = <double>[0.0, 0.12, 0.28, 0.50, 0.68, 1.0];
    final cols = xs.length;
    final rows = ys.length;
    final rnd = math.Random(seed * 7919 + 17);
    // Deterministic per-page randomness, logged so seeds can be cherry-picked.
    final shift = (rnd.nextDouble() * 2 - 1) * 0.10;
    final rowDrift = (rnd.nextDouble() * 2 - 1) * 0.045;
    final k = intensity.clamp(0.0, 1.0);

    Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;
    final grid = <List<Color>>[
      [
        p.midEmerald,
        p.coreMintAlt,
        mix(p.coreMintAlt, p.deepForestAlt, 0.50),
        p.deepForest,
      ],
      [
        p.midEmerald,
        p.coreMint,
        mix(p.coreMintAlt, p.deepForestAlt, 0.60),
        p.deepForest,
      ],
      [p.midEmerald, p.midEmeraldAlt, p.deepForestAlt, p.canvas],
      // Long feather: a faint wash reaches y=0.5 before the canvas takes over.
      [
        mix(p.deepForestAlt, p.canvas, 0.55),
        mix(p.deepForestAlt, p.canvas, 0.75),
        p.canvas,
        p.canvas,
      ],
      [p.canvas, p.canvas, p.canvas, p.canvas],
      [p.canvas, p.canvas, p.canvas, p.canvas],
    ];

    final points = <Offset>[];
    final colors = <Color>[];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final jx = (rnd.nextDouble() * 2 - 1) * drift;
        final jy = (rnd.nextDouble() * 2 - 1) * drift;
        var x = xs[c];
        var y = ys[r];
        if (c == 1 || c == 2) x += shift + jx; // interior columns only
        if (r > 0 && r < 3) y += jy + rowDrift; // 0.42 row stays fixed
        points.add(Offset(x, y));
        colors.add(Color.lerp(p.canvas, grid[r][c], k)!);
      }
    }
    debugPrint(
      '[Mesh] seed=$seed shift=${shift.toStringAsFixed(3)} '
      'rowDrift=${rowDrift.toStringAsFixed(3)} drift=${drift.toStringAsFixed(3)} '
      'litX=${points.sublist(0, cols * 3).map((p) => p.dx.toStringAsFixed(2)).join(',')}',
    );
    return MeshSpec(cols: cols, rows: rows, points: points, colors: colors);
  }

  /// Same points, one flat color. Used as the "before" state of the open
  /// animation so the primary glow fades in.
  factory MeshSpec.flat(MeshSpec like, Color color) => MeshSpec(
    cols: like.cols,
    rows: like.rows,
    points: like.points,
    colors: List<Color>.filled(like.colors.length, color),
  );

  static MeshSpec lerp(MeshSpec a, MeshSpec b, double t) {
    assert(a.cols == b.cols && a.rows == b.rows);
    return MeshSpec(
      cols: a.cols,
      rows: a.rows,
      points: [
        for (var i = 0; i < a.points.length; i++)
          Offset.lerp(a.points[i], b.points[i], t)!,
      ],
      colors: [
        for (var i = 0; i < a.colors.length; i++)
          Color.lerp(a.colors[i], b.colors[i], t)!,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Controller: owns the vertex buffers + the (rare) animation
// ---------------------------------------------------------------------------

class MeshBackdropController extends ChangeNotifier {
  MeshBackdropController({
    required TickerProvider vsync,
    required MeshSpec initial,
    required this.backgroundKey,
    Duration duration = const Duration(milliseconds: 1100),
    this.curve = Curves.easeInOutCubic,
    this.frostSaturation = 1.25,
  }) : _cols = initial.cols,
       _rows = initial.rows,
       _from = initial,
       _to = initial,
       _current = initial {
    _anim = AnimationController(vsync: vsync, duration: duration)
      ..addListener(_onTick);
    final built = _build(initial);
    _plain = built.plain;
    _frosted = built.frosted;
  }

  /// Key of the RenderBox that paints the background; glass surfaces measure
  /// their position against it.
  final GlobalKey backgroundKey;
  final Curve curve;

  /// Glass copies of the mesh are a touch more saturated and lighter, which is
  /// what makes the glass read as glass over a flat-ish surface color.
  final double frostSaturation;

  static const int _subdiv = 8; // per cell; 3x4 grid -> 17x25 vertices

  final int _cols;
  final int _rows;
  late final AnimationController _anim;
  late ui.Vertices _plain;
  late ui.Vertices _frosted;
  late final Uint16List _indices = _buildIndices();
  MeshSpec _from;
  MeshSpec _to;
  MeshSpec _current;

  /// Exact mesh. Used by the page background.
  ui.Vertices get vertices => _plain;

  /// Frosted mesh. Used by glass surfaces.
  ui.Vertices get frostedVertices => _frosted;

  bool get isAnimating => _anim.isAnimating;

  RenderBox? get backgroundBox {
    final ro = backgroundKey.currentContext?.findRenderObject();
    if (ro is RenderBox && ro.attached && ro.hasSize) return ro;
    return null;
  }

  void jumpTo(MeshSpec spec) {
    _anim.stop();
    _from = _to = _current = spec;
    _swap(spec);
  }

  void animateTo(MeshSpec target, {Duration? duration}) {
    _from = _current;
    _to = target;
    if (duration != null) _anim.duration = duration;
    _anim.forward(from: 0);
  }

  void _onTick() {
    _current = MeshSpec.lerp(_from, _to, curve.transform(_anim.value));
    _swap(_current);
  }

  void _swap(MeshSpec spec) {
    final oldPlain = _plain;
    final oldFrosted = _frosted;
    final built = _build(spec);
    _plain = built.plain;
    _frosted = built.frosted;
    notifyListeners();
    oldPlain.dispose();
    oldFrosted.dispose();
  }

  @override
  void dispose() {
    _anim.dispose();
    _plain.dispose();
    _frosted.dispose();
    super.dispose();
  }

  // -- geometry --------------------------------------------------------------

  Uint16List _buildIndices() {
    final vx = (_cols - 1) * _subdiv + 1;
    final vy = (_rows - 1) * _subdiv + 1;
    final out = Uint16List((vx - 1) * (vy - 1) * 6);
    var n = 0;
    for (var j = 0; j < vy - 1; j++) {
      for (var i = 0; i < vx - 1; i++) {
        final a = j * vx + i;
        final b = a + 1;
        final c = a + vx;
        final d = c + 1;
        out[n++] = a;
        out[n++] = b;
        out[n++] = c;
        out[n++] = b;
        out[n++] = d;
        out[n++] = c;
      }
    }
    return out;
  }

  // C2-continuous ease: no visible creases where cells meet.
  static double _quint(double t) => t * t * t * (t * (t * 6 - 15) + 10);

  ({ui.Vertices plain, ui.Vertices frosted}) _build(MeshSpec s) {
    final cols = s.cols;
    final rows = s.rows;
    final vx = (cols - 1) * _subdiv + 1;
    final vy = (rows - 1) * _subdiv + 1;
    final count = vx * vy;
    final pos = Float32List(count * 2);
    final plain = Int32List(count);
    final frost = Int32List(count);

    var k = 0;
    for (var j = 0; j < vy; j++) {
      final cy = math.min(j ~/ _subdiv, rows - 2);
      final v = (j - cy * _subdiv) / _subdiv;
      final sv = _quint(v);
      for (var i = 0; i < vx; i++) {
        final cx = math.min(i ~/ _subdiv, cols - 2);
        final u = (i - cx * _subdiv) / _subdiv;
        final su = _quint(u);

        final i00 = cy * cols + cx;
        final i10 = i00 + 1;
        final i01 = i00 + cols;
        final i11 = i01 + 1;

        // Positions: plain bilinear, so dragged control points make quads.
        final top = Offset.lerp(s.points[i00], s.points[i10], u)!;
        final bot = Offset.lerp(s.points[i01], s.points[i11], u)!;
        final p = Offset.lerp(top, bot, v)!;
        pos[k * 2] = p.dx;
        pos[k * 2 + 1] = p.dy;

        // Colors: eased weights.
        final c = Color.lerp(
          Color.lerp(s.colors[i00], s.colors[i10], su)!,
          Color.lerp(s.colors[i01], s.colors[i11], su)!,
          sv,
        )!;
        plain[k] = c.toARGB32();
        frost[k] = _frost(c).toARGB32();
        k++;
      }
    }

    return (
      plain: ui.Vertices.raw(
        ui.VertexMode.triangles,
        pos,
        colors: plain,
        indices: _indices,
      ),
      frosted: ui.Vertices.raw(
        ui.VertexMode.triangles,
        pos,
        colors: frost,
        indices: _indices,
      ),
    );
  }

  Color _frost(Color c) {
    final l = 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;
    double f(double v) => (l + (v - l) * frostSaturation).clamp(0.0, 1.0);
    final saturated = Color.from(
      alpha: c.a,
      red: f(c.r),
      green: f(c.g),
      blue: f(c.b),
    );
    return Color.lerp(saturated, const Color(0xFFFFFFFF), 0.04)!;
  }
}

// ---------------------------------------------------------------------------
// Scope
// ---------------------------------------------------------------------------

class MeshBackdrop extends InheritedWidget {
  const MeshBackdrop({
    super.key,
    required this.controller,
    required super.child,
  });

  final MeshBackdropController controller;

  static MeshBackdropController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MeshBackdrop>()?.controller;

  @override
  bool updateShouldNotify(MeshBackdrop oldWidget) =>
      controller != oldWidget.controller;
}

// ---------------------------------------------------------------------------
// The background widget
// ---------------------------------------------------------------------------

/// Put this once above your pages (or per page). Glass widgets below it sample
/// it automatically; they fall back to a real BackdropFilter if it's absent.
///
/// Static almost always. It animates only when:
///  * it first appears ([animateOnOpen]) - glow fades/drifts in,
///  * [seed] / [intensity] / [palette] change (page changes),
///  * the ColorScheme changes (light/dark, dynamic color).
/// Honors the platform "reduce motion" setting.
class MeshBackground extends StatefulWidget {
  const MeshBackground({
    super.key,
    required this.child,
    this.seed = 0,
    this.intensity = 1.0,
    this.palette,
    this.accentMix = 0.0,
    this.animateOnOpen = true,
    this.duration = const Duration(milliseconds: 1100),
    this.openDuration = const Duration(milliseconds: 1600),
  });

  final Widget child;
  final int seed;
  final double intensity;
  final MeshPalette? palette;
  final double accentMix;
  final bool animateOnOpen;
  final Duration duration;
  final Duration openDuration;

  @override
  State<MeshBackground> createState() => _MeshBackgroundState();
}

class _MeshBackgroundState extends State<MeshBackground>
    with SingleTickerProviderStateMixin {
  final GlobalKey _bgKey = GlobalKey(debugLabel: 'MeshBackground');
  MeshBackdropController? _c;
  ColorScheme? _scheme;
  bool _reduceMotion = false;

  MeshSpec _target(ColorScheme cs) => MeshSpec.fromScheme(
    cs,
    seed: widget.seed,
    intensity: widget.intensity,
    palette: widget.palette,
    accentMix: widget.accentMix,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cs = Theme.of(context).colorScheme;
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final target = _target(cs);
    final c = _c;
    if (c == null) {
      final open = widget.animateOnOpen && !_reduceMotion;
      final created = MeshBackdropController(
        vsync: this,
        initial: open ? MeshSpec.flat(target, cs.surface) : target,
        backgroundKey: _bgKey,
        duration: widget.duration,
      );
      _c = created;
      if (open) created.animateTo(target, duration: widget.openDuration);
    } else if (cs != _scheme) {
      _retarget(target);
    }
    _scheme = cs;
  }

  @override
  void didUpdateWidget(MeshBackground old) {
    super.didUpdateWidget(old);
    if (old.seed != widget.seed ||
        old.intensity != widget.intensity ||
        old.palette != widget.palette ||
        old.accentMix != widget.accentMix) {
      final cs = _scheme;
      if (cs != null) _retarget(_target(cs));
    }
  }

  void _retarget(MeshSpec target) {
    final c = _c!;
    if (_reduceMotion) {
      c.jumpTo(target);
    } else {
      c.animateTo(target, duration: widget.duration);
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c!;
    // BackdropGroup: any glass in `live` mode shares ONE backdrop capture.
    return BackdropGroup(
      child: MeshBackdrop(
        controller: c,
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: CustomPaint(key: _bgKey, painter: _MeshPainter(c)),
            ),
            widget.child,
          ],
        ),
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
  _MeshPainter(this.controller) : super(repaint: controller);

  final MeshBackdropController controller;
  static final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width, size.height); // vertices live in unit space
    // BlendMode.dst: use the vertex colors only, ignore the paint.
    canvas.drawVertices(controller.vertices, BlendMode.dst, _paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MeshPainter old) => old.controller != controller;
}
