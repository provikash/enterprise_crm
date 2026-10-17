import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/vendors/data/repositories/mock_vendor_repository.dart';
import 'package:enterprise_crm/features/vendors/domain/entities/vendor_record.dart';
import 'package:enterprise_crm/features/vendors/domain/entities/vendor_status.dart';
import 'package:enterprise_crm/features/vendors/presentation/bloc/vendor_form_cubit.dart';
import 'package:enterprise_crm/features/vendors/presentation/bloc/vendor_form_state.dart';

void main() {
  group('VendorFormCubit Tests', () {
    late MockVendorRepository repository;
    late VendorFormCubit cubit;

    setUp(() {
      repository = MockVendorRepository();
      cubit = VendorFormCubit(repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is VendorFormInitial', () {
      expect(cubit.state, isA<VendorFormInitial>());
    });

    test('fails validation when company name is blank', () async {
      final vendor = VendorRecord(
        id: '',
        vendorCode: '',
        companyName: '   ',
        phone: '+91 98000 00000',
        createdAt: DateTime.now(),
      );

      await cubit.submitVendor(vendor);

      expect(cubit.state, isA<VendorFormFailure>());
      expect((cubit.state as VendorFormFailure).error, contains('Company Name is required'));
    });

    test('fails validation when phone is blank', () async {
      final vendor = VendorRecord(
        id: '',
        vendorCode: '',
        companyName: 'Valid Name',
        phone: '',
        createdAt: DateTime.now(),
      );

      await cubit.submitVendor(vendor);

      expect(cubit.state, isA<VendorFormFailure>());
      expect((cubit.state as VendorFormFailure).error, contains('Primary Phone'));
    });

    test('fails validation when email is malformed', () async {
      final vendor = VendorRecord(
        id: '',
        vendorCode: '',
        companyName: 'Valid Name',
        phone: '+91 98000 00000',
        email: 'invalid-email',
        createdAt: DateTime.now(),
      );

      await cubit.submitVendor(vendor);

      expect(cubit.state, isA<VendorFormFailure>());
      expect((cubit.state as VendorFormFailure).error, contains('valid email'));
    });

    test('fails validation when GSTIN is provided but not 15 characters', () async {
      final vendor = VendorRecord(
        id: '',
        vendorCode: '',
        companyName: 'Valid Name',
        phone: '+91 98000 00000',
        gstin: '07AAAAA00',
        createdAt: DateTime.now(),
      );

      await cubit.submitVendor(vendor);

      expect(cubit.state, isA<VendorFormFailure>());
      expect((cubit.state as VendorFormFailure).error, contains('15 characters'));
    });

    test('submits valid vendor successfully and creates record', () async {
      final vendor = VendorRecord(
        id: '',
        vendorCode: 'VND-999',
        companyName: 'Titan Hardware Corp',
        phone: '+91 98999 11111',
        email: 'info@titan.com',
        gstin: '07AAAAA0000A1Z5',
        status: VendorStatus.active,
        createdAt: DateTime.now(),
      );

      await cubit.submitVendor(vendor);

      expect(cubit.state, isA<VendorFormSuccess>());
      final created = (cubit.state as VendorFormSuccess).vendor;
      expect(created.id, isNotEmpty);
      expect(created.companyName, 'Titan Hardware Corp');
      expect(created.gstin, '07AAAAA0000A1Z5');
    });

    test('updates existing vendor successfully in edit mode', () async {
      final existing = (await repository.getVendors()).first;
      final modified = existing.copyWith(companyName: 'Modified Name');

      await cubit.submitVendor(modified, isEdit: true);

      expect(cubit.state, isA<VendorFormSuccess>());
      final updated = (cubit.state as VendorFormSuccess).vendor;
      expect(updated.companyName, 'Modified Name');
    });
  });
}
