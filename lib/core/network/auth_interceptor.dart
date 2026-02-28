import 'dart:async';

import 'package:dio/dio.dart';
import 'package:ppv_app/core/config/app_config.dart';
import 'package:ppv_app/core/storage/secure_storage_service.dart';

/// Interceptor d'authentification JWT — QueuedInterceptor.
///
/// Utilise [QueuedInterceptor] pour empêcher les race conditions :
/// quand plusieurs requêtes échouent en 401, elles sont mises en queue
/// et le refresh ne se fait qu'une seule fois.
///
/// [onSessionExpired] est appelé quand le refresh token échoue,
/// permettant au routeur de naviguer vers /login.
///
/// [dio] est le Dio parent — réutilisé pour le retry après refresh afin de
/// conserver les timeouts et le certificate pinning configurés dans DioClient.
/// M5 — Évite l'instance Dio() anonyme qui bypasse la config de sécurité.
class AuthInterceptor extends QueuedInterceptor {
  final Dio _dio;
  final SecureStorageService _storageService;
  final void Function()? _onSessionExpired;
  Completer<void>? _refreshCompleter;

  // Clé extra pour marquer les requêtes de retry et prévenir les boucles infinies.
  static const _kAuthRetry = 'authRetry';

  AuthInterceptor({
    required Dio dio,
    required SecureStorageService storageService,
    void Function()? onSessionExpired,
  })  : _dio = dio,
        _storageService = storageService,
        _onSessionExpired = onSessionExpired;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storageService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // M5 — Ne pas retenter si c'est déjà un retry (prévient la boucle infinie)
    final isRetry = err.requestOptions.extra[_kAuthRetry] == true;

    if (err.response?.statusCode == 401 && !isRetry) {
      try {
        await _doRefresh();
        // Refresh réussi → retry la requête originale avec le nouveau token
        final newToken = await _storageService.getAccessToken();
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        // Marquer comme retry pour éviter une boucle infinie si le serveur
        // retourne encore 401 (ex : token valide mais permissions insuffisantes)
        err.requestOptions.extra[_kAuthRetry] = true;
        // M5 — Réutiliser _dio (timeouts + cert pinning) au lieu de Dio()
        final response = await _dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } catch (_) {
        // Refresh échoué → clear tokens + notifier session expirée
        await _storageService.clearTokens();
        _onSessionExpired?.call();
      }
    }
    handler.next(err);
  }

  /// Effectue le refresh token. Mutex via Completer pour éviter
  /// les refreshs concurrents.
  Future<void> _doRefresh() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<void>();
    try {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken == null) {
        throw Exception('No refresh token');
      }

      // Instance Dio séparée pour éviter la boucle infinie (pas d'AuthInterceptor).
      // M5 — Configured avec les mêmes timeouts que DioClient (pas de timeouts infinis).
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(milliseconds: AppConfig.connectTimeoutMs),
        receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeoutMs),
        sendTimeout: const Duration(milliseconds: AppConfig.sendTimeoutMs),
      ));
      final response = await dio.post(
        '/auth/refresh',
        options: Options(
          headers: {'Authorization': 'Bearer $refreshToken'},
        ),
      );

      final data = response.data['data'] as Map<String, dynamic>?;
      if (data == null) throw Exception('Invalid refresh response');

      final newAccessToken = data['access_token'] as String?;
      final newRefreshToken = data['refresh_token'] as String?;
      if (newAccessToken == null || newRefreshToken == null) {
        throw Exception('Missing tokens in refresh response');
      }

      await _storageService.saveTokens(
        access: newAccessToken,
        refresh: newRefreshToken,
      );

      _refreshCompleter!.complete();
    } catch (e) {
      _refreshCompleter!.completeError(e);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }
}
