import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/core/config/app_config.dart';

void main() {
  group('AppConfig - Valeurs par défaut', () {
    test('baseUrl par défaut est localhost Android emulator', () {
      expect(AppConfig.baseUrl, 'http://10.0.2.2:8000/api/v1');
    });

    test('environment par défaut est dev', () {
      expect(AppConfig.environment, 'dev');
    });

    test('isDev retourne true par défaut', () {
      expect(AppConfig.isDev, isTrue);
    });

    test('isProd retourne false par défaut', () {
      expect(AppConfig.isProd, isFalse);
    });
  });

  group('AppConfig - Timeouts', () {
    test('connectTimeoutMs est 15000', () {
      expect(AppConfig.connectTimeoutMs, 15000);
    });

    test('receiveTimeoutMs est 15000', () {
      expect(AppConfig.receiveTimeoutMs, 15000);
    });

    test('sendTimeoutMs est 30000', () {
      expect(AppConfig.sendTimeoutMs, 30000);
    });
  });
}
