import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/vendors/data/repositories/mock_vendor_repository.dart';
import 'package:enterprise_crm/features/vendors/domain/entities/vendor_status.dart';
import 'package:enterprise_crm/features/vendors/presentation/bloc/vendor_list_cubit.dart';
import 'package:enterprise_crm/features/vendors/presentation/bloc/vendor_list_state.dart';

void main() {
  group('VendorListCubit Tests', () {
    late MockVendorRepository repository;
    late VendorListCubit cubit;

    setUp(() {
      repository = MockVendorRepository();
      cubit = VendorListCubit(repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is VendorListInitial', () {
      expect(cubit.state, isA<VendorListInitial>());
    });

    test('loadVendors emits [Loading, Loaded] with vendors and summary', () async {
      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<VendorListLoading>(),
          isA<VendorListLoaded>(),
        ]),
      );

      await cubit.loadVendors();
      expect(cubit.state, isA<VendorListLoaded>());
      final loaded = cubit.state as VendorListLoaded;
      expect(loaded.vendors, isNotEmpty);
      expect(loaded.summary.totalVendors, greaterThan(0));
    });

    test('search updates query and filters vendors', () async {
      await cubit.loadVendors();
      cubit.search('Apex');
      await Future.delayed(Duration.zero);

      final state = cubit.state as VendorListLoaded;
      expect(state.query.search, 'Apex');
      expect(state.vendors.length, 1);
    });

    test('filterByStatus toggles status', () async {
      await cubit.loadVendors();

      cubit.filterByStatus(VendorStatus.blacklisted);
      await Future.delayed(Duration.zero);
      var state = cubit.state as VendorListLoaded;
      expect(state.query.status, VendorStatus.blacklisted);

      // Tapping same status toggles off
      cubit.filterByStatus(VendorStatus.blacklisted);
      await Future.delayed(Duration.zero);
      state = cubit.state as VendorListLoaded;
      expect(state.query.status, isNull);
    });

    test('filterByCategory filters records', () async {
      await cubit.loadVendors();
      cubit.filterByCategory('Electronics');
      await Future.delayed(Duration.zero);

      final state = cubit.state as VendorListLoaded;
      expect(state.query.category, 'Electronics');
      expect(state.vendors.every((v) => v.category == 'Electronics'), isTrue);
    });

    test('setSort changes sort field and toggles direction', () async {
      await cubit.loadVendors();

      cubit.setSort('rating');
      await Future.delayed(Duration.zero);
      var state = cubit.state as VendorListLoaded;
      expect(state.query.sortField, 'rating');
      expect(state.query.sortAscending, isTrue);

      // Same field toggles descending
      cubit.setSort('rating');
      await Future.delayed(Duration.zero);
      state = cubit.state as VendorListLoaded;
      expect(state.query.sortAscending, isFalse);
    });

    test('clearFilters resets query parameters', () async {
      await cubit.loadVendors();
      cubit.search('Apex');
      cubit.filterByStatus(VendorStatus.active);
      await Future.delayed(Duration.zero);

      cubit.clearFilters();
      await Future.delayed(Duration.zero);
      final state = cubit.state as VendorListLoaded;
      expect(state.query.isEmpty, isTrue);
    });

    test('deleteVendor deletes record and reloads list', () async {
      await cubit.loadVendors();
      final initialCount = (cubit.state as VendorListLoaded).vendors.length;
      final targetId = (cubit.state as VendorListLoaded).vendors.first.id;

      final success = await cubit.deleteVendor(targetId);
      expect(success, isTrue);

      final afterCount = (cubit.state as VendorListLoaded).vendors.length;
      expect(afterCount, initialCount - 1);
    });
  });
}
