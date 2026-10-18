class DispatchSummary {
  final int totalDispatches;
  final int pendingCount;
  final int inTransitCount;
  final int outForDeliveryCount;
  final int deliveredCount;
  final int todayDispatchesCount;

  const DispatchSummary({
    required this.totalDispatches,
    required this.pendingCount,
    required this.inTransitCount,
    this.outForDeliveryCount = 0,
    required this.deliveredCount,
    this.todayDispatchesCount = 0,
  });

  const DispatchSummary.empty()
      : totalDispatches = 0,
        pendingCount = 0,
        inTransitCount = 0,
        outForDeliveryCount = 0,
        deliveredCount = 0,
        todayDispatchesCount = 0;
}
