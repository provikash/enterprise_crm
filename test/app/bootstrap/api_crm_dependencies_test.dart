import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/app/bootstrap/api_crm_dependencies.dart';
import 'package:enterprise_crm/core/config/app_config.dart';
import 'package:enterprise_crm/core/security/auth_token_vault.dart';
import 'package:enterprise_crm/core/security/secure_storage_service.dart';

void main() {
  group('Production API Dependencies Composition Root Tests', () {
    test('createProductionApiDependencies initializes seamlessly in API mode without throwing', () {
      final vault = AuthTokenVault(storage: InMemorySecureStorageService());
      const config = AppConfig(
        dataSourceMode: DataSourceMode.api,
        apiBaseUri: null, // Tests fallback to default API URI
      );

      final dependencies = createProductionApiDependencies(
        config: config,
        authTokenVault: vault,
      );

      expect(dependencies.leadRepository, isNotNull);
      expect(dependencies.authRepository, isNotNull);
      expect(dependencies.userManagementRepository, isNotNull);
      expect(dependencies.userLeadLinkRepository, isNotNull);
      expect(dependencies.inventoryRepository, isNotNull);
      expect(dependencies.dispatchRepository, isNotNull);
      expect(dependencies.purchaseRepository, isNotNull);
      expect(dependencies.vendorRepository, isNotNull);
      expect(dependencies.approvalRepository, isNotNull);
      expect(dependencies.notificationRepository, isNotNull);
      expect(dependencies.approvalBridge, isNotNull);
      expect(dependencies.notificationDispatcher, isNotNull);
      expect(dependencies.authTokenVault, equals(vault));
    });

    test('AppConfig.fromEnvironment produces valid configuration', () {
      final config = AppConfig.fromEnvironment();
      expect(config.dataSourceMode, DataSourceMode.mock);
      expect(config.apiBaseUri, isNotNull);
      expect(config.apiBaseUri.toString(), 'https://api.crm.vinayenterprise.com');
    });
  });
}

