import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/animations.dart';

class CustomCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final Color? color;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final List<BoxShadow>? boxShadow;
  final bool animated;
  final Duration animationDuration;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
    this.color,
    this.borderRadius,
    this.onTap,
    this.boxShadow,
    this.animated = true,
    this.animationDuration = AppAnimations.normalDuration,
  });

  @override
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _elevationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.reverse();
      Future.delayed(const Duration(milliseconds: 100), widget.onTap!);
    }
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      padding: widget.padding ?? const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: widget.color ?? AppTheme.cardColor,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(AppTheme.radiusM),
        boxShadow: widget.boxShadow ?? [
          BoxShadow(
            color: Colors.black.withOpacity(0.05 + _elevationAnimation.value * 0.1),
            blurRadius: 10 + _elevationAnimation.value * 10,
            offset: Offset(0, 2 + _elevationAnimation.value * 4),
          ),
        ],
      ),
      child: widget.child,
    );

    if (widget.onTap != null) {
      cardContent = GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: cardContent,
      );
    }

    Widget animatedCard = widget.animated
        ? TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: widget.animationDuration,
            curve: AppAnimations.defaultCurve,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Transform.scale(
                    scale: 0.95 + (0.05 * value),
                    child: child,
                  ),
                ),
              );
            },
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: cardContent,
            ),
          )
        : cardContent;

    return Container(
      margin:
          widget.margin ??
          const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingS,
          ),
      child: animatedCard,
    );
  }
}

class StatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;
  final int? animationDelay;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.onTap,
    this.animationDelay,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _iconAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.normalDuration,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.defaultCurve),
    );
    _iconAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    if (widget.animationDelay != null) {
      Future.delayed(Duration(milliseconds: widget.animationDelay!), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CustomCard(
        onTap: widget.onTap,
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _iconAnimation,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, color: widget.iconColor, size: 32),
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                widget.value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryTextColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXS),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const InfoCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      padding: padding ?? const EdgeInsets.all(AppTheme.spacingM),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppTheme.spacingM),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppTheme.spacingM),
            trailing!,
          ],
        ],
      ),
    );
  }
}
