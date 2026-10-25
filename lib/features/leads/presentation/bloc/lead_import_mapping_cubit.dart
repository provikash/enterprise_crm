import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/lead_source.dart';
import '../models/lead_import_column_mapping.dart';
import '../models/lead_import_parsed_file.dart';
import '../models/lead_import_structure_analysis.dart';
import 'lead_import_mapping_state.dart';

class LeadImportMappingCubit extends Cubit<LeadImportMappingState> {
  LeadImportMappingCubit({
    required LeadImportParsedFile parsedFile,
    required LeadImportStructureAnalysis analysis,
    LeadImportColumnMapping? initialMapping,
  }) : super(
         LeadImportMappingState(
           parsedFile: parsedFile,
           analysis: analysis,
           mapping:
               initialMapping ??
               LeadImportColumnMapping(
                 sheetIndex: analysis.sheetIndex,
                 headerRowIndex: analysis.headerRowIndex,
                 defaultSource: analysis.source == LeadSource.excel
                     ? LeadSource.excel
                     : LeadSource.csv,
               ),
         ),
       );

  /// Sets or clears the mapped column index for a [target] Lead field.
  ///
  /// - Passing `null` unmaps the field.
  /// - If [columnIndex] does not exist in discovered columns, the request is ignored.
  /// - If another Lead field was previously mapped to [columnIndex], its mapping
  ///   is automatically cleared so each source column feeds at most one field.
  void setMapping(LeadImportTargetField target, int? columnIndex) {
    if (columnIndex != null) {
      final isValidColumn = state.analysis.columns.any(
        (c) => c.index == columnIndex,
      );
      if (!isValidColumn) return;
    }

    var nameCol = state.mapping.nameColumnIndex;
    var businessCol = state.mapping.businessNameColumnIndex;
    var phoneCol = state.mapping.phoneColumnIndex;
    var emailCol = state.mapping.emailColumnIndex;
    var cityCol = state.mapping.cityColumnIndex;
    var stateCol = state.mapping.stateColumnIndex;
    var countryCol = state.mapping.countryColumnIndex;
    var sourceCol = state.mapping.sourceColumnIndex;
    var priorityCol = state.mapping.priorityColumnIndex;
    var requirementCol = state.mapping.requirementColumnIndex;
    var estimatedValueCol = state.mapping.estimatedValueColumnIndex;
    var notesCol = state.mapping.notesColumnIndex;

    // Conflict resolution: clear any other field pointing to this columnIndex
    if (columnIndex != null) {
      if (target != LeadImportTargetField.name && nameCol == columnIndex) {
        nameCol = null;
      }
      if (target != LeadImportTargetField.businessName &&
          businessCol == columnIndex) {
        businessCol = null;
      }
      if (target != LeadImportTargetField.phone && phoneCol == columnIndex) {
        phoneCol = null;
      }
      if (target != LeadImportTargetField.email && emailCol == columnIndex) {
        emailCol = null;
      }
      if (target != LeadImportTargetField.city && cityCol == columnIndex) {
        cityCol = null;
      }
      if (target != LeadImportTargetField.state && stateCol == columnIndex) {
        stateCol = null;
      }
      if (target != LeadImportTargetField.country &&
          countryCol == columnIndex) {
        countryCol = null;
      }
      if (target != LeadImportTargetField.source && sourceCol == columnIndex) {
        sourceCol = null;
      }
      if (target != LeadImportTargetField.priority &&
          priorityCol == columnIndex) {
        priorityCol = null;
      }
      if (target != LeadImportTargetField.requirement &&
          requirementCol == columnIndex) {
        requirementCol = null;
      }
      if (target != LeadImportTargetField.estimatedValue &&
          estimatedValueCol == columnIndex) {
        estimatedValueCol = null;
      }
      if (target != LeadImportTargetField.notes && notesCol == columnIndex) {
        notesCol = null;
      }
    }

    // Assign to target field
    switch (target) {
      case LeadImportTargetField.name:
        nameCol = columnIndex;
      case LeadImportTargetField.businessName:
        businessCol = columnIndex;
      case LeadImportTargetField.phone:
        phoneCol = columnIndex;
      case LeadImportTargetField.email:
        emailCol = columnIndex;
      case LeadImportTargetField.city:
        cityCol = columnIndex;
      case LeadImportTargetField.state:
        stateCol = columnIndex;
      case LeadImportTargetField.country:
        countryCol = columnIndex;
      case LeadImportTargetField.source:
        sourceCol = columnIndex;
      case LeadImportTargetField.priority:
        priorityCol = columnIndex;
      case LeadImportTargetField.requirement:
        requirementCol = columnIndex;
      case LeadImportTargetField.estimatedValue:
        estimatedValueCol = columnIndex;
      case LeadImportTargetField.notes:
        notesCol = columnIndex;
    }

    final newMapping = LeadImportColumnMapping(
      sheetIndex: state.analysis.sheetIndex,
      headerRowIndex: state.analysis.headerRowIndex,
      nameColumnIndex: nameCol,
      businessNameColumnIndex: businessCol,
      phoneColumnIndex: phoneCol,
      emailColumnIndex: emailCol,
      cityColumnIndex: cityCol,
      stateColumnIndex: stateCol,
      countryColumnIndex: countryCol,
      sourceColumnIndex: sourceCol,
      priorityColumnIndex: priorityCol,
      requirementColumnIndex: requirementCol,
      estimatedValueColumnIndex: estimatedValueCol,
      notesColumnIndex: notesCol,
      defaultSource: state.mapping.defaultSource,
    );

    emit(state.copyWith(mapping: newMapping));
  }

