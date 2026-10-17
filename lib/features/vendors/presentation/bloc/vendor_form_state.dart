import 'package:flutter/foundation.dart';
import '../../domain/entities/vendor_record.dart';

@immutable
sealed class VendorFormState {
  const VendorFormState();
}

class VendorFormInitial extends VendorFormState {
  const VendorFormInitial();
}

class VendorFormSubmitting extends VendorFormState {
  const VendorFormSubmitting();
}

class VendorFormSuccess extends VendorFormState {
  final VendorRecord vendor;
  const VendorFormSuccess(this.vendor);
}

class VendorFormFailure extends VendorFormState {
  final String error;
  const VendorFormFailure(this.error);
}
