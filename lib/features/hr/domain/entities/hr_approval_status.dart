/// Represents the lifecycle status of an HR approval request.
///
/// Invariants:
/// - Initial state for a submitted request is [pending].
/// - [approved], [rejected], and [cancelled] are terminal states.
/// - Once in a terminal state, no further transitions are permitted.
enum HrApprovalStatus {
  /// Request is submitted and awaiting decision by an authorized actor.
  pending('pending', 'Pending'),

  /// Request was formally approved by an authorized decision-maker.
  approved('approved', 'Approved'),

  /// Request was explicitly rejected by an authorized decision-maker.
  rejected('rejected', 'Rejected'),

  /// Request was cancelled or withdrawn by the original requester before decision.
  cancelled('cancelled', 'Cancelled');

  final String value;
  final String label;

  const HrApprovalStatus(this.value, this.label);

  /// Whether this status is a terminal state that cannot transition further.
  bool get isTerminal =>
      this == HrApprovalStatus.approved ||
      this == HrApprovalStatus.rejected ||
      this == HrApprovalStatus.cancelled;

  /// Whether this status represents an active pending state.
  bool get isPending => this == HrApprovalStatus.pending;

  /// Whether this status represents an approval.
  bool get isApproved => this == HrApprovalStatus.approved;

  /// Whether this status represents a rejection.
  bool get isRejected => this == HrApprovalStatus.rejected;

  /// Whether this status represents a cancellation.
  bool get isCancelled => this == HrApprovalStatus.cancelled;

  /// Checks if transition from `this` to [next] is structurally permissible.
  bool canTransitionTo(HrApprovalStatus next) {
    if (isTerminal) return false;
    if (this == HrApprovalStatus.pending) {
      return next == HrApprovalStatus.approved ||
          next == HrApprovalStatus.rejected ||
          next == HrApprovalStatus.cancelled;
    }
    return false;
  }

  /// Parses a status from its string value, or returns `null` if unrecognized.
  static HrApprovalStatus? fromValue(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase();
    for (final status in HrApprovalStatus.values) {
      if (status.value == normalized) return status;
    }
    return null;
  }
}
