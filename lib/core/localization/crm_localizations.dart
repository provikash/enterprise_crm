import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Industrial-grade Localization dictionary for Vinay Enterprise CRM.
/// Supports English ('en'), Spanish ('es'), Hindi ('hi'), and German ('de').
class CrmLocalizations {
  final Locale locale;

  CrmLocalizations(this.locale);

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('es'),
    Locale('hi'),
    Locale('de'),
  ];

  static CrmLocalizations of(BuildContext context) {
    return Localizations.of<CrmLocalizations>(context, CrmLocalizations) ??
        CrmLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<CrmLocalizations> delegate =
      _CrmLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'Vinay Enterprise CRM',
      'dashboard': 'Dashboard',
      'overview_and_summary': 'Overview & Summary',
      'quick_actions': 'Quick Actions',
      'leads': 'Leads',
      'total_leads': 'Total Leads',
      'assigned_leads': 'Assigned Leads',
      'unassigned_leads': 'Unassigned Leads',
      'manual_leads': 'Manual Leads',
      'excel_leads': 'Excel Leads',
      'csv_leads': 'CSV Leads',
      'add_lead': 'Add Lead',
      'create_lead': 'Create Lead',
      'import_leads': 'Import Leads',
      'distribute_leads': 'Distribute Leads',
      'export': 'Export',
      'export_data': 'Export Data',
      'calling': 'Calling & Telephony',
      'inventory': 'Inventory Management',
      'purchase': 'Procurement & Orders',
      'vendors': 'Vendor Directory',
      'dispatch': 'Dispatch & Logistics',
      'hr': 'HR & Directory',
      'attendance': 'Time & Attendance',
      'payroll': 'Payroll & Compensation',
      'approvals': 'Approvals Inbox',
      'notifications': 'Notification Center',
      'user_management': 'User Management',
      'login': 'Log In',
      'logout': 'Log Out',
      'search_placeholder': 'Search across CRM...',
      'save': 'Save',
      'cancel': 'Cancel',
      'submit': 'Submit',
      'filter': 'Filter',
      'refresh': 'Refresh',
      'approved': 'Approved',
      'pending': 'Pending',
      'rejected': 'Rejected',
      'verified': 'Verified',
      'status': 'Status',
      'a11y_notifications': 'Notifications inbox',
      'a11y_theme_toggle': 'Toggle light or dark theme',
      'a11y_language_picker': 'Select display language',
      'a11y_search_field': 'Search CRM database',
      'a11y_metric_card': 'Summary KPI Card',
    },
    'es': {
      'app_title': 'Vinay CRM Empresarial',
      'dashboard': 'Panel Principal',
      'overview_and_summary': 'Resumen General',
      'quick_actions': 'Acciones Rápidas',
      'leads': 'Prospectos',
      'total_leads': 'Total de Prospectos',
      'assigned_leads': 'Prospectos Asignados',
      'unassigned_leads': 'Prospectos Sin Asignar',
      'manual_leads': 'Prospectos Manuales',
      'excel_leads': 'Prospectos Excel',
      'csv_leads': 'Prospectos CSV',
      'add_lead': 'Agregar Prospecto',
      'create_lead': 'Crear Prospecto',
      'import_leads': 'Importar Prospectos',
      'distribute_leads': 'Distribuir Prospectos',
      'export': 'Exportar',
      'export_data': 'Exportar Datos',
      'calling': 'Llamadas y Telefonía',
      'inventory': 'Gestión de Inventario',
      'purchase': 'Compras y Adquisiciones',
      'vendors': 'Directorio de Proveedores',
      'dispatch': 'Despacho y Logística',
      'hr': 'Recursos Humanos',
      'attendance': 'Asistencia y Control Horario',
      'payroll': 'Nómina y Salarios',
      'approvals': 'Bandeja de Aprobaciones',
      'notifications': 'Centro de Notificaciones',
      'user_management': 'Gestión de Usuarios',
      'login': 'Iniciar Sesión',
      'logout': 'Cerrar Sesión',
      'search_placeholder': 'Buscar en el CRM...',
      'save': 'Guardar',
      'cancel': 'Cancelar',
      'submit': 'Enviar',
      'filter': 'Filtrar',
      'refresh': 'Actualizar',
      'approved': 'Aprobado',
      'pending': 'Pendiente',
      'rejected': 'Rechazado',
      'verified': 'Verificado',
      'status': 'Estado',
      'a11y_notifications': 'Bandeja de notificaciones',
      'a11y_theme_toggle': 'Cambiar tema claro u oscuro',
      'a11y_language_picker': 'Seleccionar idioma',
      'a11y_search_field': 'Buscar en base de datos CRM',
      'a11y_metric_card': 'Tarjeta métrica KPI',
    },
    'hi': {
      'app_title': 'विनय एंटरप्राइज सीआरएम',
      'dashboard': 'डैशबोर्ड',
      'overview_and_summary': 'अवलोकन और सारांश',
      'quick_actions': 'त्वरित कार्य',
      'leads': 'लीड्स',
      'total_leads': 'कुल लीड्स',
      'assigned_leads': 'आवंटित लीड्स',
      'unassigned_leads': 'अनावंटित लीड्स',
      'manual_leads': 'मैन्युअल लीड्स',
      'excel_leads': 'एक्सेल लीड्स',
      'csv_leads': 'सीएसवी लीड्स',
      'add_lead': 'लीड जोड़ें',
      'create_lead': 'लीड बनाएं',
      'import_leads': 'लीड्स आयात करें',
      'distribute_leads': 'लीड्स वितरित करें',
      'export': 'निर्यात',
      'export_data': 'डेटा निर्यात करें',
      'calling': 'कॉलिंग और टेलीफोनी',
      'inventory': 'इन्वेंटरी प्रबंधन',
      'purchase': 'खरीद और खरीद आदेश',
      'vendors': 'विक्रेता निर्देशिका',
      'dispatch': 'डिस्पैच और लॉजिस्टिक्स',
      'hr': 'मानव संसाधन और निर्देशिका',
      'attendance': 'उपस्थिति और समय',
      'payroll': 'पेरोल और मुआवजा',
      'approvals': 'स्वीकृति इनबॉक्स',
      'notifications': 'अधिसूचना केंद्र',
      'user_management': 'उपयोगकर्ता प्रबंधन',
      'login': 'लॉग इन करें',
      'logout': 'लॉग आउट करें',
      'search_placeholder': 'सीआरएम में खोजें...',
      'save': 'सहेजें',
      'cancel': 'रद्द करें',
      'submit': 'जमा करें',
      'filter': 'फ़िल्टर',
      'refresh': 'ताज़ा करें',
      'approved': 'स्वीकृत',
      'pending': 'लंबित',
      'rejected': 'अस्वीकृत',
      'verified': 'सत्यापित',
      'status': 'स्थिति',
      'a11y_notifications': 'अधिसूचना इनबॉक्स',
      'a11y_theme_toggle': 'थीम बदलें',
      'a11y_language_picker': 'भाषा चुनें',
      'a11y_search_field': 'सीआरएम डेटाबेस खोजें',
      'a11y_metric_card': 'केपीआई सारांश कार्ड',
    },
    'de': {
      'app_title': 'Vinay Unternehmens-CRM',
      'dashboard': 'Dashboard',
      'overview_and_summary': 'Übersicht & Zusammenfassung',
      'quick_actions': 'Schnellaktionen',
      'leads': 'Leads',
      'total_leads': 'Gesamtanzahl Leads',
      'assigned_leads': 'Zugewiesene Leads',
      'unassigned_leads': 'Nicht zugewiesene Leads',
      'manual_leads': 'Manuelle Leads',
      'excel_leads': 'Excel Leads',
      'csv_leads': 'CSV Leads',
      'add_lead': 'Lead hinzufügen',
      'create_lead': 'Lead erstellen',
      'import_leads': 'Leads importieren',
      'distribute_leads': 'Leads verteilen',
      'export': 'Exportieren',
      'export_data': 'Daten exportieren',
      'calling': 'Telefonie & Anrufe',
      'inventory': 'Bestandsverwaltung',
      'purchase': 'Beschaffung & Bestellungen',
      'vendors': 'Lieferantenverzeichnis',
      'dispatch': 'Versand & Logistik',
      'hr': 'Personalwesen (HR)',
      'attendance': 'Zeiterfassung',
      'payroll': 'Gehaltsabrechnung',
      'approvals': 'Genehmigungspostfach',
      'notifications': 'Benachrichtigungszentrum',
      'user_management': 'Benutzerverwaltung',
      'login': 'Anmelden',
      'logout': 'Abmelden',
      'search_placeholder': 'Im CRM suchen...',
      'save': 'Speichern',
      'cancel': 'Abbrechen',
      'submit': 'Absenden',
      'filter': 'Filtern',
      'refresh': 'Aktualisieren',
      'approved': 'Genehmigt',
      'pending': 'Ausstehend',
      'rejected': 'Abgelehnt',
      'verified': 'Verifiziert',
      'status': 'Status',
      'a11y_notifications': 'Benachrichtigungspostfach',
      'a11y_theme_toggle': 'Design wechseln',
      'a11y_language_picker': 'Sprache auswählen',
      'a11y_search_field': 'CRM-Datenbank durchsuchen',
      'a11y_metric_card': 'KPI-Kennzahlenkarte',
    },
  };

  String text(String key) {
    final lang = locale.languageCode;
    return _localizedValues[lang]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  // Getters for primary enterprise concepts
  String get appTitle => text('app_title');
  String get dashboard => text('dashboard');
  String get overviewAndSummary => text('overview_and_summary');
  String get quickActions => text('quick_actions');
  String get leads => text('leads');
  String get totalLeads => text('total_leads');
  String get assignedLeads => text('assigned_leads');
  String get unassignedLeads => text('unassigned_leads');
  String get manualLeads => text('manual_leads');
  String get excelLeads => text('excel_leads');
  String get csvLeads => text('csv_leads');
  String get addLead => text('add_lead');
  String get createLead => text('create_lead');
  String get importLeads => text('import_leads');
  String get distributeLeads => text('distribute_leads');
  String get export => text('export');
  String get exportData => text('export_data');
  String get calling => text('calling');
  String get inventory => text('inventory');
  String get purchase => text('purchase');
  String get vendors => text('vendors');
  String get dispatch => text('dispatch');
  String get hr => text('hr');
  String get attendance => text('attendance');
  String get payroll => text('payroll');
  String get approvals => text('approvals');
  String get notifications => text('notifications');
  String get userManagement => text('user_management');
  String get login => text('login');
  String get logout => text('logout');
  String get searchPlaceholder => text('search_placeholder');
  String get save => text('save');
  String get cancel => text('cancel');
  String get submit => text('submit');
  String get filter => text('filter');
  String get refresh => text('refresh');
  String get approved => text('approved');
  String get pending => text('pending');
  String get rejected => text('rejected');
  String get verified => text('verified');
  String get status => text('status');
}

class _CrmLocalizationsDelegate
    extends LocalizationsDelegate<CrmLocalizations> {
  const _CrmLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return CrmLocalizations.supportedLocales
        .any((l) => l.languageCode == locale.languageCode);
  }

  @override
  Future<CrmLocalizations> load(Locale locale) {
    return SynchronousFuture<CrmLocalizations>(CrmLocalizations(locale));
  }

  @override
  bool shouldReload(_CrmLocalizationsDelegate old) => false;
}

