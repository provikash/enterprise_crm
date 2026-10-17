import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/vendor_filter_query.dart';
import '../../domain/entities/vendor_status.dart';
import '../../domain/repositories/vendor_repository.dart';
import 'vendor_list_state.dart';

class VendorListCubit extends Cubit<VendorListState> {
  final VendorRepository _repository;
  VendorFilterQuery _currentQuery = const VendorFilterQuery();

  VendorListCubit(this._repository) : super(const VendorListInitial());

  VendorFilterQuery get currentQuery => _currentQuery;

  Future<void> loadVendors({VendorFilterQuery? query}) async {
    emit(const VendorListLoading());
    if (query != null) {
      _currentQuery = query;
    }

    try {
      final vendors = await _repository.getVendors(query: _currentQuery);
      final summary = await _repository.getVendorSummary();
      emit(VendorListLoaded(
        vendors: vendors,
        summary: summary,
        query: _currentQuery,
      ));
    } catch (e) {
      emit(VendorListError('Failed to load vendors: ${e.toString()}'));
    }
  }

  void search(String queryText) {
    _currentQuery = _currentQuery.copyWith(search: queryText);
    loadVendors(query: _currentQuery);
  }

  void filterByStatus(VendorStatus? status) {
    if (_currentQuery.status == status) {
      _currentQuery = _currentQuery.copyWith(clearStatus: true);
    } else {
      _currentQuery = _currentQuery.copyWith(status: status);
    }
    loadVendors(query: _currentQuery);
  }

  void filterByCategory(String? category) {
    if (category == null || category == 'All') {
      _currentQuery = _currentQuery.copyWith(clearCategory: true);
    } else {
      _currentQuery = _currentQuery.copyWith(category: category);
    }
    loadVendors(query: _currentQuery);
  }

  void setSort(String sortField) {
    final sameField = _currentQuery.sortField == sortField;
    _currentQuery = _currentQuery.copyWith(
      sortField: sortField,
      sortAscending: sameField ? !_currentQuery.sortAscending : true,
    );
    loadVendors(query: _currentQuery);
  }

  void clearFilters() {
    _currentQuery = const VendorFilterQuery();
    loadVendors(query: _currentQuery);
  }

  Future<bool> deleteVendor(String id) async {
    try {
      final success = await _repository.deleteVendor(id);
      if (success) {
        await loadVendors(query: _currentQuery);
      }
      return success;
    } catch (e) {
      emit(VendorListError('Failed to delete vendor: ${e.toString()}'));
      return false;
    }
  }

  Future<void> refresh() async {
    await loadVendors(query: _currentQuery);
  }
}
