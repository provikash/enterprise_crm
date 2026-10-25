import '../../domain/entities/lead_source.dart';

/// The supported Lead fields that can be mapped from spreadsheet columns.
enum LeadImportTargetField {
  name,
  businessName,
  phone,
  email,
  city,
  state,
  country,
  source,
  priority,
  requirement,
  estimatedValue,
  notes,
}

/// Explicit mapping from discovered spreadsheet column indices to Lead fields.
class LeadImportColumnMapping {
  const LeadImportColumnMapping({
    required this.sheetIndex,
    required this.headerRowIndex,
    this.nameColumnIndex,
    this.businessNameColumnIndex,
    this.phoneColumnIndex,
    this.emailColumnIndex,
    this.cityColumnIndex,
    this.stateColumnIndex,
    this.countryColumnIndex,
    this.sourceColumnIndex,
    this.priorityColumnIndex,
    this.requirementColumnIndex,
    this.estimatedValueColumnIndex,
    this.notesColumnIndex,
    this.defaultSource,
  });

  final int sheetIndex;
  final int headerRowIndex;
  final int? nameColumnIndex;
  final int? businessNameColumnIndex;
  final int? phoneColumnIndex;
  final int? emailColumnIndex;
  final int? cityColumnIndex;
  final int? stateColumnIndex;
  final int? countryColumnIndex;
  final int? sourceColumnIndex;
  final int? priorityColumnIndex;
  final int? requirementColumnIndex;
  final int? estimatedValueColumnIndex;
  final int? notesColumnIndex;
  final LeadSource? defaultSource;

  /// True if at least one Lead field is mapped.
  bool get hasAnyMapping =>
      nameColumnIndex != null ||
      businessNameColumnIndex != null ||
      phoneColumnIndex != null ||
      emailColumnIndex != null ||
      cityColumnIndex != null ||
      stateColumnIndex != null ||
      countryColumnIndex != null ||
      sourceColumnIndex != null ||
      priorityColumnIndex != null ||
      requirementColumnIndex != null ||
      estimatedValueColumnIndex != null ||
      notesColumnIndex != null;

  /// Returns the set of all non-null column indices mapped to any Lead field.
  Set<int> get mappedColumnIndices => {
    ?nameColumnIndex,
    ?businessNameColumnIndex,
    ?phoneColumnIndex,
    ?emailColumnIndex,
    ?cityColumnIndex,
    ?stateColumnIndex,
    ?countryColumnIndex,
    ?sourceColumnIndex,
    ?priorityColumnIndex,
    ?requirementColumnIndex,
    ?estimatedValueColumnIndex,
    ?notesColumnIndex,
  };

  /// Retrieves the mapped column index for the specified [field].
  int? getColumnFor(LeadImportTargetField field) {
    return switch (field) {
      LeadImportTargetField.name => nameColumnIndex,
      LeadImportTargetField.businessName => businessNameColumnIndex,
      LeadImportTargetField.phone => phoneColumnIndex,
      LeadImportTargetField.email => emailColumnIndex,
      LeadImportTargetField.city => cityColumnIndex,
      LeadImportTargetField.state => stateColumnIndex,
      LeadImportTargetField.country => countryColumnIndex,
      LeadImportTargetField.source => sourceColumnIndex,
      LeadImportTargetField.priority => priorityColumnIndex,
      LeadImportTargetField.requirement => requirementColumnIndex,
      LeadImportTargetField.estimatedValue => estimatedValueColumnIndex,
      LeadImportTargetField.notes => notesColumnIndex,
    };
  }

