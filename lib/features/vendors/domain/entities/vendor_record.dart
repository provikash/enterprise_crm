import 'package:flutter/foundation.dart';
import 'vendor_status.dart';

/// Pure domain entity representing a Vendor / Supplier record in Enterprise CRM.
@immutable
class VendorRecord {
  final String id;
  final String vendorCode;
  final String companyName;
  final String contactPerson;
  final String email;
  final String phone;
  final String alternatePhone;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String gstin;
  final String pan;
  final String category;
  final String paymentTerms;
  final double creditLimitInr;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String branchName;
  final VendorStatus status;
  final double rating;
  final String notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const VendorRecord({
    required this.id,
    required this.vendorCode,
    required this.companyName,
    this.contactPerson = '',
    this.email = '',
    this.phone = '',
    this.alternatePhone = '',
    this.address = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.gstin = '',
    this.pan = '',
    this.category = 'General',
    this.paymentTerms = 'Net 30',
    this.creditLimitInr = 0.0,
    this.bankName = '',
    this.accountNumber = '',
    this.ifscCode = '',
    this.branchName = '',
    this.status = VendorStatus.active,
    this.rating = 4.0,
    this.notes = '',
    required this.createdAt,
    this.updatedAt,
  });

  VendorRecord copyWith({
    String? id,
    String? vendorCode,
    String? companyName,
    String? contactPerson,
    String? email,
    String? phone,
    String? alternatePhone,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? gstin,
    String? pan,
    String? category,
    String? paymentTerms,
    double? creditLimitInr,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? branchName,
    VendorStatus? status,
    double? rating,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VendorRecord(
      id: id ?? this.id,
      vendorCode: vendorCode ?? this.vendorCode,
      companyName: companyName ?? this.companyName,
      contactPerson: contactPerson ?? this.contactPerson,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      gstin: gstin ?? this.gstin,
      pan: pan ?? this.pan,
      category: category ?? this.category,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      creditLimitInr: creditLimitInr ?? this.creditLimitInr,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      branchName: branchName ?? this.branchName,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorRecord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          vendorCode == other.vendorCode &&
          companyName == other.companyName &&
          status == other.status;

  @override
  int get hashCode => id.hashCode ^ vendorCode.hashCode ^ companyName.hashCode ^ status.hashCode;
}
