enum AppEnvironment { dev, production }

class ApiConfig {
  static const String _devBaseUrl = 'http://localhost:5247/api';
  static const String _productionBaseUrl = 'https://sofiaapi.apicoredev.com';

  static const AppEnvironment environment = AppEnvironment.production;

  static String get baseUrl {
    switch (environment) {
      case AppEnvironment.dev:
        return _devBaseUrl;
      case AppEnvironment.production:
        return _productionBaseUrl;
    }
  }
}
