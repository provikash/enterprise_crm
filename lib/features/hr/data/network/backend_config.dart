/// Runtime environments supported by the CRM application.
enum BackendEnvironment {
  development,
  staging,
  production;

  bool get isProduction => this == BackendEnvironment.production;
  bool get isDevelopment => this == BackendEnvironment.development;
  bool get isStaging => this == BackendEnvironment.staging;
}

/// Operation mode controlling whether repositories use deterministic in-memory mocks
/// or communicate with the live backend API.
enum BackendMode {
  mock,
  backend;

  bool get isMock => this == BackendMode.mock;
  bool get isBackend => this == BackendMode.backend;
}

/// Thrown when backend runtime configuration validation fails.
class BackendConfigException implements Exception {
  final String message;
  const BackendConfigException(this.message);

  @override
  String toString() => 'BackendConfigException: $message';
}

/// Validated configuration specifying the backend host, API prefix, timeouts,
/// and operational mode for API communication.
class BackendConfig {
  final String baseUrl;
  final String apiPrefix;
  final BackendEnvironment environment;
  final BackendMode mode;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  const BackendConfig._({
    required this.baseUrl,
    required this.apiPrefix,
    required this.environment,
    required this.mode,
    required this.connectTimeout,
    required this.receiveTimeout,
  });

  /// Factory constructor that validates all configuration parameters defensively.
  ///
  /// Throws [BackendConfigException] if:
  /// - [baseUrl] is empty, malformed, or missing host.
  /// - [baseUrl] scheme is neither 'http' nor 'https'.
  /// - [baseUrl] scheme is insecure 'http' when [environment] is [BackendEnvironment.production].
  /// - [connectTimeout] or [receiveTimeout] are non-positive.
  factory BackendConfig({
    required String baseUrl,
    String apiPrefix = '/api/v1',
    BackendEnvironment environment = BackendEnvironment.development,
    BackendMode mode = BackendMode.mock,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 30),
  }) {
    final trimmedUrl = baseUrl.trim();
    if (trimmedUrl.isEmpty) {
      throw const BackendConfigException('Backend base URL cannot be empty.');
    }

    final uri = Uri.tryParse(trimmedUrl);
    if (uri == null || !uri.hasScheme || uri.host.trim().isEmpty) {
      throw BackendConfigException('Invalid backend base URL: "$trimmedUrl". Must include valid scheme and host.');
    }

    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      throw BackendConfigException('Unsupported URI scheme: "$scheme". Only http and https are permitted.');
    }

    if (environment.isProduction && scheme != 'https') {
      throw const BackendConfigException('Production environment mandates HTTPS for backend communication.');
    }

    if (connectTimeout.isNegative || connectTimeout.inMilliseconds == 0) {
      throw const BackendConfigException('Connect timeout must be positive.');
    }

    if (receiveTimeout.isNegative || receiveTimeout.inMilliseconds == 0) {
      throw const BackendConfigException('Receive timeout must be positive.');
    }

    // Normalize API prefix to have leading slash and no trailing slash
    var normalizedPrefix = apiPrefix.trim();
    if (normalizedPrefix.isNotEmpty) {
      if (!normalizedPrefix.startsWith('/')) {
        normalizedPrefix = '/$normalizedPrefix';
      }
      if (normalizedPrefix.endsWith('/')) {
        normalizedPrefix = normalizedPrefix.substring(0, normalizedPrefix.length - 1);
      }
    }

    // Normalize base URL without trailing slash
    final normalizedBaseUrl = trimmedUrl.endsWith('/')
        ? trimmedUrl.substring(0, trimmedUrl.length - 1)
        : trimmedUrl;

    return BackendConfig._(
      baseUrl: normalizedBaseUrl,
      apiPrefix: normalizedPrefix,
      environment: environment,
      mode: mode,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
    );
  }

  /// Default local development configuration.
  factory BackendConfig.development({
    String baseUrl = 'http://10.0.2.2:8000',
    BackendMode mode = BackendMode.mock,
  }) {
    return BackendConfig(
      baseUrl: baseUrl,
      environment: BackendEnvironment.development,
      mode: mode,
    );
  }

  /// Default staging configuration.
  factory BackendConfig.staging({
    required String baseUrl,
    BackendMode mode = BackendMode.backend,
  }) {
    return BackendConfig(
      baseUrl: baseUrl,
      environment: BackendEnvironment.staging,
      mode: mode,
    );
  }

  /// Default production configuration with mandatory HTTPS enforcement.
  factory BackendConfig.production({
    required String baseUrl,
    BackendMode mode = BackendMode.backend,
  }) {
    return BackendConfig(
      baseUrl: baseUrl,
      environment: BackendEnvironment.production,
      mode: mode,
    );
  }

  /// Resolves an API [path] into a fully qualified, normalized URI.
  ///
  /// Example:
  /// baseUrl: 'https://api.crm.example.com', apiPrefix: '/api/v1'
  /// resolveUrl('/hr/employees') -> 'https://api.crm.example.com/api/v1/hr/employees'
  Uri resolveUrl(String path) {
    var normalizedPath = path.trim();
    if (!normalizedPath.startsWith('/')) {
      normalizedPath = '/$normalizedPath';
    }

    final fullPath = '$apiPrefix$normalizedPath';
    return Uri.parse('$baseUrl$fullPath');
  }

  @override
  String toString() =>
      'BackendConfig(baseUrl: $baseUrl, prefix: $apiPrefix, env: ${environment.name}, mode: ${mode.name})';
}
