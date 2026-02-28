import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ppv_app/features/payment/data/download_service.dart';

enum _DownloadState { idle, downloading, success, error }

/// Bouton de téléchargement du contenu original vers la galerie de l'appareil.
///
/// Gère les états idle / downloading (avec pourcentage) / success / error.
/// Affiche une [SnackBar] de confirmation ou d'erreur après chaque tentative.
///
/// Injecter un [DownloadService] custom via le constructeur pour les tests.
class DownloadButton extends StatefulWidget {
  /// URL complète de l'endpoint de contenu original, incluant le ?ref=.
  final String downloadUrl;

  /// Nom du fichier à télécharger (utilisé pour déterminer image vs vidéo).
  final String filename;

  /// Service de téléchargement injecté (optionnel, pour les tests).
  final DownloadService? downloadService;

  const DownloadButton({
    super.key,
    required this.downloadUrl,
    required this.filename,
    this.downloadService,
  });

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  _DownloadState _state = _DownloadState.idle;
  double _progress = 0.0;
  late final DownloadService _service;

  @override
  void initState() {
    super.initState();
    // Service injecté (tests) ou créé avec Dio sans AuthInterceptor.
    // L'authentification se fait via le paramètre ?ref= dans l'URL.
    _service = widget.downloadService ?? DownloadService(Dio());
  }

  Future<void> _startDownload() async {
    // Vérifier/demander la permission galerie
    final hasPermission = await _service.ensureGalleryPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Permission galerie refusée. Activez-la dans les réglages.'),
          ),
        );
      }
      return;
    }

    setState(() {
      _state = _DownloadState.downloading;
      _progress = 0.0;
    });

    try {
      await _service.downloadToGallery(
        url: widget.downloadUrl,
        filename: widget.filename,
        onProgress: (progress) {
          if (mounted) {
            setState(() => _progress = progress);
          }
        },
      );

      if (mounted) {
        setState(() => _state = _DownloadState.success);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contenu enregistré dans votre galerie'),
            backgroundColor: Color(0xFF00BFA5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _state = _DownloadState.error);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('Échec du téléchargement. Vérifiez votre connexion.'),
            action: SnackBarAction(
              label: 'Réessayer',
              onPressed: () {
                setState(() => _state = _DownloadState.idle);
                _startDownload();
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _DownloadState.downloading => _buildProgressButton(),
      _DownloadState.success => _buildSuccessButton(),
      _ => _buildIdleButton(),
    };
  }

  Widget _buildIdleButton() {
    return OutlinedButton.icon(
      onPressed: _startDownload,
      icon: const Icon(Icons.download_rounded, size: 18),
      label: const Text('Télécharger'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF00BFA5),
        side: const BorderSide(color: Color(0xFF00BFA5), width: 1.5),
      ),
    );
  }

  Widget _buildProgressButton() {
    return OutlinedButton.icon(
      onPressed: null, // Désactivé pendant le téléchargement
      icon: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          value: _progress > 0 ? _progress : null,
          strokeWidth: 2.0,
          color: const Color(0xFF00BFA5),
        ),
      ),
      label: Text(
        _progress > 0 ? '${(_progress * 100).toInt()}%' : 'Téléchargement...',
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.grey,
        side: const BorderSide(color: Colors.grey),
      ),
    );
  }

  Widget _buildSuccessButton() {
    return OutlinedButton.icon(
      onPressed: null, // Déjà téléchargé
      icon: const Icon(Icons.check_circle_outline, size: 18),
      label: const Text('Enregistré'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF00BFA5),
        side: const BorderSide(color: Color(0xFF00BFA5)),
      ),
    );
  }
}
