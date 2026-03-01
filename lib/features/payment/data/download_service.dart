import 'dart:io';

import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

/// Interface d'accès à la galerie de l'appareil.
/// Permet l'injection de fakes lors des tests unitaires.
abstract class GalGateway {
  Future<void> putImage(String path, {String? album});
  Future<void> putVideo(String path, {String? album});
  Future<bool> hasAccess();
  Future<bool> requestAccess();
}

/// Implémentation par défaut utilisant le package [Gal].
class DefaultGalGateway implements GalGateway {
  const DefaultGalGateway();

  @override
  Future<void> putImage(String path, {String? album}) =>
      Gal.putImage(path, album: album);

  @override
  Future<void> putVideo(String path, {String? album}) =>
      Gal.putVideo(path, album: album);

  @override
  Future<bool> hasAccess() => Gal.hasAccess();

  @override
  Future<bool> requestAccess() => Gal.requestAccess();
}

/// Service de téléchargement de contenu vers la galerie de l'appareil.
///
/// Utilise [Dio] pour le téléchargement HTTP et [GalGateway] pour enregistrer
/// dans la galerie. Le fichier temporaire est supprimé après enregistrement.
///
/// Injecter un [GalGateway] custom via le constructeur pour les tests.
class DownloadService {
  final Dio _dio;
  final GalGateway _gal;

  DownloadService(this._dio, {GalGateway? gal})
      : _gal = gal ?? const DefaultGalGateway();

  /// Télécharge le fichier depuis [url] puis l'enregistre dans la galerie.
  ///
  /// [filename] est utilisé pour déterminer le type (image ou vidéo) et
  /// comme nom du fichier temporaire.
  /// [onProgress] reçoit une valeur entre 0.0 et 1.0 pendant le téléchargement.
  ///
  /// Lance une exception si le téléchargement ou l'enregistrement échoue.
  Future<void> downloadToGallery({
    required String url,
    required String filename,
    void Function(double progress)? onProgress,
  }) async {
    final tmpDir = await getTemporaryDirectory();
    final tmpPath = '${tmpDir.path}/$filename';

    try {
      await _dio.download(
        url,
        tmpPath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
        options: Options(
          // Pas de Bearer token : l'acheteur n'a pas de compte PPV.
          // L'authentification se fait via ?ref= dans l'URL.
          headers: {'Accept': '*/*'},
          receiveTimeout: const Duration(minutes: 2),
        ),
      );

      final ext = extractExtension(filename);
      final isVideo = const {'mp4', 'mov', 'avi', 'mkv', 'webm'}.contains(ext);

      if (isVideo) {
        await _gal.putVideo(tmpPath, album: 'SeeMi');
      } else {
        await _gal.putImage(tmpPath, album: 'SeeMi');
      }
    } finally {
      // Nettoyer le fichier temporaire dans tous les cas (succès ou erreur)
      final tmpFile = File(tmpPath);
      if (await tmpFile.exists()) {
        await tmpFile.delete();
      }
    }
  }

  /// Vérifie si la permission galerie est accordée, et la demande si nécessaire.
  /// Retourne [true] si la permission est accordée, [false] sinon.
  Future<bool> ensureGalleryPermission() async {
    if (await _gal.hasAccess()) return true;
    return _gal.requestAccess();
  }

  /// Extrait l'extension d'un nom de fichier en minuscules.
  /// Retourne 'jpg' par défaut si aucune extension n'est trouvée.
  static String extractExtension(String filename) {
    final dot = filename.lastIndexOf('.');
    if (dot != -1 && dot < filename.length - 1) {
      return filename.substring(dot + 1).toLowerCase();
    }
    return 'jpg';
  }
}
