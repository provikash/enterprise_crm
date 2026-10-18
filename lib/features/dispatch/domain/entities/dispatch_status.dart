enum DispatchStatus {
  pending,
  packed,
  inTransit,
  outForDelivery,
  delivered,
  cancelled;

  String get displayName {
    switch (this) {
      case DispatchStatus.pending:
        return 'Pending';
      case DispatchStatus.packed:
        return 'Packed';
      case DispatchStatus.inTransit:
        return 'In Transit';
      case DispatchStatus.outForDelivery:
        return 'Out for Delivery';
      case DispatchStatus.delivered:
        return 'Delivered';
      case DispatchStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isTerminal =>
      this == DispatchStatus.delivered || this == DispatchStatus.cancelled;

  bool get isInProgress =>
      this == DispatchStatus.packed ||
      this == DispatchStatus.inTransit ||
      this == DispatchStatus.outForDelivery;
}