  LeadImportColumnMapping copyWith({
    int? sheetIndex,
    int? headerRowIndex,
    int? nameColumnIndex,
    bool clearName = false,
    int? businessNameColumnIndex,
    bool clearBusinessName = false,
    int? phoneColumnIndex,
    bool clearPhone = false,
    int? emailColumnIndex,
    bool clearEmail = false,
    int? cityColumnIndex,
    bool clearCity = false,
    int? stateColumnIndex,
    bool clearState = false,
    int? countryColumnIndex,
    bool clearCountry = false,
    int? sourceColumnIndex,
    bool clearSource = false,
    int? priorityColumnIndex,
    bool clearPriority = false,
    int? requirementColumnIndex,
    bool clearRequirement = false,
    int? estimatedValueColumnIndex,
    bool clearEstimatedValue = false,
    int? notesColumnIndex,
    bool clearNotes = false,
    LeadSource? defaultSource,
    bool clearDefaultSource = false,
  }) {
    return LeadImportColumnMapping(
      sheetIndex: sheetIndex ?? this.sheetIndex,
      headerRowIndex: headerRowIndex ?? this.headerRowIndex,
      nameColumnIndex: clearName
          ? null
          : (nameColumnIndex ?? this.nameColumnIndex),
      businessNameColumnIndex: clearBusinessName
          ? null
          : (businessNameColumnIndex ?? this.businessNameColumnIndex),
      phoneColumnIndex: clearPhone
          ? null
          : (phoneColumnIndex ?? this.phoneColumnIndex),
      emailColumnIndex: clearEmail
          ? null
          : (emailColumnIndex ?? this.emailColumnIndex),
      cityColumnIndex: clearCity
          ? null
          : (cityColumnIndex ?? this.cityColumnIndex),
      stateColumnIndex: clearState
          ? null
          : (stateColumnIndex ?? this.stateColumnIndex),
      countryColumnIndex: clearCountry
          ? null
          : (countryColumnIndex ?? this.countryColumnIndex),
      sourceColumnIndex: clearSource
          ? null
          : (sourceColumnIndex ?? this.sourceColumnIndex),
      priorityColumnIndex: clearPriority
          ? null
          : (priorityColumnIndex ?? this.priorityColumnIndex),
      requirementColumnIndex: clearRequirement
          ? null
          : (requirementColumnIndex ?? this.requirementColumnIndex),
      estimatedValueColumnIndex: clearEstimatedValue
          ? null
          : (estimatedValueColumnIndex ?? this.estimatedValueColumnIndex),
      notesColumnIndex: clearNotes
          ? null
          : (notesColumnIndex ?? this.notesColumnIndex),
      defaultSource: clearDefaultSource
          ? null
          : (defaultSource ?? this.defaultSource),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeadImportColumnMapping &&
          runtimeType == other.runtimeType &&
          sheetIndex == other.sheetIndex &&
          headerRowIndex == other.headerRowIndex &&
          nameColumnIndex == other.nameColumnIndex &&
          businessNameColumnIndex == other.businessNameColumnIndex &&
          phoneColumnIndex == other.phoneColumnIndex &&
          emailColumnIndex == other.emailColumnIndex &&
          cityColumnIndex == other.cityColumnIndex &&
          stateColumnIndex == other.stateColumnIndex &&
          countryColumnIndex == other.countryColumnIndex &&
          sourceColumnIndex == other.sourceColumnIndex &&
          priorityColumnIndex == other.priorityColumnIndex &&
          requirementColumnIndex == other.requirementColumnIndex &&
          estimatedValueColumnIndex == other.estimatedValueColumnIndex &&
          notesColumnIndex == other.notesColumnIndex &&
          defaultSource == other.defaultSource;

  @override
  int get hashCode => Object.hash(
    sheetIndex,
    headerRowIndex,
    nameColumnIndex,
    businessNameColumnIndex,
    phoneColumnIndex,
    emailColumnIndex,
    cityColumnIndex,
    stateColumnIndex,
    countryColumnIndex,
    sourceColumnIndex,
    priorityColumnIndex,
    requirementColumnIndex,
    estimatedValueColumnIndex,
    notesColumnIndex,
    defaultSource,
  );

  @override
  String toString() =>
      'LeadImportColumnMapping(sheet: $sheetIndex, headerRow: $headerRowIndex, name: $nameColumnIndex, business: $businessNameColumnIndex, phone: $phoneColumnIndex, email: $emailColumnIndex, city: $cityColumnIndex, state: $stateColumnIndex, country: $countryColumnIndex, source: $sourceColumnIndex, priority: $priorityColumnIndex, requirement: $requirementColumnIndex, estimatedValue: $estimatedValueColumnIndex, notes: $notesColumnIndex, defaultSource: $defaultSource)';
}
