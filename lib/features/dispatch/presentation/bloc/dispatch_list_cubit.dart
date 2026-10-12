import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/dispatch_filter_query.dart';
import '../../domain/entities/dispatch_status.dart';
import '../../domain/repositories/dispatch_repository.dart';
import 'dispatch_list_state.dart';

/// Business logic cubit managing dispatch filtering, pagination, and data loading.
class DispatchListCubit extends Cubit<DispatchListState> {
  final DispatchRepository repository;

  DispatchListCubit(this.repository) : super(const DispatchListInitial());

  Future<void> loadDispatches({DispatchFilterQuery? newQuery}) async {
    final activeQuery = newQuery ?? state.query;
    emit(DispatchListLoading(query: activeQuery, summary: state.summary));

    try {
      final results = await Future.wait([
        repository.getSummary(),
        repository.getDispatches(query: activeQuery),
        repository.getDispatchesCount(query: activeQuery),
      ]);

      emit(DispatchListLoaded(
        query: activeQuery,
        summary: results[0] as dynamic,
        dispatches: results[1] as dynamic,
        totalCount: results[2] as int,
      ));
    } catch (e) {
      emit(DispatchListFailure(
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
    loadDispatches(newQuery: updated);
  }

  void updateStatusFilter(DispatchStatus? status) {
    final updated = state.query.copyWith(
      status: status,
      clearStatus: status == null,
      page: 1,
    );
    loadDispatches(newQuery: updated);
  }

  void updatePage(int page) {
    if (page == state.query.page || page < 1) return;
    final updated = state.query.copyWith(page: page);
    loadDispatches(newQuery: updated);
  }

  void refresh() {
    loadDispatches();
  }
}
