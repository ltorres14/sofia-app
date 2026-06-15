import 'api_config.dart';

class AppEnvironmentConfig {
  static AppEnvironment get current => ApiConfig.environment;
  static String get baseUrl => ApiConfig.baseUrl;
}
