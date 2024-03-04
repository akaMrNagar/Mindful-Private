import 'package:flutter/material.dart';

/// Custom card with inkwell for interactivity.
/// Returns just card if [onPressed] is null.
/// This widget is used all over the app wherever needed instead of buttons and tiles
class InteractiveCard extends StatelessWidget {
  const InteractiveCard({
    super.key,
    required this.child,
    this.onPressed,
    this.elevation = 0,
    this.circularRadius = 12,
    this.margin = const EdgeInsets.all(0),
    this.padding = const EdgeInsets.all(12),
    this.applyBorder = false,
    this.borderWidth = 1,
    this.borderRadius,
    this.height,
    this.width,
    this.borderColor,
  });

  final Widget child;
  final double elevation;
  final double circularRadius;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final bool applyBorder;
  final double borderWidth;
  final double? height;
  final double? width;
  final VoidCallback? onPressed;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final paddedChild = Padding(
      padding: padding,
      child: Align(alignment: Alignment.center, child: child),
    );

    return SizedBox(
      height: height,
      width: width,
      child: Card(
        elevation: elevation,
        color: applyBorder
            ? Colors.transparent
            : Theme.of(context).cardColor.withOpacity(
                  onPressed == null ? 0.25 : 1,
                ),
        // color: Colors.transparent,
        surfaceTintColor: Colors.white,
        margin: margin,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(circularRadius),
          side: applyBorder
              ? BorderSide(
                  color: borderColor ?? Theme.of(context).focusColor,
                  width: borderWidth,
                  strokeAlign: BorderSide.strokeAlignInside,
                )
              : BorderSide.none,
        ),
        child: onPressed == null
            ? paddedChild
            : InkWell(
                onTap: onPressed,
                borderRadius:
                    borderRadius ?? BorderRadius.circular(circularRadius),
                splashFactory: InkSparkle.splashFactory,
                child: paddedChild,
              ),
      ),
    );
  }
}