  void setDefaultSource(LeadSource? source) {
    emit(
      state.copyWith(
        mapping: state.mapping.copyWith(
          defaultSource: source,
          clearDefaultSource: source == null,
        ),
      ),
    );
  }

  void mapNameTo(int? columnIndex) =>
      setMapping(LeadImportTargetField.name, columnIndex);

  void mapBusinessNameTo(int? columnIndex) =>
      setMapping(LeadImportTargetField.businessName, columnIndex);

  void mapPhoneTo(int? columnIndex) =>
      setMapping(LeadImportTargetField.phone, columnIndex);

  void mapEmailTo(int? columnIndex) =>
      setMapping(LeadImportTargetField.email, columnIndex);

  void mapCityTo(int? columnIndex) =>
      setMapping(LeadImportTargetField.city, columnIndex);

  void mapStateTo(int? columnIndex) =>
      setMapping(LeadImportTargetField.state, columnIndex);

  void mapCountryTo(int? columnIndex) =>
      setMapping(LeadImportTargetField.country, columnIndex);

  void mapSourceTo(int? columnIndex) =>
      setMapping(LeadImportTargetField.source, columnIndex);

  void mapPriorityTo(int? columnIndex) =>
      setMapping(LeadImportTargetField.priority, columnIndex);

  void mapRequirementTo(int? columnIndex) =>
      setMapping(LeadImportTargetField.requirement, columnIndex);

  void mapEstimatedValueTo(int? columnIndex) =>
      setMapping(LeadImportTargetField.estimatedValue, columnIndex);

  void mapNotesTo(int? columnIndex) =>
      setMapping(LeadImportTargetField.notes, columnIndex);

  /// Automatically matches spreadsheet columns to Lead fields based on column headers.
  void autoDetect() {
    emit(state.copyWith(mapping: autoDetectMapping(state.analysis)));
  }

