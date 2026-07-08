enum AppEnvironment { dev, production }

class ApiConfig {
  static const String _devBaseUrl = 'http://192.168.1.4:5247';
  static const String _productionBaseUrl = 'https://sofiaapi.apicoredev.com';

  static const AppEnvironment environment = AppEnvironment.dev;

  static String get baseUrl {
    switch (environment) {
      case AppEnvironment.dev:
        return _devBaseUrl;
      case AppEnvironment.production:
        return _productionBaseUrl;
    }
  }
}
