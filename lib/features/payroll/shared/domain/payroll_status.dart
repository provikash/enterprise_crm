enum PayrollStatus {
  draft('Draft'),
  calculated('Calculated'),
  underReview('Under Review'),
  approved('Approved'),
  locked('Locked'),
  paid('Paid'),
  closed('Closed'),
  pending('Pending'),
  rejected('Rejected'),
  verified('Verified'),
  failed('Failed'),
  held('Held');

  final String label;
  const PayrollStatus(this.label);
}
