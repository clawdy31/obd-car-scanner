import 'package:flutter/material.dart';

/// Neumorphic design system for Doctor Car app.
/// Light neumorphism: soft gray background with white + gray shadows
/// Dark neumorphism: dark gray background with lighter + darker shadows
class NeuColors {
  // Light theme
  static const lightBg = Color(0xFFE0E5EC);
  static const lightShadowDark = Color(0xFFA3B1C6);
  static const lightShadowLight = Color(0xFFFFFFFF);

  // Dark theme
  static const darkBg = Color(0xFF2D2D30);
  static const darkShadowDark = Color(0xFF1A1A1D);
  static const darkShadowLight = Color(0xFF3D3D42);
}

/// Raised neumorphic container (extruded look)
class NeuContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets? padding;
  final double? width;
  final double? height;

  const NeuContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? NeuColors.darkBg : NeuColors.lightBg,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isDark
            ? [
                // Dark neumorphic: bottom-right dark, top-left lighter
                BoxShadow(
                  color: NeuColors.darkShadowDark,
                  offset: const Offset(5, 5),
                  blurRadius: 15,
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: NeuColors.darkShadowLight,
                  offset: const Offset(-4, -4),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ]
            : [
                // Light neumorphic: bottom-right gray, top-left white
                BoxShadow(
                  color: NeuColors.lightShadowDark,
                  offset: const Offset(5, 5),
                  blurRadius: 15,
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: NeuColors.lightShadowLight,
                  offset: const Offset(-5, -5),
                  blurRadius: 15,
                  spreadRadius: -2,
                ),
              ],
      ),
      child: child,
    );
  }
}

/// Pressed/inset neumorphic container (pressed button look)
class NeuContainerPressed extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets? padding;

  const NeuContainerPressed({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? NeuColors.darkBg : NeuColors.lightBg,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isDark
            ? [
                // Inset dark: inner shadows reversed
                BoxShadow(
                  color: NeuColors.darkShadowLight,
                  offset: const Offset(-3, -3),
                  blurRadius: 8,
                  spreadRadius: -1,
                ),
                BoxShadow(
                  color: NeuColors.darkShadowDark.withAlpha(128),
                  offset: const Offset(3, 3),
                  blurRadius: 8,
                  spreadRadius: -1,
                ),
              ]
            : [
                // Inset light
                BoxShadow(
                  color: NeuColors.lightShadowDark.withAlpha(77),
                  offset: const Offset(3, 3),
                  blurRadius: 8,
                  spreadRadius: -1,
                ),
                BoxShadow(
                  color: NeuColors.lightShadowLight,
                  offset: const Offset(-3, -3),
                  blurRadius: 8,
                  spreadRadius: -1,
                ),
              ],
      ),
      child: child,
    );
  }
}

/// Neumorphic icon button
class NeuIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? iconColor;

  const NeuIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 50,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isDark ? NeuColors.darkBg : NeuColors.lightBg,
          shape: BoxShape.circle,
          boxShadow: isDark
              ? [
                  BoxShadow(color: NeuColors.darkShadowDark, offset: const Offset(4, 4), blurRadius: 10, spreadRadius: -2),
                  BoxShadow(color: NeuColors.darkShadowLight, offset: const Offset(-3, -3), blurRadius: 8, spreadRadius: -2),
                ]
              : [
                  BoxShadow(color: NeuColors.lightShadowDark, offset: const Offset(5, 5), blurRadius: 12, spreadRadius: -2),
                  BoxShadow(color: NeuColors.lightShadowLight, offset: const Offset(-5, -5), blurRadius: 12, spreadRadius: -2),
                ],
        ),
        child: Icon(icon, color: iconColor ?? (isDark ? Colors.white70 : Colors.grey[700]), size: size * 0.45),
      ),
    );
  }
}

/// Text color helper for neumorphic light theme
class NeuText {
  static Color primary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF2D2D30);

  static Color secondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.grey[600]!;

  static Color accent(Color color) => color;
}
