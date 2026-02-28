import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/features/auth/data/auth_remote_datasource.dart';
import 'package:ppv_app/features/auth/data/auth_repository.dart';
import 'package:ppv_app/core/storage/secure_storage_service.dart';

// Fake Dio qui capture les appels POST
class _CapturingDio extends Fake implements Dio {
  String? capturedPath;
  Object? capturedData;
  DioException? errorToThrow;

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    capturedPath = path;
    capturedData = data;
    if (errorToThrow != null) throw errorToThrow!;
    return Response<T>(requestOptions: RequestOptions(path: path));
  }
}

// Fake FirebaseAuth — évite l'initialisation Firebase
class _FakeFirebaseAuth extends Fake implements firebase.FirebaseAuth {}

// Fake SecureStorageService — non utilisé dans registerFcmToken
class _FakeSecureStorage extends Fake implements SecureStorageService {}

void main() {
  group('AuthRemoteDataSource.registerFcmToken', () {
    late _CapturingDio fakeDio;
    late AuthRemoteDataSource dataSource;

    setUp(() {
      fakeDio = _CapturingDio();
      dataSource = AuthRemoteDataSource(
        dio: fakeDio,
        firebaseAuth: _FakeFirebaseAuth(),
      );
    });

    test('envoie POST /profile/fcm-token avec le token correct', () async {
      await dataSource.registerFcmToken('fcm-token-abc123');

      expect(fakeDio.capturedPath, equals('/profile/fcm-token'));
      expect(
        (fakeDio.capturedData as Map<String, dynamic>)['token'],
        equals('fcm-token-abc123'),
      );
    });

    test('propage une Exception si DioException reçue', () async {
      fakeDio.errorToThrow = DioException(
        requestOptions: RequestOptions(path: '/profile/fcm-token'),
        response: Response(
          requestOptions: RequestOptions(path: '/profile/fcm-token'),
          statusCode: 422,
          data: {'message': 'Token invalide'},
        ),
        type: DioExceptionType.badResponse,
      );

      expect(
        () async => dataSource.registerFcmToken('bad-token'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('AuthRepository.registerFcmToken', () {
    test('délègue à dataSource.registerFcmToken', () async {
      final fakeDio = _CapturingDio();
      final dataSource = AuthRemoteDataSource(
        dio: fakeDio,
        firebaseAuth: _FakeFirebaseAuth(),
      );
      final repository = AuthRepository(
        dataSource: dataSource,
        storageService: _FakeSecureStorage(),
      );

      await repository.registerFcmToken('repo-token-xyz');

      expect(fakeDio.capturedPath, equals('/profile/fcm-token'));
      expect(
        (fakeDio.capturedData as Map<String, dynamic>)['token'],
        equals('repo-token-xyz'),
      );
    });
  });
}
