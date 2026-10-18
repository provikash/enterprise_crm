import 'dispatch_status.dart';

class DispatchFilterQuery {
  final String? searchText;
  final DispatchStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? transporter;
  final int page;
  final int pageSize;

  const DispatchFilterQuery({
    this.searchText,
    this.status,
    this.startDate,
    this.endDate,
    this.transporter,
    this.page = 1,
    this.pageSize = 10,
  });

  DispatchFilterQuery copyWith({
    String? searchText,
    bool clearSearchText = false,
    DispatchStatus? status,
    bool clearStatus = false,
    DateTime? startDate,
    DateTime? endDate,
    String? transporter,
    int? page,
    int? pageSize,
  }) {
    return DispatchFilterQuery(
      searchText: clearSearchText ? null : (searchText ?? this.searchText),
      status: clearStatus ? null : (status ?? this.status),
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      transporter: transporter ?? this.transporter,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}
