import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/core/config/app_config.dart';
import 'package:ppv_app/core/network/auth_interceptor.dart';
import 'package:ppv_app/core/network/dio_client.dart';
import 'package:ppv_app/core/network/retry_interceptor.dart';
import 'package:ppv_app/core/storage/secure_storage_service.dart';

void main() {
  late DioClient dioClient;

  setUp(() {
    dioClient = DioClient(
      storageService: const SecureStorageService(),
    );
  });

  group('DioClient - Configuration', () {
    test('baseUrl est configurée depuis AppConfig', () {
      expect(dioClient.dio.options.baseUrl, AppConfig.baseUrl);
    });

    test('connectTimeout est 15 secondes', () {
      expect(
        dioClient.dio.options.connectTimeout,
        const Duration(milliseconds: AppConfig.connectTimeoutMs),
      );
    });

    test('receiveTimeout est 15 secondes', () {
      expect(
        dioClient.dio.options.receiveTimeout,
        const Duration(milliseconds: AppConfig.receiveTimeoutMs),
      );
    });

    test('sendTimeout est 30 secondes', () {
      expect(
        dioClient.dio.options.sendTimeout,
        const Duration(milliseconds: AppConfig.sendTimeoutMs),
      );
    });

    test('headers par défaut contiennent Accept et Content-Type JSON', () {
      final headers = dioClient.dio.options.headers;
      expect(headers['Accept'], 'application/json');
      expect(headers['Content-Type'], 'application/json');
    });
  });

  group('DioClient - Interceptors', () {
    test('contient AuthInterceptor', () {
      final hasAuth = dioClient.dio.interceptors
          .any((i) => i is AuthInterceptor);
      expect(hasAuth, isTrue);
    });

    test('contient RetryInterceptor', () {
      final hasRetry = dioClient.dio.interceptors
          .any((i) => i is RetryInterceptor);
      expect(hasRetry, isTrue);
    });

    test('AuthInterceptor est avant RetryInterceptor', () {
      final interceptors = dioClient.dio.interceptors;
      final authIndex =
          interceptors.indexWhere((i) => i is AuthInterceptor);
      final retryIndex =
          interceptors.indexWhere((i) => i is RetryInterceptor);
      expect(authIndex, lessThan(retryIndex));
    });
  });
}
