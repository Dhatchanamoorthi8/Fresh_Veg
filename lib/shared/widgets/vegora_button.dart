import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum VegoraButtonVariant { primary, secondary, outline, text, destructive }

/// Reusable premium Vegora Button component.
///
/// Features calibrated touch-friendly height, accessible contrast, smooth states,
/// integrated loading spinners, and optional prefix/suffix icons.
class VegoraButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final VegoraButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final double height;
  final double? width;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const VegoraButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = VegoraButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.prefixIcon,
    this.suffixIcon,
    this.height = 50.0,
    this.width,
    this.borderRadius = 12.0,
    this.padding,
  });

  const VegoraButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.prefixIcon,
    this.suffixIcon,
    this.height = 50.0,
    this.width,
    this.borderRadius = 12.0,
    this.padding,
  }) : variant = VegoraButtonVariant.secondary;

  const VegoraButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.prefixIcon,
    this.suffixIcon,
    this.height = 50.0,
    this.width,
    this.borderRadius = 12.0,
    this.padding,
  }) : variant = VegoraButtonVariant.destructive;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide side = BorderSide.none;

    switch (variant) {
      case VegoraButtonVariant.primary:
        bg = AppColors.primary;
        fg = Colors.white;
        break;
      case VegoraButtonVariant.secondary:
        bg = AppColors.primaryLight;
        fg = AppColors.primary;
        side = const BorderSide(color: AppColors.primary, width: 1.2);
        break;
      case VegoraButtonVariant.outline:
        bg = Colors.white;
        fg = AppColors.primary;
        side = const BorderSide(color: AppColors.border, width: 1.2);
        break;
      case VegoraButtonVariant.text:
        bg = Colors.transparent;
        fg = AppColors.primary;
        break;
      case VegoraButtonVariant.destructive:
        bg = AppColors.error;
        fg = Colors.white;
        break;
    }

    final isInteractive = onPressed != null && !isLoading;

    final childWidget = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        : Row(
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (prefixIcon != null) ...[
                Icon(prefixIcon, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Text(label, style: AppTypography.button(color: fg)),
              if (suffixIcon != null) ...[
                const SizedBox(width: 8),
                Icon(suffixIcon, size: 18, color: fg),
              ],
            ],
          );

    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: height,
      child: Material(
        color: isInteractive ? bg : bg.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: side,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isInteractive ? onPressed : null,
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: childWidget),
          ),
        ),
      ),
    );
  }
}
