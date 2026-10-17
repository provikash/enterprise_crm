import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/vendor_record.dart';
import '../../domain/repositories/vendor_repository.dart';
import 'vendor_form_state.dart';

class VendorFormCubit extends Cubit<VendorFormState> {
  final VendorRepository _repository;

  VendorFormCubit(this._repository) : super(const VendorFormInitial());

  Future<void> submitVendor(VendorRecord vendor, {bool isEdit = false}) async {
    final name = vendor.companyName.trim();
    if (name.isEmpty) {
      emit(const VendorFormFailure('Company Name is required.'));
      return;
    }

    final phone = vendor.phone.trim();
    if (phone.isEmpty) {
      emit(const VendorFormFailure('Primary Phone number is required.'));
      return;
    }

    final email = vendor.email.trim();
    if (email.isNotEmpty && (!email.contains('@') || !email.contains('.'))) {
      emit(const VendorFormFailure('Enter a valid email address.'));
      return;
    }

    final gstin = vendor.gstin.trim().toUpperCase();
    if (gstin.isNotEmpty && gstin.length != 15) {
      emit(const VendorFormFailure('GSTIN must be exactly 15 characters.'));
      return;
    }

    final sanitizedVendor = vendor.copyWith(
      companyName: name,
      phone: phone,
      email: email,
      gstin: gstin,
    );

    emit(const VendorFormSubmitting());

    try {
      final result = isEdit
          ? await _repository.updateVendor(sanitizedVendor)
          : await _repository.createVendor(sanitizedVendor);
      emit(VendorFormSuccess(result));
    } catch (e) {
      emit(VendorFormFailure(e.toString()));
    }
  }
}
