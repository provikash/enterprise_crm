class DispatchSummary {
  final int totalDispatches;
  final int pendingCount;
  final int inTransitCount;
  final int deliveredCount;
  final int todayDispatchesCount;

  const DispatchSummary({
    required this.totalDispatches,
    required this.pendingCount,
    required this.inTransitCount,
    required this.deliveredCount,
    required this.todayDispatchesCount,
  });

  const DispatchSummary.empty()
      : totalDispatches = 0,
        pendingCount = 0,
        inTransitCount = 0,
        deliveredCount = 0,
        todayDispatchesCount = 0;
}
