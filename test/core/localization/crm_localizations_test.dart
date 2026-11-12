import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/core/localization/crm_localizations.dart';
import 'package:enterprise_crm/core/localization/locale_controller.dart';
import 'package:enterprise_crm/core/security/secure_storage_service.dart';

void main() {
  group('CrmLocalizations Tests', () {
    test('supports en, es, hi, and de', () {
      final supportedCodes =
          CrmLocalizations.supportedLocales.map((l) => l.languageCode).toSet();
      expect(supportedCodes, containsAll(['en', 'es', 'hi', 'de']));
    });

    test('English translations provide accurate enterprise labels', () {
      final loc = CrmLocalizations(const Locale('en'));
      expect(loc.appTitle, 'Vinay Enterprise CRM');
      expect(loc.totalLeads, 'Total Leads');
      expect(loc.overviewAndSummary, 'Overview & Summary');
      expect(loc.quickActions, 'Quick Actions');
      expect(loc.exportData, 'Export Data');
      expect(loc.inventory, 'Inventory Management');
      expect(loc.payroll, 'Payroll & Compensation');
      expect(loc.approvals, 'Approvals Inbox');
      expect(loc.notifications, 'Notification Center');
    });

    test('Spanish translations provide accurate enterprise labels', () {
      final loc = CrmLocalizations(const Locale('es'));
      expect(loc.appTitle, 'Vinay CRM Empresarial');
      expect(loc.totalLeads, 'Total de Prospectos');
      expect(loc.leads, 'Prospectos');
      expect(loc.login, 'Iniciar Sesión');
      expect(loc.logout, 'Cerrar Sesión');
      expect(loc.inventory, 'Gestión de Inventario');
    });

    test('Hindi translations provide accurate enterprise labels', () {
      final loc = CrmLocalizations(const Locale('hi'));
      expect(loc.appTitle, 'विनय एंटरप्राइज सीआरएम');
      expect(loc.totalLeads, 'कुल लीड्स');
      expect(loc.leads, 'लीड्स');
      expect(loc.addLead, 'लीड जोड़ें');
      expect(loc.save, 'सहेजें');
    });

    test('German translations provide accurate enterprise labels', () {
      final loc = CrmLocalizations(const Locale('de'));
      expect(loc.appTitle, 'Vinay Unternehmens-CRM');
      expect(loc.totalLeads, 'Gesamtanzahl Leads');
      expect(loc.leads, 'Leads');
      expect(loc.save, 'Speichern');
      expect(loc.cancel, 'Abbrechen');
    });

    test('falls back gracefully to English when a language is unmapped', () {
      final loc = CrmLocalizations(const Locale('fr'));
      expect(loc.totalLeads, 'Total Leads');
    });

    testWidgets('resolves CrmLocalizations via context', (tester) async {
      late CrmLocalizations resolved;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: const [
            CrmLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: CrmLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              resolved = CrmLocalizations.of(context);
              return Text(resolved.leads);
            },
          ),
        ),
      );

      expect(resolved.leads, 'Prospectos');
      expect(find.text('Prospectos'), findsOneWidget);
    });
  });

  group('LocaleController Tests', () {
    test('updates locale and notifies listeners', () async {
      final controller = LocaleController.instance;
      expect(controller.value, const Locale('en'));

      Locale? notified;
      void listener() {
        notified = controller.value;
      }

      controller.addListener(listener);
      await controller.setLanguageCode('es');
      expect(controller.value, const Locale('es'));
      expect(notified, const Locale('es'));

      await controller.setLanguageCode('en');
      expect(controller.value, const Locale('en'));
      controller.removeListener(listener);
    });

    test('persists locale into SecureStorageService', () async {
      final storage = InMemorySecureStorageService();
      final controller = LocaleController.instance;
      await controller.initialize(storage: storage);

      await controller.setLanguageCode('de');
      expect(await storage.read(key: 'crm_user_locale_pref'), 'de');

      // Re-initialize with saved pref
      await controller.initialize(storage: storage);
      expect(controller.value, const Locale('de'));

      // Restore to English
      await controller.setLanguageCode('en');
    });
  });
}
