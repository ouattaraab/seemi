import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/features/payment/data/download_service.dart';
import 'package:ppv_app/features/payment/presentation/widgets/download_button.dart';

// ─── Fakes GalGateway ────────────────────────────────────────────────────────

class _GrantedGalGateway implements GalGateway {
  @override
  Future<void> putImage(String path, {String? album}) async {}
  @override
  Future<void> putVideo(String path, {String? album}) async {}
  @override
  Future<bool> hasAccess() async => true;
  @override
  Future<bool> requestAccess() async => true;
}

class _DeniedGalGateway implements GalGateway {
  @override
  Future<void> putImage(String path, {String? album}) async =>
      throw Exception('Permission refusée');
  @override
  Future<void> putVideo(String path, {String? album}) async =>
      throw Exception('Permission refusée');
  @override
  Future<bool> hasAccess() async => false;
  @override
  Future<bool> requestAccess() async => false;
}

// ─── Fakes DownloadService ────────────────────────────────────────────────────

/// Téléchargement réussi instantané.
class _SuccessDownloadService extends DownloadService {
  _SuccessDownloadService() : super(Dio(), gal: _GrantedGalGateway());

  @override
  Future<void> downloadToGallery({
    required String url,
    required String filename,
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0.5);
    onProgress?.call(1.0);
  }

  @override
  Future<bool> ensureGalleryPermission() async => true;
}

/// Téléchargement qui échoue avec une erreur réseau.
class _FailingDownloadService extends DownloadService {
  _FailingDownloadService() : super(Dio(), gal: _GrantedGalGateway());

  @override
  Future<void> downloadToGallery({
    required String url,
    required String filename,
    void Function(double progress)? onProgress,
  }) async {
    throw DioException(
      requestOptions: RequestOptions(path: url),
      message: 'Connection refused',
      type: DioExceptionType.connectionError,
    );
  }

  @override
  Future<bool> ensureGalleryPermission() async => true;
}

/// Permission galerie refusée — downloadToGallery jamais appelé.
class _PermissionDeniedDownloadService extends DownloadService {
  _PermissionDeniedDownloadService()
      : super(Dio(), gal: _DeniedGalGateway());

  @override
  Future<bool> ensureGalleryPermission() async => false;
}

/// Service lent : bloque sur un [Completer] contrôlable depuis le test.
class _SlowDownloadService extends DownloadService {
  final _completer = Completer<void>();

  _SlowDownloadService() : super(Dio(), gal: _GrantedGalGateway());

  void complete() => _completer.complete();

  @override
  Future<void> downloadToGallery({
    required String url,
    required String filename,
    void Function(double progress)? onProgress,
  }) async {
    await _completer.future;
  }

  @override
  Future<bool> ensureGalleryPermission() async => true;
}

// ─── Helper ───────────────────────────────────────────────────────────────────

Widget _wrapWithMaterial(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('DownloadButton', () {
    testWidgets('affiche "Télécharger" et icône download à l\'état initial',
        (tester) async {
      await tester.pumpWidget(_wrapWithMaterial(
        DownloadButton(
          downloadUrl: 'https://api.ppv.io/original?ref=test',
          filename: 'photo.jpg',
          downloadService: _SuccessDownloadService(),
        ),
      ));

      expect(find.text('Télécharger'), findsOneWidget);
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
    });

    testWidgets('bouton est cliquable (onPressed != null) à l\'état idle',
        (tester) async {
      await tester.pumpWidget(_wrapWithMaterial(
        DownloadButton(
          downloadUrl: 'https://api.ppv.io/original?ref=test',
          filename: 'photo.jpg',
          downloadService: _SuccessDownloadService(),
        ),
      ));

      final button =
          tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('affiche "Enregistré" après téléchargement réussi',
        (tester) async {
      await tester.pumpWidget(_wrapWithMaterial(
        DownloadButton(
          downloadUrl: 'https://api.ppv.io/original?ref=test',
          filename: 'photo.jpg',
          downloadService: _SuccessDownloadService(),
        ),
      ));

      await tester.tap(find.text('Télécharger'));
      await tester.pumpAndSettle();

      expect(find.text('Enregistré'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('bouton désactivé (onPressed == null) après succès',
        (tester) async {
      await tester.pumpWidget(_wrapWithMaterial(
        DownloadButton(
          downloadUrl: 'https://api.ppv.io/original?ref=test',
          filename: 'photo.jpg',
          downloadService: _SuccessDownloadService(),
        ),
      ));

      await tester.tap(find.text('Télécharger'));
      await tester.pumpAndSettle();

      final button =
          tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('affiche SnackBar de succès après téléchargement',
        (tester) async {
      await tester.pumpWidget(_wrapWithMaterial(
        DownloadButton(
          downloadUrl: 'https://api.ppv.io/original?ref=test',
          filename: 'photo.jpg',
          downloadService: _SuccessDownloadService(),
        ),
      ));

      await tester.tap(find.text('Télécharger'));
      await tester.pumpAndSettle();

      expect(
          find.text('Contenu enregistré dans votre galerie'), findsOneWidget);
    });

    testWidgets('affiche SnackBar d\'erreur si téléchargement échoue',
        (tester) async {
      await tester.pumpWidget(_wrapWithMaterial(
        DownloadButton(
          downloadUrl: 'https://api.ppv.io/original?ref=test',
          filename: 'photo.jpg',
          downloadService: _FailingDownloadService(),
        ),
      ));

      await tester.tap(find.text('Télécharger'));
      await tester.pumpAndSettle();

      expect(
        find.text(
            'Échec du téléchargement. Vérifiez votre connexion.'),
        findsOneWidget,
      );
      // Bouton "Réessayer" présent dans le SnackBar
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('affiche SnackBar si permission galerie refusée',
        (tester) async {
      await tester.pumpWidget(_wrapWithMaterial(
        DownloadButton(
          downloadUrl: 'https://api.ppv.io/original?ref=test',
          filename: 'photo.jpg',
          downloadService: _PermissionDeniedDownloadService(),
        ),
      ));

      await tester.tap(find.text('Télécharger'));
      await tester.pumpAndSettle();

      expect(
        find.text(
            'Permission galerie refusée. Activez-la dans les réglages.'),
        findsOneWidget,
      );
    });

    testWidgets('bouton désactivé pendant le téléchargement en cours',
        (tester) async {
      final service = _SlowDownloadService();

      await tester.pumpWidget(_wrapWithMaterial(
        DownloadButton(
          downloadUrl: 'https://api.ppv.io/original?ref=test',
          filename: 'photo.jpg',
          downloadService: service,
        ),
      ));

      // Lancer le téléchargement sans attendre
      await tester.tap(find.text('Télécharger'));
      await tester.pump();

      // État intermédiaire : bouton désactivé
      final button =
          tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(button.onPressed, isNull);

      // Résoudre le téléchargement
      service.complete();
      await tester.pumpAndSettle();
    });
  });
}
