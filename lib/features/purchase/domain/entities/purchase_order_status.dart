import 'package:flutter/material.dart';

/// Comprehensive lifecycle statuses for a Purchase Order.
enum PurchaseOrderStatus {
  draft(
    'Draft',
    Color(0xFF6B7280),
    Icons.edit_note_outlined,
  ),
  pendingApproval(
    'Pending Approval',
    Color(0xFFF59E0B),
    Icons.hourglass_top_outlined,
  ),
  approved(
    'Approved',
    Color(0xFF3B82F6),
    Icons.verified_outlined,
  ),
  ordered(
    'Ordered',
    Color(0xFF8B5CF6),
    Icons.local_shipping_outlined,
  ),
  received(
    'Received',
    Color(0xFF10B981),
    Icons.inventory_2_outlined,
  ),
  cancelled(
    'Cancelled',
    Color(0xFFEF4444),
    Icons.cancel_outlined,
  );

  final String displayName;
  final Color color;
  final IconData icon;

  const PurchaseOrderStatus(this.displayName, this.color, this.icon);

  /// Terminal statuses cannot transition further.
  bool get isTerminal => this == received || this == cancelled;

  /// Whether this PO can still be edited or submitted for approval.
  bool get isDraft => this == draft;

  /// Whether this PO is waiting for manager/admin approval.
  bool get isPendingApproval => this == pendingApproval;

  /// Whether this PO is approved and ready to be placed with the vendor.
  bool get isApproved => this == approved;

  /// Whether goods can be received against this PO.
  bool get canReceiveGoods => this == ordered;
}
