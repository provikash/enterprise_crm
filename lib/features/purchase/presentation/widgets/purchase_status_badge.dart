import 'package:flutter/material.dart';
import '../../domain/entities/purchase_order_status.dart';

/// Visual badge displaying a color-coded [PurchaseOrderStatus].
class PurchaseStatusBadge extends StatelessWidget {
  final PurchaseOrderStatus status;

  const PurchaseStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (textColor, bgColor, borderColor) = _colorsForStatus(status);

    return Container(
      key: Key('purchase_status_badge_${status.name}'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.displayName,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (Color text, Color bg, Color border) _colorsForStatus(PurchaseOrderStatus status) {
    switch (status) {
      case PurchaseOrderStatus.draft:
        return (
          const Color(0xFF4B5563), // gray 600
          const Color(0xFFF3F4F6), // gray 100
          const Color(0xFFE5E7EB), // gray 200
        );
      case PurchaseOrderStatus.pendingApproval:
        return (
          const Color(0xFFB45309), // amber 700
          const Color(0xFFFEF3C7), // amber 100
          const Color(0xFFFDE68A), // amber 200
        );
      case PurchaseOrderStatus.approved:
        return (
          const Color(0xFF1D4ED8), // blue 700
          const Color(0xFFDBEAFE), // blue 100
          const Color(0xFFBFDBFE), // blue 200
        );
      case PurchaseOrderStatus.ordered:
        return (
          const Color(0xFF6D28D9), // purple 700
          const Color(0xFFEDE9FE), // purple 100
          const Color(0xFFDDD6FE), // purple 200
        );
      case PurchaseOrderStatus.received:
        return (
          const Color(0xFF15803D), // green 700
          const Color(0xFFDCFCE7), // green 100
          const Color(0xFFBBF7D0), // green 200
        );
      case PurchaseOrderStatus.cancelled:
        return (
          const Color(0xFFB91C1C), // red 700
          const Color(0xFFFEE2E2), // red 100
          const Color(0xFFFECACA), // red 200
        );
    }
  }
}
