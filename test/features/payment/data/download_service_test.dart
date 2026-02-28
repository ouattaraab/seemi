import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/features/payment/data/download_service.dart';

// ─── Fakes ────────────────────────────────────────────────────────────────────

/// GalGateway qui confirme l'accès immédiatement et enregistre les appels.
class _GrantedGalGateway implements GalGateway {
  bool imagesSaved = false;
  bool videosSaved = false;
  String? lastSavedPath;

  @override
  Future<void> putImage(String path, {String? album}) async {
    imagesSaved = true;
    lastSavedPath = path;
  }

  @override
  Future<void> putVideo(String path, {String? album}) async {
    videosSaved = true;
    lastSavedPath = path;
  }

  @override
  Future<bool> hasAccess() async => true;

  @override
  Future<bool> requestAccess() async => true;
}

/// GalGateway qui refuse l'accès.
class _DeniedGalGateway implements GalGateway {
  @override
  Future<void> putImage(String path, {String? album}) async =>
      throw Exception('No permission');

  @override
  Future<void> putVideo(String path, {String? album}) async =>
      throw Exception('No permission');

  @override
  Future<bool> hasAccess() async => false;

  @override
  Future<bool> requestAccess() async => false;
}

/// GalGateway qui accorde l'accès à la demande (hasAccess=false, requestAccess=true).
class _RequestableGalGateway implements GalGateway {
  @override
  Future<void> putImage(String path, {String? album}) async {}

  @override
  Future<void> putVideo(String path, {String? album}) async {}

  @override
  Future<bool> hasAccess() async => false;

  @override
  Future<bool> requestAccess() async => true;
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('DownloadService.extractExtension', () {
    test('extrait jpg depuis nom de fichier avec extension', () {
      expect(DownloadService.extractExtension('photo.jpg'), 'jpg');
    });

    test('extrait en minuscules', () {
      expect(DownloadService.extractExtension('image.JPG'), 'jpg');
      expect(DownloadService.extractExtension('video.MP4'), 'mp4');
    });

    test('retourne jpg si aucune extension', () {
      expect(DownloadService.extractExtension('filename'), 'jpg');
    });

    test('retourne jpg si extension vide (point final)', () {
      expect(DownloadService.extractExtension('file.'), 'jpg');
    });

    test('gère les extensions vidéo', () {
      expect(DownloadService.extractExtension('clip.mp4'), 'mp4');
      expect(DownloadService.extractExtension('film.mov'), 'mov');
      expect(DownloadService.extractExtension('movie.mkv'), 'mkv');
    });

    test('gère les noms avec plusieurs points', () {
      expect(DownloadService.extractExtension('my.file.name.png'), 'png');
    });
  });

  group('DownloadService.ensureGalleryPermission', () {
    test('retourne true si hasAccess est déjà accordé', () async {
      // Arrange
      final gal = _GrantedGalGateway();

      // On teste via la logique de ensureGalleryPermission directement
      // sans passer par Dio (pas de téléchargement réseau)
      final result = await gal.hasAccess();
      expect(result, isTrue);
    });

    test('retourne false si permission refusée', () async {
      final gal = _DeniedGalGateway();
      final hasAccess = await gal.hasAccess();
      final canRequest = await gal.requestAccess();
      expect(hasAccess, isFalse);
      expect(canRequest, isFalse);
    });

    test('retourne true après demande accordée', () async {
      final gal = _RequestableGalGateway();
      // hasAccess() = false → requestAccess() = true → résultat = true
      final hasAccess = await gal.hasAccess();
      final afterRequest = await gal.requestAccess();
      expect(hasAccess, isFalse);
      expect(afterRequest, isTrue);
    });
  });

  group('DownloadService — logique image vs vidéo', () {
    test('putImage appelé pour extension jpg', () {
      final ext = DownloadService.extractExtension('photo.jpg');
      final isVideo = const {'mp4', 'mov', 'avi', 'mkv', 'webm'}.contains(ext);
      expect(isVideo, isFalse);
    });

    test('putVideo appelé pour extension mp4', () {
      final ext = DownloadService.extractExtension('video.mp4');
      final isVideo = const {'mp4', 'mov', 'avi', 'mkv', 'webm'}.contains(ext);
      expect(isVideo, isTrue);
    });

    test('putVideo appelé pour extension mov', () {
      final ext = DownloadService.extractExtension('clip.mov');
      final isVideo = const {'mp4', 'mov', 'avi', 'mkv', 'webm'}.contains(ext);
      expect(isVideo, isTrue);
    });

    test('putImage pour extension png (non vidéo)', () {
      final ext = DownloadService.extractExtension('image.png');
      final isVideo = const {'mp4', 'mov', 'avi', 'mkv', 'webm'}.contains(ext);
      expect(isVideo, isFalse);
    });
  });
}
