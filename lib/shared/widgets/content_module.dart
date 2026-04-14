import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/constants/colors.dart';
import '../providers/accessibility_providers.dart';

/// Translucent content module — the signature depth card pattern.
///
/// Semi-transparent background with subtle border, no shadow.
/// Designed to float on gradient scaffold backgrounds.
///
/// Variants:
/// - **Content**: icon + title + body text (default)
/// - **Group**: icon + title + arbitrary [child] content
/// - **Action**: icon + title + body + trailing widget + onTap
class ContentModule extends StatelessWidget {
  final IconData? icon;
  final double iconSize;
  final String? title;
  final String? body;
  final Widget? child;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final BoxDecoration? decoration;

  const ContentModule({
    super.key,
    this.icon,
    this.iconSize = 22,
    this.title,
    this.body,
    this.child,
    this.leading,
    this.trailing,
    this.onTap,
    this.padding,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveDecoration = decoration ?? TavliModule.decoration(isDark: isDark);
    final effectivePadding = padding ?? const EdgeInsets.all(TavliSpacing.md);

    Widget content = Container(
      padding: effectivePadding,
      decoration: effectiveDecoration,
      child: _buildContent(context),
    );

    if (onTap != null) {
      content = _TappableModule(
        onTap: onTap!,
        decoration: effectiveDecoration,
        padding: effectivePadding,
        child: _buildContent(context),
      );
    }

    return Semantics(
      button: onTap != null,
      label: onTap != null ? '$title' : null,
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    final hasHeader = icon != null || title != null || leading != null || trailing != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasHeader)
          Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: TavliSpacing.sm),
              ],
              if (icon != null && leading == null) ...[
                Icon(icon, color: TavliColors.light, size: iconSize),
                const SizedBox(width: TavliSpacing.sm),
              ],
              if (title != null)
                Expanded(
                  child: Text(
                    title!,
                    style: TextStyle(
                      color: TavliColors.light,
                      fontSize: 18,
                      fontFamily: TavliTheme.serifFamily,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (trailing != null) ...[
                const SizedBox(width: TavliSpacing.sm),
                trailing!,
              ],
            ],
          ),
        if (body != null) ...[
          if (hasHeader) const SizedBox(height: TavliSpacing.sm),
          Text(
            body!,
            style: const TextStyle(
              color: TavliColors.light,
              fontSize: 15,
              height: 1.55,
            ),
          ),
        ],
        if (child != null) ...[
          if (hasHeader || body != null) const SizedBox(height: TavliSpacing.sm),
          child!,
        ],
      ],
    );
  }
}

/// Tappable version with press state animation.
class _TappableModule extends StatefulWidget {
  final VoidCallback onTap;
  final BoxDecoration decoration;
  final EdgeInsets padding;
  final Widget child;

  const _TappableModule({
    required this.onTap,
    required this.decoration,
    required this.padding,
    required this.child,
  });

  @override
  State<_TappableModule> createState() => _TappableModuleState();
}

class _TappableModuleState extends State<_TappableModule> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: ReducedMotion.duration(context, const Duration(milliseconds: 100)),
        curve: Curves.easeIn,
        padding: widget.padding,
        transform: _pressed
            ? Matrix4.diagonal3Values(0.98, 0.98, 1.0)
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: widget.decoration.copyWith(
          color: _pressed
              ? TavliColors.background.withValues(alpha: 0.22)
              : widget.decoration.color,
        ),
        child: widget.child,
      ),
    );
  }
}
