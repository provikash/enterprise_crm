import 'package:enterprise_crm/features/hr/data/network/backend_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HR-10.2 — BackendConfig Validation Tests', () {
    test('creates valid development configuration with defaults', () {
      final config = BackendConfig.development();

      expect(config.baseUrl, 'http://10.0.2.2:8000');
      expect(config.apiPrefix, '/api/v1');
      expect(config.environment, BackendEnvironment.development);
      expect(config.mode, BackendMode.mock);
      expect(config.connectTimeout, const Duration(seconds: 15));
      expect(config.receiveTimeout, const Duration(seconds: 30));
    });

    test('creates valid staging configuration', () {
      final config = BackendConfig.staging(
        baseUrl: 'https://staging-api.crm.example.com',
      );

      expect(config.baseUrl, 'https://staging-api.crm.example.com');
      expect(config.environment, BackendEnvironment.staging);
      expect(config.mode, BackendMode.backend);
    });

    test('creates valid production configuration with HTTPS', () {
      final config = BackendConfig.production(
        baseUrl: 'https://api.crm.example.com',
      );

      expect(config.baseUrl, 'https://api.crm.example.com');
      expect(config.environment, BackendEnvironment.production);
      expect(config.mode, BackendMode.backend);
    });

    test('throws BackendConfigException on empty base URL', () {
      expect(
        () => BackendConfig(baseUrl: '   '),
        throwsA(isA<BackendConfigException>().having(
          (e) => e.message,
          'message',
          contains('cannot be empty'),
        )),
      );
    });

    test('throws BackendConfigException on malformed base URL without host', () {
      expect(
        () => BackendConfig(baseUrl: 'not-a-valid-url'),
        throwsA(isA<BackendConfigException>().having(
          (e) => e.message,
          'message',
          contains('Must include valid scheme and host'),
        )),
      );
    });

    test('throws BackendConfigException on unsupported scheme', () {
      expect(
        () => BackendConfig(baseUrl: 'ftp://files.example.com'),
        throwsA(isA<BackendConfigException>().having(
          (e) => e.message,
          'message',
          contains('Only http and https are permitted'),
        )),
      );
    });

    test('mandates HTTPS in production environment', () {
      expect(
        () => BackendConfig(
          baseUrl: 'http://insecure.example.com',
          environment: BackendEnvironment.production,
        ),
        throwsA(isA<BackendConfigException>().having(
          (e) => e.message,
          'message',
          contains('Production environment mandates HTTPS'),
        )),
      );
    });

    test('normalizes trailing slashes in baseUrl and apiPrefix', () {
      final config = BackendConfig(
        baseUrl: 'https://api.crm.example.com/',
        apiPrefix: 'api/v2/',
      );

      expect(config.baseUrl, 'https://api.crm.example.com');
      expect(config.apiPrefix, '/api/v2');
    });

    test('resolveUrl correctly resolves paths', () {
      final config = BackendConfig(
        baseUrl: 'https://api.crm.example.com',
        apiPrefix: '/api/v1',
      );

      final uri1 = config.resolveUrl('/hr/employees');
      expect(uri1.toString(), 'https://api.crm.example.com/api/v1/hr/employees');

      final uri2 = config.resolveUrl('attendance/records');
      expect(uri2.toString(), 'https://api.crm.example.com/api/v1/attendance/records');
    });

    test('throws BackendConfigException on non-positive timeouts', () {
      expect(
        () => BackendConfig(
          baseUrl: 'https://api.crm.example.com',
          connectTimeout: Duration.zero,
        ),
        throwsA(isA<BackendConfigException>()),
      );

      expect(
        () => BackendConfig(
          baseUrl: 'https://api.crm.example.com',
          receiveTimeout: const Duration(seconds: -1),
        ),
        throwsA(isA<BackendConfigException>()),
      );
    });
  });
}
