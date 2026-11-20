import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Animated SVG with sliding gradient fill.
/// - [asset] — путь к SVG в assets (svg должен быть "залит" белым или без fill so color can apply).
/// - [height] — высота виджета.
/// - [duration] — продолжительность одного цикла анимации.
/// - [visible] — если false, виджет плавно исчезнет (AnimatedOpacity).
class AnimatedGradientSvg extends StatefulWidget {
  final String asset;
  final double height;
  final Duration duration;
  final bool visible;
  final BoxFit fit;

  const AnimatedGradientSvg({
    super.key,
    required this.asset,
    this.height = 160,
    this.duration = const Duration(seconds: 3),
    this.visible = true,
    this.fit = BoxFit.contain,
  });

  @override
  State<AnimatedGradientSvg> createState() => _AnimatedGradientSvgState();
}

class _AnimatedGradientSvgState extends State<AnimatedGradientSvg>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);

    // anim: 0.0 -> 1.0 -> 0.0 (reverse true above)
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(covariant AnimatedGradientSvg oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _ctrl.duration = widget.duration;
      _ctrl.reset();
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Main build: ShaderMask with a moving gradient shader.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = [
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      theme.colorScheme.secondary,
    ];

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 420),
      opacity: widget.visible ? 1.0 : 0.0,
      curve: Curves.easeInOut,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedBuilder(
              animation: _anim,
              builder: (context, child) {
                // We create a wider rect for gradient so sliding looks smooth.
                // shift controls offset of gradient, mapped from -width..+width
                final double w = constraints.maxWidth.clamp(120.0, 2000.0);
                final double h = constraints.maxHeight.clamp(20.0, 800.0);

                // shift factor in [-1, 1]
                final double shift = (_anim.value * 2.0) - 1.0;

                // make gradient span across 3x width so it can slide smoothly
                final Rect shaderRect = Rect.fromLTWH(-w, 0, w * 3, h);

                // translate shader by shift * w
                final double dx =
                    shift * w * 0.35; // less translation for subtler motion

                final Gradient gradient = LinearGradient(
                  begin: Alignment(-1.0, -0.2),
                  end: Alignment(1.0, 0.8),
                  colors: colors,
                  stops: const [0.0, 0.5, 1.0],
                  // you can change tileMode to repeated/mirror if you like
                  tileMode: TileMode.mirror,
                );

                return ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (rect) {
                    // create shader inside a shifted rect for animation
                    final Rect moved = shaderRect.shift(Offset(dx, 0));
                    return gradient.createShader(moved);
                  },
                  child: child,
                );
              },
              // The child is the SVG rendered in white so ShaderMask applies colors.
              child: Center(
                child: SvgPicture.asset(
                  widget.asset,
                  height: widget.height,
                  width: constraints.maxWidth,
                  fit: widget.fit,
                  // Render SVG in white so shader masks the fill/stroke.
                  // If your SVG defines colors that block this, make sure paths are "currentColor" or remove fills.
                  color: Colors.white,
                  // ensure color blend mode replaces fill
                  colorBlendMode: BlendMode.srcIn,
                  // allow SVG to size itself
                  semanticsLabel: 'Logo',
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
