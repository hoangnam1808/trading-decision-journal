import 'package:flutter/material.dart';

class DjRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
}

class DjSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
}

class DjShadow {
  static List<BoxShadow> soft(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withOpacity(0.22)
            : Colors.black.withOpacity(0.06),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ];
  }
}

class DjCard extends StatelessWidget {
  const DjCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DjSpacing.lg),
    this.margin,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark
        ? colorScheme.surfaceContainerHighest.withOpacity(0.55)
        : colorScheme.surface;

    final borderColor = isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.black.withOpacity(0.06);

    final content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(DjRadius.xl),
        border: Border.all(color: borderColor),
        boxShadow: DjShadow.soft(context),
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(DjRadius.xl),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class DjSectionHeader extends StatelessWidget {
  const DjSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DjSpacing.lg,
        DjSpacing.lg,
        DjSpacing.lg,
        DjSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class DjMetricCard extends StatelessWidget {
  const DjMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final String? caption;
  final IconData? icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DjCard(
      padding: const EdgeInsets.all(DjSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: DjSpacing.sm),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DjSpacing.md),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: valueColor,
              letterSpacing: -0.6,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: DjSpacing.xs),
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DjPill extends StatelessWidget {
  const DjPill({
    super.key,
    required this.label,
    this.icon,
    this.color,
  });

  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = color ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DjSpacing.md,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: baseColor.withOpacity(0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: baseColor),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: baseColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}