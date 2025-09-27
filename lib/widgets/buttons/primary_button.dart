import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum ButtonVariant {
  primary,
  secondary,
  outline,
  text,
}

enum ButtonSize {
  small,
  medium,
  large,
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  const PrimaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Size configurations
    double height;
    EdgeInsets padding;
    double fontSize;

    switch (size) {
      case ButtonSize.small:
        height = 36;
        padding = const EdgeInsets.symmetric(
          horizontal: AppSizing.paddingLarge,
          vertical: AppSizing.paddingSmall,
        );
        fontSize = 14;
        break;
      case ButtonSize.medium:
        height = 44;
        padding = const EdgeInsets.symmetric(
          horizontal: AppSizing.paddingXLarge,
          vertical: AppSizing.paddingMedium,
        );
        fontSize = 16;
        break;
      case ButtonSize.large:
        height = 52;
        padding = const EdgeInsets.symmetric(
          horizontal: AppSizing.paddingXXLarge,
          vertical: AppSizing.paddingLarge,
        );
        fontSize = 18;
        break;
    }

    Widget buttonChild = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: AppSizing.iconSmall,
            height: AppSizing.iconSmall,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getTextColor(),
              ),
            ),
          )
        else if (icon != null) ...[
          Icon(
            icon,
            size: AppSizing.iconSmall,
            color: _getTextColor(),
          ),
          const SizedBox(width: AppSizing.paddingSmall),
        ],
        if (!isLoading)
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: _getTextColor(),
            ),
          ),
      ],
    );

    Widget button;

    switch (variant) {
      case ButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryTeal,
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: AppTheme.primaryTeal.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizing.radiusMedium),
            ),
            padding: padding,
            minimumSize: Size(fullWidth ? double.infinity : 0, height),
            disabledBackgroundColor: AppTheme.neutralGray300,
            disabledForegroundColor: AppTheme.neutralGray500,
          ),
          child: buttonChild,
        );
        break;

      case ButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondaryBlue,
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: AppTheme.secondaryBlue.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizing.radiusMedium),
            ),
            padding: padding,
            minimumSize: Size(fullWidth ? double.infinity : 0, height),
            disabledBackgroundColor: AppTheme.neutralGray300,
            disabledForegroundColor: AppTheme.neutralGray500,
          ),
          child: buttonChild,
        );
        break;

      case ButtonVariant.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryTeal,
            side: const BorderSide(color: AppTheme.primaryTeal, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizing.radiusMedium),
            ),
            padding: padding,
            minimumSize: Size(fullWidth ? double.infinity : 0, height),
            disabledForegroundColor: AppTheme.neutralGray500,
            disabledBackgroundColor: Colors.transparent,
          ),
          child: buttonChild,
        );
        break;

      case ButtonVariant.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primaryTeal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizing.radiusSmall),
            ),
            padding: padding,
            minimumSize: Size(fullWidth ? double.infinity : 0, height),
            disabledForegroundColor: AppTheme.neutralGray500,
          ),
          child: buttonChild,
        );
        break;
    }

    return button;
  }

  Color _getTextColor() {
    if (isLoading || onPressed == null) {
      return AppTheme.neutralGray500;
    }

    switch (variant) {
      case ButtonVariant.primary:
      case ButtonVariant.secondary:
        return Colors.white;
      case ButtonVariant.outline:
      case ButtonVariant.text:
        return AppTheme.primaryTeal;
    }
  }
}

// Floating Action Button with consistent styling
class AppFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final bool mini;

  const AppFloatingActionButton({
    Key? key,
    this.onPressed,
    required this.icon,
    this.tooltip,
    this.mini = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      mini: mini,
      backgroundColor: AppTheme.primaryTeal,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(mini ? 12 : 16),
      ),
      child: Icon(
        icon,
        size: mini ? AppSizing.iconMedium : AppSizing.iconLarge,
      ),
    );
  }
}

// Icon button with consistent styling
class AppIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final ButtonVariant variant;
  final double? size;

  const AppIconButton({
    Key? key,
    this.onPressed,
    required this.icon,
    this.tooltip,
    this.variant = ButtonVariant.text,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color iconColor;

    switch (variant) {
      case ButtonVariant.primary:
        backgroundColor = AppTheme.primaryTeal;
        iconColor = Colors.white;
        break;
      case ButtonVariant.secondary:
        backgroundColor = AppTheme.secondaryBlue;
        iconColor = Colors.white;
        break;
      case ButtonVariant.outline:
        backgroundColor = Colors.transparent;
        iconColor = AppTheme.primaryTeal;
        break;
      case ButtonVariant.text:
        backgroundColor = Colors.transparent;
        iconColor = AppTheme.neutralGray700;
        break;
    }

    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: iconColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizing.radiusSmall),
          side: variant == ButtonVariant.outline
              ? const BorderSide(color: AppTheme.primaryTeal, width: 1)
              : BorderSide.none,
        ),
        padding: const EdgeInsets.all(AppSizing.paddingSmall),
      ),
      icon: Icon(
        icon,
        size: size ?? AppSizing.iconLarge,
      ),
    );
  }
}