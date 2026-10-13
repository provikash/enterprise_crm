import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/purchase_filter_query.dart';
import '../../domain/entities/purchase_order_record.dart';
import '../../domain/entities/purchase_order_status.dart';
import '../../domain/entities/purchase_summary.dart';
import '../../domain/repositories/purchase_repository.dart';
import 'purchase_list_state.dart';

/// Business logic cubit managing purchase order filtering, pagination, and data loading.
class PurchaseListCubit extends Cubit<PurchaseListState> {
  final PurchaseRepository repository;

  PurchaseListCubit(this.repository) : super(const PurchaseListInitial());

  Future<void> loadOrders({PurchaseFilterQuery? newQuery}) async {
    final activeQuery = newQuery ?? state.query;
    emit(PurchaseListLoading(query: activeQuery, summary: state.summary));

    try {
      final results = await Future.wait([
        repository.getSummary(),
        repository.getPurchaseOrders(query: activeQuery),
        repository.getPurchaseOrdersCount(query: activeQuery),
      ]);

      emit(PurchaseListLoaded(
        query: activeQuery,
        summary: results[0] as PurchaseSummary,
        orders: results[1] as List<PurchaseOrderRecord>,
        totalCount: results[2] as int,
      ));
    } catch (e) {
      emit(PurchaseListFailure(
        query: activeQuery,
        summary: state.summary,
        message: e.toString(),
      ));
    }
  }

  void updateSearch(String text) {
    final trimmed = text.trim();
    final updated = state.query.copyWith(
      searchText: trimmed.isEmpty ? null : trimmed,
      clearSearchText: trimmed.isEmpty,
      page: 1,
    );
    loadOrders(newQuery: updated);
  }

  void updateStatusFilter(PurchaseOrderStatus? status) {
    final updated = state.query.copyWith(
      status: status,
      clearStatus: status == null,
      page: 1,
    );
    loadOrders(newQuery: updated);
  }

  void updatePage(int page) {
    if (page == state.query.page || page < 1) return;
    final updated = state.query.copyWith(page: page);
    loadOrders(newQuery: updated);
  }

  void clearFilters() {
    final updated = state.query.copyWith(
      clearSearchText: true,
      clearStatus: true,
      page: 1,
    );
    loadOrders(newQuery: updated);
  }

  void refresh() {
    loadOrders();
  }
}
