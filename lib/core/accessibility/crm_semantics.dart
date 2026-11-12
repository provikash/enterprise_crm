import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Enterprise Accessibility (WCAG 2.1 AA) utilities and semantic wrappers.
class CrmSemantics {
  const CrmSemantics._();

  /// Minimum touch target dimension according to Material & WCAG 2.1 standards.
  static const double minTouchTargetDimension = 48.0;

  /// Wraps an interactive widget with a WCAG compliant 48x48 touch target
  /// and explicit screen-reader button semantics.
  static Widget button({
    required Widget child,
    required String label,
    String? hint,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      hint: hint,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: minTouchTargetDimension,
          minHeight: minTouchTargetDimension,
        ),
        child: child,
      ),
    );
  }

  /// Wraps a dashboard metric card or summary widget with semantic announcements.
  static Widget metricCard({
    required Widget child,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return Semantics(
      container: true,
      excludeSemantics: true,
      button: onTap != null,
      label: '$label: $value',
      child: child,
    );
  }

  /// Announces a message directly to assistive technology (TalkBack / VoiceOver).
  static Future<void> announce(
    BuildContext context,
    String message, {
    TextDirection? textDirection,
  }) async {
    final direction = textDirection ?? Directionality.maybeOf(context) ?? TextDirection.ltr;
    final view = View.maybeOf(context);
    if (view != null) {
      await SemanticsService.sendAnnouncement(view, message, direction);
    }
  }
}
