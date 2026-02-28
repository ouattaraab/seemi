import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/core/network/api_exceptions.dart';

void main() {
  group('NetworkException', () {
    test('fromDioException — connectionTimeout → timeout', () {
      final dioErr = DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: '/test'),
      );
      final e = NetworkException.fromDioException(dioErr);
      expect(e.type, NetworkExceptionType.timeout);
      expect(e.message, contains('connexion'));
    });

    test('fromDioException — receiveTimeout → timeout', () {
      final dioErr = DioException(
        type: DioExceptionType.receiveTimeout,
        requestOptions: RequestOptions(path: '/test'),
      );
      final e = NetworkException.fromDioException(dioErr);
      expect(e.type, NetworkExceptionType.timeout);
    });

    test('fromDioException — sendTimeout → timeout', () {
      final dioErr = DioException(
        type: DioExceptionType.sendTimeout,
        requestOptions: RequestOptions(path: '/test'),
      );
      final e = NetworkException.fromDioException(dioErr);
      expect(e.type, NetworkExceptionType.timeout);
    });

    test('fromDioException — connectionError → noConnection', () {
      final dioErr = DioException(
        type: DioExceptionType.connectionError,
        requestOptions: RequestOptions(path: '/test'),
      );
      final e = NetworkException.fromDioException(dioErr);
      expect(e.type, NetworkExceptionType.noConnection);
      expect(e.message, contains('internet'));
    });

    test('fromDioException — cancel → cancelled', () {
      final dioErr = DioException(
        type: DioExceptionType.cancel,
        requestOptions: RequestOptions(path: '/test'),
      );
      final e = NetworkException.fromDioException(dioErr);
      expect(e.type, NetworkExceptionType.cancelled);
    });

    test('fromDioException — unknown → unknown', () {
      final dioErr = DioException(
        type: DioExceptionType.unknown,
        requestOptions: RequestOptions(path: '/test'),
      );
      final e = NetworkException.fromDioException(dioErr);
      expect(e.type, NetworkExceptionType.unknown);
    });

    test('toString contient type et message', () {
      const e = NetworkException(
        message: 'test msg',
        type: NetworkExceptionType.timeout,
      );
      expect(e.toString(), contains('timeout'));
      expect(e.toString(), contains('test msg'));
    });
  });

  group('ApiException', () {
    test('fromDioException — parse le format standard PPV', () {
      final dioErr = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          statusCode: 422,
          data: {
            'success': false,
            'message': 'Données invalides',
            'code': 'VALIDATION_ERROR',
            'errors': {'price': ['Le prix est obligatoire']},
          },
          requestOptions: RequestOptions(path: '/test'),
        ),
      );
      final e = ApiException.fromDioException(dioErr);
      expect(e.message, 'Données invalides');
      expect(e.statusCode, 422);
      expect(e.errorCode, 'VALIDATION_ERROR');
      expect(e.errors, isNotNull);
      expect(e.errors!['price'], contains('Le prix est obligatoire'));
    });

    test('fromDioException — réponse sans data map', () {
      final dioErr = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          statusCode: 500,
          data: 'Internal Server Error',
          requestOptions: RequestOptions(path: '/test'),
        ),
      );
      final e = ApiException.fromDioException(dioErr);
      expect(e.statusCode, 500);
      expect(e.message, contains('500'));
    });

    test('fromDioException — pas de réponse', () {
      final dioErr = DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: '/test'),
      );
      final e = ApiException.fromDioException(dioErr);
      expect(e.errorCode, 'NO_RESPONSE');
    });

    test('helpers de status code', () {
      const e401 = ApiException(message: 'x', statusCode: 401);
      expect(e401.isUnauthorized, isTrue);
      expect(e401.isForbidden, isFalse);

      const e403 = ApiException(message: 'x', statusCode: 403);
      expect(e403.isForbidden, isTrue);

      const e404 = ApiException(message: 'x', statusCode: 404);
      expect(e404.isNotFound, isTrue);

      const e422 = ApiException(message: 'x', statusCode: 422);
      expect(e422.isValidationError, isTrue);

      const e429 = ApiException(message: 'x', statusCode: 429);
      expect(e429.isRateLimited, isTrue);

      const e500 = ApiException(message: 'x', statusCode: 500);
      expect(e500.isServerError, isTrue);
    });

    test('toString contient statusCode et errorCode', () {
      const e = ApiException(
        message: 'test',
        statusCode: 422,
        errorCode: 'VALIDATION_ERROR',
      );
      expect(e.toString(), contains('422'));
      expect(e.toString(), contains('VALIDATION_ERROR'));
    });
  });
}
