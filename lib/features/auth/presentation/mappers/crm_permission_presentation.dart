import '../../domain/policies/crm_permissions.dart';

/// Presentation mapper providing human-readable labels for CRM permissions.
abstract final class CrmPermissionPresentation {
  static const Map<String, String> _displayNames = {
    CrmPermissions.leadViewAssigned: 'View assigned leads',
    CrmPermissions.leadUpdate: 'Update leads',
    CrmPermissions.callingUse: 'Use calling',
    CrmPermissions.hrView: 'View HR',
    CrmPermissions.attendanceManage: 'Add and edit attendance',
    CrmPermissions.shiftManage: 'Manage shifts and rosters',
    CrmPermissions.attendancePolicyManage: 'Manage attendance policies',
    CrmPermissions.timesheetApprove: 'Approve timesheets',
    CrmPermissions.leaveManage: 'Manage leave and holidays',
    CrmPermissions.payrollView: 'View payroll',
    CrmPermissions.payrollConfigManage: 'Manage payroll configuration',
    CrmPermissions.payrollSalaryView: 'View employee salary',
    CrmPermissions.payrollSalaryEdit: 'Edit employee salary',
    CrmPermissions.payrollRunView: 'View pay runs',
    CrmPermissions.payrollRunCreate: 'Create pay runs',
    CrmPermissions.payrollRunApprove: 'Approve pay runs',
    CrmPermissions.payrollRunLock: 'Lock and reopen pay runs',
    CrmPermissions.payrollPaymentRelease: 'Release payroll payments',
    CrmPermissions.payrollPayslipViewAll: 'View all employee payslips',
    CrmPermissions.payrollTaxVerify: 'Verify employee tax proofs',
    CrmPermissions.payrollComplianceView: 'View payroll compliance',
    CrmPermissions.payrollReportsView: 'View payroll reports',
    CrmPermissions.inventoryView: 'View inventory',
    CrmPermissions.inventoryCreate: 'Create inventory items',
    CrmPermissions.inventoryEdit: 'Edit inventory items',
    CrmPermissions.inventoryDelete: 'Delete inventory items',
    CrmPermissions.inventoryStockManage: 'Manage Stock Quantity',
    CrmPermissions.inventoryImportCsv: 'Import inventory (CSV)',
    CrmPermissions.inventoryImportXlsx: 'Import inventory (Excel)',
    CrmPermissions.inventoryExportCsv: 'Export inventory (CSV)',
    CrmPermissions.inventoryExportXlsx: 'Export inventory (Excel)',
    CrmPermissions.purchaseView: 'View purchases',
    CrmPermissions.vendorView: 'View vendors',
  };

  /// Returns the human-readable display label for [permissionId].
  ///
  /// Falls back to [permissionId] if no display mapping is configured.
  static String displayNameFor(String permissionId) =>
      _displayNames[permissionId] ?? permissionId;
}
