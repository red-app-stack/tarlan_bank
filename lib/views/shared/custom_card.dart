import 'package:material_ui/material_ui.dart';

class SimpleCard extends StatelessWidget {
  final Widget? startWidget;
  final String? label;
  final TextStyle? labelStyle;
  final Widget? endWidget;
  final Widget? child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry topRowPadding;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;

  const SimpleCard({
    super.key,
    this.startWidget,
    this.label,
    this.labelStyle,
    this.endWidget,
    this.child,
    this.padding = const EdgeInsets.all(16),
    this.topRowPadding = const EdgeInsets.symmetric(horizontal: 0),
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.spaceBetween,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.all(Radius.circular(30)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(30)),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class CustomCard extends StatelessWidget {
  final Widget? startWidget;
  final String? label;
  final TextStyle? labelStyle;
  final Widget? endWidget;
  final Widget? child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry topRowPadding;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;

  const CustomCard({
    super.key,
    this.startWidget,
    this.label,
    this.labelStyle,
    this.endWidget,
    this.child,
    this.padding = const EdgeInsets.all(16),
    this.topRowPadding = const EdgeInsets.symmetric(horizontal: 0),
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.spaceBetween,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.all(Radius.circular(30)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(30)),
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: crossAxisAlignment,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (startWidget != null || label != null || endWidget != null)
                Padding(
                  padding: topRowPadding,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: mainAxisAlignment,
                    children: [
                      if (startWidget != null) ...[
                        startWidget!,
                        SizedBox(width: 8),
                      ],
                      if (label != null) ...[
                        Padding(
                          padding: EdgeInsets.only(
                            left: (startWidget != null ? 0 : 8.0),
                          ),
                          child: Text(
                            label!,
                            style:
                                labelStyle ??
                                theme.textTheme.labelLarge?.copyWith(
                                  fontSize: 16,
                                ),
                          ),
                        ),
                      ],
                      ?endWidget,
                      if (endWidget == null) SizedBox(width: 8),
                    ],
                  ),
                ),
              if (child != null) ...[
                if (label != null || endWidget != null) SizedBox(height: 16),
                child!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
