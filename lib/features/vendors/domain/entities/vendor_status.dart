/// Lifecycle status of a vendor / supplier in the Enterprise CRM.
enum VendorStatus {
  active('Active'),
  underReview('Under Review'),
  inactive('Inactive'),
  blacklisted('Blacklisted');

  final String displayName;
  const VendorStatus(this.displayName);

  /// Only active vendors can be selected for new Purchase Orders.
  bool get isEligibleForOrders => this == VendorStatus.active;
}
