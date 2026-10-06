import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.cardTheme.color ?? theme.colorScheme.surface;

    BorderSide borderSide = BorderSide.none;
    if (border != null && border!.top != BorderSide.none) {
      borderSide = border!.top;
    } else if (theme.cardTheme.shape is RoundedRectangleBorder) {
      borderSide = (theme.cardTheme.shape as RoundedRectangleBorder).side;
    }

    final shapeBorder = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: borderSide,
    );

    return Padding(
      padding: margin,
      child: Material(
        color: cardColor,
        shape: shapeBorder,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

