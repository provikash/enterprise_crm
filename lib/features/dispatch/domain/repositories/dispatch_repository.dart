import '../entities/dispatch_filter_query.dart';
import '../entities/dispatch_record.dart';
import '../entities/dispatch_status.dart';
import '../entities/dispatch_summary.dart';
import '../inputs/create_dispatch_input.dart';

abstract class DispatchRepository {
  Future<List<DispatchRecord>> getDispatches({DispatchFilterQuery? query});

  Future<int> getDispatchesCount({DispatchFilterQuery? query});

  Future<DispatchRecord?> getDispatchById(String id);

  Future<DispatchRecord> createDispatch(CreateDispatchInput input);

  Future<DispatchRecord> updateDispatchStatus(
    String id,
    DispatchStatus newStatus, {
    String? remarks,
  });

  Future<DispatchSummary> getSummary();
}
