import 'lead_source.dart';
import 'lead_status.dart';

class Lead {
  final String id;
  final String? name;
  final String? businessName;
  final String? phone;
  final String? email;
  final String? city;
  final String? state;
  final LeadStatus? status;
  final LeadSource source;
  final String? assignedUserId;
  final String? assignedUserName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, String>? metadata;

  const Lead({
    required this.id,
    String? name,
    String? contactPersonName,
    this.businessName,
    this.phone,
    this.email,
    this.city,
    this.state,
    this.status,
    this.source = LeadSource.manual,
    this.assignedUserId,
    this.assignedUserName,
    this.createdAt,
    this.updatedAt,
    this.metadata,
  }) : name = contactPersonName ?? name;

  String? get contactPersonName => name;

  bool get isAssigned =>
      assignedUserId != null && assignedUserId!.trim().isNotEmpty;

  Lead copyWith({
    String? id,
    String? name,
    String? contactPersonName,
    String? businessName,
    String? phone,
    String? email,
    String? city,
    String? state,
    LeadStatus? status,
    LeadSource? source,
    String? assignedUserId,
    String? assignedUserName,
    bool clearAssignedUser = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, String>? metadata,
  }) {
    return Lead(
      id: id ?? this.id,
      name: contactPersonName ?? name ?? this.name,
      businessName: businessName ?? this.businessName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      city: city ?? this.city,
      state: state ?? this.state,
      status: status ?? this.status,
      source: source ?? this.source,
      assignedUserId: clearAssignedUser
          ? null
          : (assignedUserId ?? this.assignedUserId),
      assignedUserName: clearAssignedUser
          ? null
          : (assignedUserName ?? this.assignedUserName),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Lead &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          businessName == other.businessName &&
          phone == other.phone &&
          email == other.email &&
          city == other.city &&
          state == other.state &&
          status == other.status &&
          source == other.source &&
          assignedUserId == other.assignedUserId &&
          assignedUserName == other.assignedUserName &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    businessName,
    phone,
    email,
    city,
    state,
    status,
    source,
    assignedUserId,
    assignedUserName,
    createdAt,
    updatedAt,
  );

  @override
  String toString() =>
      'Lead(id: $id, name: $name, business: $businessName, phone: $phone, email: $email, city: $city, state: $state, status: $status, source: $source, assignedTo: $assignedUserName, metadata: $metadata)';
}
