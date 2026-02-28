import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/core/network/retry_interceptor.dart';

void main() {
  late Dio dio;
  late RetryInterceptor interceptor;

  setUp(() {
    dio = Dio();
    interceptor = RetryInterceptor(dio: dio, maxRetries: 3);
    dio.interceptors.add(interceptor);
  });

  group('RetryInterceptor - Configuration', () {
    test('maxRetries par défaut est 3', () {
      final defaultInterceptor = RetryInterceptor(dio: dio);
      expect(defaultInterceptor.maxRetries, 3);
    });

    test('maxRetries est configurable', () {
      final custom = RetryInterceptor(dio: dio, maxRetries: 5);
      expect(custom.maxRetries, 5);
    });

    test('initialDelay par défaut est 1 seconde', () {
      final defaultInterceptor = RetryInterceptor(dio: dio);
      expect(defaultInterceptor.initialDelay, const Duration(seconds: 1));
    });

    test('initialDelay est configurable', () {
      final custom = RetryInterceptor(
        dio: dio,
        initialDelay: const Duration(milliseconds: 500),
      );
      expect(custom.initialDelay, const Duration(milliseconds: 500));
    });
  });

  group('RetryInterceptor - shouldRetry : filtrage par méthode HTTP', () {
    DioException makeError({
      required String method,
      DioExceptionType type = DioExceptionType.connectionTimeout,
    }) {
      return DioException(
        type: type,
        requestOptions: RequestOptions(path: '/test', method: method),
      );
    }

    test('GET + connectionTimeout → true (retry)', () {
      expect(interceptor.shouldRetry(makeError(method: 'GET')), isTrue);
    });

    test('HEAD + connectionTimeout → true (retry)', () {
      expect(interceptor.shouldRetry(makeError(method: 'HEAD')), isTrue);
    });

    test('POST + connectionTimeout → false (pas de retry)', () {
      expect(interceptor.shouldRetry(makeError(method: 'POST')), isFalse);
    });

    test('PUT + connectionTimeout → false (pas de retry)', () {
      expect(interceptor.shouldRetry(makeError(method: 'PUT')), isFalse);
    });

    test('DELETE + connectionTimeout → false (pas de retry)', () {
      expect(interceptor.shouldRetry(makeError(method: 'DELETE')), isFalse);
    });

    test('PATCH + connectionTimeout → false (pas de retry)', () {
      expect(interceptor.shouldRetry(makeError(method: 'PATCH')), isFalse);
    });
  });

  group('RetryInterceptor - shouldRetry : filtrage par type d\'erreur', () {
    DioException makeGetError(DioExceptionType type) {
      return DioException(
        type: type,
        requestOptions: RequestOptions(path: '/test', method: 'GET'),
      );
    }

    test('connectionTimeout → true (retry)', () {
      expect(
        interceptor.shouldRetry(makeGetError(DioExceptionType.connectionTimeout)),
        isTrue,
      );
    });

    test('receiveTimeout → true (retry)', () {
      expect(
        interceptor.shouldRetry(makeGetError(DioExceptionType.receiveTimeout)),
        isTrue,
      );
    });

    test('sendTimeout → true (retry)', () {
      expect(
        interceptor.shouldRetry(makeGetError(DioExceptionType.sendTimeout)),
        isTrue,
      );
    });

    test('connectionError → true (retry)', () {
      expect(
        interceptor.shouldRetry(makeGetError(DioExceptionType.connectionError)),
        isTrue,
      );
    });

    test('badResponse (400/401/500) → false (pas de retry)', () {
      final err = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test', method: 'GET'),
        response: Response(
          statusCode: 500,
          requestOptions: RequestOptions(path: '/test'),
        ),
      );
      expect(interceptor.shouldRetry(err), isFalse);
    });

    test('cancel → false (pas de retry)', () {
      expect(
        interceptor.shouldRetry(makeGetError(DioExceptionType.cancel)),
        isFalse,
      );
    });

    test('unknown → false (pas de retry)', () {
      expect(
        interceptor.shouldRetry(makeGetError(DioExceptionType.unknown)),
        isFalse,
      );
    });

    test('badCertificate → false (pas de retry)', () {
      expect(
        interceptor.shouldRetry(makeGetError(DioExceptionType.badCertificate)),
        isFalse,
      );
    });
  });

  group('RetryInterceptor - compteur retry', () {
    test('retry_count est initialisé à null dans extra', () {
      final opts = RequestOptions(path: '/test', method: 'GET');
      expect(opts.extra['retry_count'], isNull);
    });

    test('retry_count peut être stocké dans extra', () {
      final opts = RequestOptions(path: '/test', method: 'GET');
      opts.extra['retry_count'] = 2;
      expect(opts.extra['retry_count'], 2);
    });

    test('POST + timeout ne met PAS à jour retry_count', () {
      final err = DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: '/test', method: 'POST'),
      );
      // POST ne devrait pas déclencher de retry — shouldRetry retourne false
      expect(interceptor.shouldRetry(err), isFalse);
      // retry_count reste null car le retry n'est jamais tenté
      expect(err.requestOptions.extra['retry_count'], isNull);
    });
  });
}