  /// Pure static helper for auto-detecting column mappings.
  static LeadImportColumnMapping autoDetectMapping(
    LeadImportStructureAnalysis analysis,
  ) {
    int? nameCol;
    int? businessCol;
    int? phoneCol;
    int? emailCol;
    int? cityCol;
    int? stateCol;
    int? countryCol;
    int? sourceCol;
    int? priorityCol;
    int? requirementCol;
    int? estimatedValueCol;
    int? notesCol;

    final used = <int>{};

    for (final col in analysis.columns) {
      final h = col.displayHeader.toLowerCase().trim();
      if (!used.contains(col.index)) {
        if (emailCol == null &&
            (h == 'email' ||
                h == 'e-mail' ||
                h == 'email id' ||
                h == 'email_id' ||
                h == 'mail' ||
                h.contains('email'))) {
          emailCol = col.index;
          used.add(col.index);
        } else if (phoneCol == null &&
            (h == 'phone' ||
                h == 'mobile' ||
                h == 'phone number' ||
                h == 'mobile number' ||
                h == 'contact number' ||
                h.contains('phone') ||
                h.contains('mobile'))) {
          phoneCol = col.index;
          used.add(col.index);
        } else if (businessCol == null &&
            (h == 'business' ||
                h == 'business name' ||
                h == 'company' ||
                h == 'company name' ||
                h == 'organization' ||
                h == 'firm' ||
                h.contains('company') ||
                h.contains('business'))) {
          businessCol = col.index;
          used.add(col.index);
        } else if (nameCol == null &&
            (h == 'name' ||
                h == 'full name' ||
                h == 'contact person' ||
                h == 'contact name' ||
                h == 'lead name' ||
                h == 'customer name' ||
                h.contains('name') ||
                h.contains('contact'))) {
          nameCol = col.index;
          used.add(col.index);
        } else if (cityCol == null &&
            (h == 'city' ||
                h == 'town' ||
                h == 'district' ||
                h.contains('city'))) {
          cityCol = col.index;
          used.add(col.index);
        } else if (stateCol == null &&
            (h == 'state' ||
                h == 'province' ||
                h == 'region' ||
                h.contains('state'))) {
          stateCol = col.index;
          used.add(col.index);
        } else if (countryCol == null &&
            (h == 'country' ||
                h == 'nation' ||
                h.contains('country'))) {
          countryCol = col.index;
          used.add(col.index);
        } else if (sourceCol == null &&
            (h == 'source' ||
                h == 'lead source' ||
                h == 'channel' ||
                h == 'platform' ||
                h.contains('source'))) {
          sourceCol = col.index;
          used.add(col.index);
        } else if (priorityCol == null &&
            (h == 'priority' ||
                h == 'lead priority' ||
                h.contains('priority'))) {
          priorityCol = col.index;
          used.add(col.index);
        } else if (requirementCol == null &&
            (h == 'requirement' ||
                h == 'requirements' ||
                h == 'description' ||
                h.contains('requirement'))) {
          requirementCol = col.index;
          used.add(col.index);
        } else if (estimatedValueCol == null &&
            (h == 'estimated value' ||
                h == 'value' ||
                h == 'deal value' ||
                h == 'budget' ||
                h == 'estimated_value' ||
                h.contains('value') ||
                h.contains('budget'))) {
          estimatedValueCol = col.index;
          used.add(col.index);
        } else if (notesCol == null &&
            (h == 'notes' ||
                h == 'note' ||
                h == 'remarks' ||
                h == 'comments' ||
                h.contains('note') ||
                h.contains('remark'))) {
          notesCol = col.index;
          used.add(col.index);
        }
      }
    }

    return LeadImportColumnMapping(
      sheetIndex: analysis.sheetIndex,
      headerRowIndex: analysis.headerRowIndex,
      nameColumnIndex: nameCol,
      businessNameColumnIndex: businessCol,
      phoneColumnIndex: phoneCol,
      emailColumnIndex: emailCol,
      cityColumnIndex: cityCol,
      stateColumnIndex: stateCol,
      countryColumnIndex: countryCol,
      sourceColumnIndex: sourceCol,
      priorityColumnIndex: priorityCol,
      requirementColumnIndex: requirementCol,
      estimatedValueColumnIndex: estimatedValueCol,
      notesColumnIndex: notesCol,
      defaultSource: analysis.source == LeadSource.excel
          ? LeadSource.excel
          : LeadSource.csv,
    );
  }
}
