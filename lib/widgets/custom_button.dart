import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonType type;
  final ButtonSize size;
  final IconData? icon;
  final Color? color;
  final Color? textColor;
  final double? width;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.color,
    this.textColor,
    this.width,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
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
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
      Future.delayed(const Duration(milliseconds: 100), widget.onPressed!);
    }
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? _getButtonColor();
    final foregroundColor = widget.textColor ?? _getTextColor();
    final padding = _getPadding();
    final textStyle = _getTextStyle(context);

    Widget buttonChild = widget.isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: foregroundColor,
              strokeWidth: 2,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: _getIconSize()),
                const SizedBox(width: AppTheme.spacingS),
              ],
              Text(widget.text, style: textStyle),
            ],
          );

    Widget button;
    switch (widget.type) {
      case ButtonType.primary:
        button = AnimatedBuilder(
          animation: _elevationAnimation,
          builder: (context, child) {
            return ElevatedButton(
              onPressed: widget.isLoading ? null : widget.onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: foregroundColor,
                padding: padding,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                elevation: 2 + _elevationAnimation.value * 4,
                shadowColor: buttonColor.withOpacity(0.3),
              ),
              child: buttonChild,
            );
          },
        );
        break;
      case ButtonType.secondary:
        button = OutlinedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: buttonColor,
            side: BorderSide(color: buttonColor, width: 2),
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
          ),
          child: buttonChild,
        );
        break;
      case ButtonType.text:
        button = TextButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: TextButton.styleFrom(
            foregroundColor: buttonColor,
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
          ),
          child: buttonChild,
        );
        break;
    }

    Widget animatedButton = GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: button,
      ),
    );

    if (widget.width != null) {
      return SizedBox(width: widget.width, child: animatedButton);
    }

    return animatedButton;
  }

  Color _getButtonColor() {
    switch (widget.type) {
      case ButtonType.primary:
        return AppTheme.primaryColor;
      case ButtonType.secondary:
      case ButtonType.text:
        return AppTheme.primaryColor;
    }
  }

  Color _getTextColor() {
    switch (widget.type) {
      case ButtonType.primary:
        return Colors.white;
      case ButtonType.secondary:
      case ButtonType.text:
        return AppTheme.primaryColor;
    }
  }

  EdgeInsetsGeometry _getPadding() {
    switch (widget.size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        );
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingL,
          vertical: AppTheme.spacingM,
        );
      case ButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingXL,
          vertical: AppTheme.spacingL,
        );
    }
  }

  TextStyle _getTextStyle(BuildContext context) {
    final baseStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      color: widget.textColor ?? _getTextColor(),
    );

    switch (widget.size) {
      case ButtonSize.small:
        return baseStyle.copyWith(fontSize: 12);
      case ButtonSize.medium:
        return baseStyle.copyWith(fontSize: 14);
      case ButtonSize.large:
        return baseStyle.copyWith(fontSize: 16);
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 18;
      case ButtonSize.large:
        return 20;
    }
  }
}

enum ButtonType { primary, secondary, text }

enum ButtonSize { small, medium, large }

class CustomFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const CustomFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? AppTheme.primaryColor,
      foregroundColor: foregroundColor ?? Colors.white,
      tooltip: tooltip,
      child: Icon(icon),
    );
  }
}
