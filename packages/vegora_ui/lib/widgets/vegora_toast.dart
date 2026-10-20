import 'package:flutter/material.dart';
import 'package:vegora_core/vegora_core.dart';

/// Type of feedback toast to display
enum VegoraToastType {
  success,
  info,
  warning,
  error,
  address,
}

/// Vegora Premium Feedback & Toast System
///
/// Replaces harsh system SnackBars with a refined, floating brand notification
/// featuring clear visual hierarchy, iconography, accessible contrast, and smooth micro-interactions.
class VegoraToast {
  VegoraToast._();

  /// Displays a floating Vegora toast notification.
  ///
  /// Automatically clears any previously queued toasts for responsive, immediate feedback.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context, {
    required String message,
    String? title,
    VegoraToastType type = VegoraToastType.info,
    IconData? icon,
    Duration duration = const Duration(milliseconds: 3200),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    return messenger.showSnackBar(
      createSnackBar(
        context: context,
        message: message,
        title: title,
        type: type,
        icon: icon,
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
  }

  /// Convenience helper for successful operations (e.g. Added to cart, profile updated)
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSuccess(
    BuildContext context,
    String message, {
    String? title,
    IconData? icon,
    Duration duration = const Duration(milliseconds: 3000),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return show(
      context,
      message: message,
      title: title,
      type: VegoraToastType.success,
      icon: icon ?? Icons.check_circle_rounded,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Convenience helper for address selection & branch switching
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
  showAddressSelected(
    BuildContext context, {
    required String addressLabel,
    String? area,
    String? branchName,
  }) {
    final areaPart = (area != null && area.isNotEmpty) ? ' ($area)' : '';
    final branchPart =
        (branchName != null && branchName.isNotEmpty)
            ? ' • Hub: $branchName'
            : '';

    return show(
      context,
      title: 'Delivery Address Set',
      message: '$addressLabel$areaPart$branchPart',
      type: VegoraToastType.address,
      icon: Icons.location_on_rounded,
      duration: const Duration(milliseconds: 3500),
    );
  }

  /// Convenience helper for information messages
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showInfo(
    BuildContext context,
    String message, {
    String? title,
    IconData? icon,
    Duration duration = const Duration(milliseconds: 3200),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return show(
      context,
      message: message,
      title: title,
      type: VegoraToastType.info,
      icon: icon ?? Icons.info_outline_rounded,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Convenience helper for warnings (e.g. stock limits, cart branch changes)
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showWarning(
    BuildContext context,
    String message, {
    String? title,
    IconData? icon,
    Duration duration = const Duration(milliseconds: 3500),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return show(
      context,
      message: message,
      title: title,
      type: VegoraToastType.warning,
      icon: icon ?? Icons.warning_amber_rounded,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Convenience helper for error messages
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showError(
    BuildContext context,
    String message, {
    String? title,
    IconData? icon,
    Duration duration = const Duration(milliseconds: 4000),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return show(
      context,
      message: message,
      title: title,
      type: VegoraToastType.error,
      icon: icon ?? Icons.error_outline_rounded,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Creates a SnackBar with transparent outer background and floating behavior
  /// wrapping the VegoraToastWidget.
  static SnackBar createSnackBar({
    BuildContext? context,
    required String message,
    String? title,
    VegoraToastType type = VegoraToastType.info,
    IconData? icon,
    Duration duration = const Duration(milliseconds: 3200),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return SnackBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: EdgeInsets.zero,
      duration: duration,
      dismissDirection: DismissDirection.horizontal,
      content: VegoraToastWidget(
        message: message,
        title: title,
        type: type,
        icon: icon,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
  }
}

/// The visual presentation widget for the Vegora toast notification.
class VegoraToastWidget extends StatelessWidget {
  final String message;
  final String? title;
  final VegoraToastType type;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const VegoraToastWidget({
    super.key,
    required this.message,
    this.title,
    this.type = VegoraToastType.info,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = _getIconColor();
    final iconBgColor = _getIconBgColor();
    final borderColor = _getBorderColor();
    final displayIcon = icon ?? _getDefaultIcon();

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Status Icon Avatar Badge
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(displayIcon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),

            // Text column (Title + Message)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null && title!.isNotEmpty) ...[
                    Text(
                      title!,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: (title != null && title!.isNotEmpty) ? 12.5 : 13.5,
                      fontWeight:
                          (title != null && title!.isNotEmpty)
                              ? FontWeight.w500
                              : FontWeight.w600,
                      color:
                          (title != null && title!.isNotEmpty)
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                      letterSpacing: -0.2,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Optional Action Button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onAction!();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(width: 6),
              // Clean Dismiss Button
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.textMuted.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getIconColor() {
    switch (type) {
      case VegoraToastType.success:
      case VegoraToastType.address:
        return AppColors.primary;
      case VegoraToastType.info:
        return const Color(0xFF1D6EE5);
      case VegoraToastType.warning:
        return AppColors.warning;
      case VegoraToastType.error:
        return AppColors.error;
    }
  }

  Color _getIconBgColor() {
    switch (type) {
      case VegoraToastType.success:
      case VegoraToastType.address:
        return AppColors.primaryContainer;
      case VegoraToastType.info:
        return const Color(0xFFEBF3FE);
      case VegoraToastType.warning:
        return AppColors.warningContainer;
      case VegoraToastType.error:
        return AppColors.errorContainer;
    }
  }

  Color _getBorderColor() {
    switch (type) {
      case VegoraToastType.success:
      case VegoraToastType.address:
        return AppColors.primary.withValues(alpha: 0.25);
      case VegoraToastType.info:
        return const Color(0xFF1D6EE5).withValues(alpha: 0.25);
      case VegoraToastType.warning:
        return AppColors.warning.withValues(alpha: 0.3);
      case VegoraToastType.error:
        return AppColors.error.withValues(alpha: 0.3);
    }
  }

  IconData _getDefaultIcon() {
    switch (type) {
      case VegoraToastType.success:
        return Icons.check_circle_rounded;
      case VegoraToastType.address:
        return Icons.location_on_rounded;
      case VegoraToastType.info:
        return Icons.info_outline_rounded;
      case VegoraToastType.warning:
        return Icons.warning_amber_rounded;
      case VegoraToastType.error:
        return Icons.error_outline_rounded;
    }
  }
}
