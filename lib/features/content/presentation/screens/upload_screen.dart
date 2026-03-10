import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/content/presentation/content_provider.dart';
import 'package:ppv_app/features/sharing/data/contact_repository.dart';
import 'package:ppv_app/features/sharing/data/share_repository.dart';
import 'package:ppv_app/features/sharing/presentation/contact_picker_sheet.dart';

/// Écran de publication tout-en-un : sélection → upload → prix → lien.
///
/// Flux unique sans navigation entre pages :
/// 1. Sélectionner photo ou vidéo
/// 2. Upload automatique avec spinner et progression
/// 3. Saisir le prix
/// 4. Générer le lien et partager
class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final ImagePicker _picker = ImagePicker();

  // ── Sélection du média ──
  String? _contentType; // null | 'photo' | 'video'
  File? _selectedFile;
  Uint8List? _videoThumbnail;

  // ── Compression vidéo ──
  double? _compressionProgress; // 0.0–1.0 pendant la compression
  Subscription? _compressSubscription;

  // ── Hash SHA-256 (détection doublons) ──
  String? _fileHash;

  // ── État upload ──
  int? _uploadedContentId;

  // ── Pricing ──
  int? _selectedPriceFcfa;
  final TextEditingController _priceCtrl = TextEditingController();
  bool _tosAccepted = false;
  bool _isViewOnce = false;
  String? _publishError;

  // ── Partage ──
  String? _shareUrl;

  // ── Blur preview (backoff exponentiel — remplace le polling fixe 2 s × 15) ──
  String? _blurPreviewUrl;
  bool _blurPolling = false;

  @override
  void dispose() {
    _compressSubscription?.unsubscribe();
    VideoCompress.cancelCompression();
    _priceCtrl.dispose();
    super.dispose();
  }

  // ─── Sélection photo ──────────────────────────────────────────────────────

  Future<void> _onPhotoTypeTapped() async {
    setState(() => _contentType = 'photo');
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SourcePickerSheet(
        onGallery: () => Navigator.pop<ImageSource>(ctx, ImageSource.gallery),
        onCamera: () => Navigator.pop<ImageSource>(ctx, ImageSource.camera),
      ),
    );
    if (!mounted) return;
    if (source == null) {
      setState(() => _contentType = null);
      return;
    }
    await _pickImage(source);
    if (_selectedFile == null && mounted) {
      setState(() => _contentType = null);
    }
  }

  Future<void> _onVideoTypeTapped() async {
    setState(() => _contentType = 'video');
    await _pickVideo();
    if (_selectedFile == null && mounted) {
      setState(() => _contentType = null);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        // Pas de contrainte de dimensions : résolution d'origine préservée.
        // La compression JPEG (flutter_image_compress) réduit les octets sans redimensionner.
      );
      if (picked == null) return;

      // Compression JPEG qualité 65 — dimensions préservées, poids réduit < ~1 Mo
      final compressed = await _compressImage(File(picked.path));
      final file = compressed ?? File(picked.path);

      if (!await _validateSize(file, 10, 'La photo dépasse 10 Mo')) return;
      setState(() {
        _selectedFile = file;
        _videoThumbnail = null;
      });
      await _startUpload();
    } catch (e) {
      _showSnack(
        'Impossible d\'accéder à la galerie ou à la caméra. Vérifiez les permissions dans les paramètres.',
      );
    }
  }

  /// Compresse une image en réduisant la qualité JPEG SANS modifier les dimensions.
  /// Les métadonnées EXIF sont supprimées (confidentialité + poids).
  /// Retourne null si la compression échoue (on envoie alors l'original).
  Future<File?> _compressImage(File file) async {
    try {
      final tmpDir  = await getTemporaryDirectory();
      final outPath = '${tmpDir.path}/seemi_compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final result  = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        outPath,
        // 99999 : aucune limite de dimensions → les pixels d'origine sont conservés
        minWidth:  99999,
        minHeight: 99999,
        quality:   65, // ~65 % qualité JPEG : bon compromis taille/rendu visuel
        format:    CompressFormat.jpeg,
        keepExif:  false,
      );
      return result != null ? File(result.path) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickVideo() async {
    try {
      final picked = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 600), // 10 min max
      );
      if (picked == null) return;
      final originalFile = File(picked.path);

      // Validation taille brute avant compression (200 Mo absolus)
      if (!await _validateSize(originalFile, 200, 'La vidéo dépasse 200 Mo')) {
        return;
      }

      // 1. Extraire la miniature depuis le fichier original (vraie frame)
      final thumb = await VideoThumbnail.thumbnailData(
        video: originalFile.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 1280,
        quality: 70,
      );

      // 2. Calculer le hash SHA-256 du fichier ORIGINAL (avant compression)
      //    → détection de doublon côté serveur
      final hash = await _computeSha256(originalFile);

      // Afficher l'écran de sélection avec la miniature pendant la compression
      setState(() {
        _selectedFile    = originalFile;
        _videoThumbnail  = thumb;
        _fileHash        = hash;
        _compressionProgress = 0;
      });

      // 3. Compression vidéo (qualité medium, 1080p max, 30 fps)
      _compressSubscription?.unsubscribe();
      _compressSubscription = VideoCompress.compressProgress$.subscribe((p) {
        if (mounted) setState(() => _compressionProgress = p / 100);
      });

      final info = await VideoCompress.compressVideo(
        originalFile.path,
        quality:      VideoQuality.MediumQuality,
        includeAudio: true,
        frameRate:    30,
      );

      _compressSubscription?.unsubscribe();
      _compressSubscription = null;

      if (!mounted) return;

      final compressedFile = info?.file;
      if (compressedFile == null) {
        // Fallback : si la compression échoue, on envoie l'original
        setState(() => _compressionProgress = null);
      } else {
        setState(() {
          _selectedFile        = compressedFile;
          _compressionProgress = null;
        });
      }

      await _startUpload();
    } catch (e) {
      _compressSubscription?.unsubscribe();
      _compressSubscription = null;
      if (mounted) {
        setState(() {
          _compressionProgress = null;
          _contentType = null;
          _selectedFile = null;
        });
        _showSnack(
          'Impossible d\'accéder à la galerie vidéo ou de compresser. Vérifiez les permissions.',
        );
      }
    }
  }

  /// Calcule le SHA-256 d'un fichier.
  Future<String> _computeSha256(File file) async {
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  Future<bool> _validateSize(File file, double maxMb, String msg) async {
    final sizeMb = await file.length() / (1024 * 1024);
    if (sizeMb > maxMb) {
      _showSnack(msg);
      return false;
    }
    return true;
  }

  // ─── Upload ───────────────────────────────────────────────────────────────

  Future<void> _startUpload() async {
    if (_selectedFile == null) return;
    final provider = context.read<ContentProvider>();
    if (provider.isLoading) return;

    bool success;
    if (_contentType == 'photo') {
      // Photo : upload standard avec hash pour détection doublon
      final hash = _fileHash ?? await _computeSha256(_selectedFile!);
      success = await provider.uploadPhoto(_selectedFile!, fileHash: hash);
    } else {
      // Vidéo : upload chunked avec miniature + hash
      success = await provider.uploadVideoChunked(
        _selectedFile!,
        thumbnail: _videoThumbnail,
        fileHash:  _fileHash,
      );
    }

    if (!mounted) return;
    if (success) {
      final contentId = provider.lastUploadedContent?.id;
      setState(() => _uploadedContentId = contentId);
      if (contentId != null) {
        _startBlurWithBackoff(contentId);
      }
    } else {
      _showSnack(provider.error ?? 'Erreur lors du téléchargement');
    }
  }

  Future<void> _retryUpload() async {
    context.read<ContentProvider>().resetUploadState();
    setState(() {
      _fileHash            = null;
      _compressionProgress = null;
    });
    await _startUpload();
  }

  // ─── Backoff exponentiel pour le blur ────────────────────────────────────
  // Remplace le polling fixe 2 s × 15 (30 s) par un backoff 1→8 s (≈ 36 s max, 8 polls).

  void _startBlurWithBackoff(int contentId) {
    setState(() => _blurPolling = true);
    context.read<ContentProvider>().pollBlurWithBackoff(contentId).then((url) {
      if (!mounted) return;
      setState(() {
        _blurPreviewUrl = url;
        _blurPolling    = false;
      });
    });
  }

  // ─── Publication ──────────────────────────────────────────────────────────

  bool get _canPublish =>
      _selectedPriceFcfa != null &&
      _selectedPriceFcfa! >= 100 &&
      _tosAccepted;

  Future<void> _doPublish() async {
    if (!_canPublish || _uploadedContentId == null) return;
    final provider = context.read<ContentProvider>();
    if (provider.isPublishing) return;

    setState(() => _publishError = null);

    final success = await provider.publishContent(
      _uploadedContentId!,
      _selectedPriceFcfa!,
      viewOnce: _isViewOnce,
    );

    if (!mounted) return;
    if (success) {
      setState(() => _shareUrl = provider.lastPublishedContent?.shareUrl);
    } else {
      setState(
          () => _publishError = provider.error ?? 'Erreur lors de la publication');
    }
  }

  // ─── Partage ──────────────────────────────────────────────────────────────

  Future<void> _copyLink() async {
    if (_shareUrl == null) return;
    await Clipboard.setData(ClipboardData(text: _shareUrl!));
    if (mounted) {
      _showSnack('Lien copié dans le presse-papier !', bg: AppColors.kSuccess);
    }
  }

  Future<void> _shareLink() async {
    if (_shareUrl == null) return;
    final repo = context.read<ShareRepository>();
    await repo.shareContent(_shareUrl!);
    if (mounted) _showSnack('Lien partagé !', bg: AppColors.kSuccess);
  }

  Future<void> _shareToContact() async {
    if (_shareUrl == null) return;
    final contactRepo = context.read<ContactRepository>();
    final granted = await contactRepo.requestPermission();
    if (!mounted) return;
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Permission contacts refusée. Activez-la dans les paramètres.'),
        ),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ContactPickerSheet(
        shareUrl: _shareUrl!,
        repository: contactRepo,
      ),
    );
  }

  // ─── Reset ────────────────────────────────────────────────────────────────

  void _reset() {
    _compressSubscription?.unsubscribe();
    _compressSubscription = null;
    VideoCompress.cancelCompression();
    context.read<ContentProvider>().resetUploadState();
    setState(() {
      _contentType         = null;
      _selectedFile        = null;
      _videoThumbnail      = null;
      _compressionProgress = null;
      _fileHash            = null;
      _uploadedContentId   = null;
      _selectedPriceFcfa   = null;
      _priceCtrl.clear();
      _tosAccepted         = false;
      _isViewOnce          = false;
      _publishError        = null;
      _shareUrl            = null;
      _blurPreviewUrl      = null;
      _blurPolling         = false;
    });
  }

  void _showSnack(String msg, {Color? bg}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: bg ?? AppColors.kError,
    ));
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgBase,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: Consumer<ContentProvider>(
                builder: (context, provider, child) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.kScreenMargin,
                    vertical: AppSpacing.kSpaceMd,
                  ),
                  child: _buildContent(provider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    final String title;
    if (_shareUrl != null) {
      title = 'Lien généré !';
    } else if (_uploadedContentId != null) {
      title = 'Définir le prix';
    } else if (_compressionProgress != null) {
      title = 'Compression en cours...';
    } else if (_selectedFile != null) {
      title = 'Upload en cours...';
    } else {
      title = 'Publier un contenu';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_shareUrl != null) {
                _reset();
              } else {
                Navigator.of(context).maybePop();
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.kBgElevated,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.kTextPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title, style: AppTextStyles.kTitleLarge),
          ),
          if (_selectedFile != null && _shareUrl == null)
            GestureDetector(
              onTap: _reset,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.kError.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.kError,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Contenu principal ─────────────────────────────────────────────────────

  Widget _buildContent(ContentProvider provider) {
    if (_contentType == null && _selectedFile == null) {
      return _buildTypeSelection();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMediaSection(provider),
        const SizedBox(height: AppSpacing.kSpaceLg),

        AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          child: _uploadedContentId != null && _shareUrl == null
              ? _buildPricingSection(provider)
              : const SizedBox.shrink(),
        ),

        AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          child: _shareUrl != null
              ? _buildSharingSection()
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: AppSpacing.kSpaceMd),
        _buildActionButton(provider),
        const SizedBox(height: AppSpacing.kSpaceLg),
      ],
    );
  }

  // ── Phase 1 : sélection du type ───────────────────────────────────────────

  Widget _buildTypeSelection() {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.kSpaceXl),
        const Text(
          'Que voulez-vous publier ?',
          style: AppTextStyles.kHeadlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.kSpaceSm),
        Text(
          'Sélectionnez le type de contenu\npour commencer',
          style: AppTextStyles.kBodyMedium
              .copyWith(color: AppColors.kTextSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.kSpaceXl),
        Row(
          children: [
            Expanded(
              child: _TypeCard(
                icon: Icons.photo_camera_rounded,
                label: 'Photo',
                subtitle: '10 Mo max',
                color: AppColors.kPrimary,
                onTap: _onPhotoTypeTapped,
              ),
            ),
            const SizedBox(width: AppSpacing.kSpaceMd),
            Expanded(
              child: _TypeCard(
                icon: Icons.videocam_rounded,
                label: 'Vidéo',
                subtitle: '200 Mo · Auto-compressé',
                color: AppColors.kPrimaryDark,
                onTap: _onVideoTypeTapped,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.kSpace2xl),
      ],
    );
  }

  // ── Section média ─────────────────────────────────────────────────────────

  Widget _buildMediaSection(ContentProvider provider) {
    final bool hasFile = _selectedFile != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Sélectionner un média'),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: hasFile && !provider.isLoading
              ? (_contentType == 'photo' ? _onPhotoTypeTapped : null)
              : null,
          child: AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: AppColors.kAccent.withValues(alpha: 0.40),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Fond / miniature
                    if (_contentType == 'photo' && _selectedFile != null)
                      Image.file(_selectedFile!, fit: BoxFit.cover)
                    else if (_videoThumbnail != null)
                      Image.memory(_videoThumbnail!, fit: BoxFit.cover)
                    else
                      Container(
                        color: AppColors.kBgElevated,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppColors.kAccent.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 36,
                                color: AppColors.kAccent,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Appuyez pour sélectionner',
                              style: AppTextStyles.kBodyMedium.copyWith(
                                color: AppColors.kTextSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ── Overlay compression (avant upload) ──
                    if (_compressionProgress != null) ...[
                      Container(color: Colors.black.withValues(alpha: 0.65)),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 52,
                              height: 52,
                              child: CircularProgressIndicator(
                                value: _compressionProgress,
                                color: Colors.orangeAccent,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.25),
                                strokeWidth: 4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _compressionProgress! > 0
                                  ? 'Compression ${(_compressionProgress! * 100).toInt()}%'
                                  : 'Préparation...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Optimisation de la vidéo...',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ── Overlay upload (après compression) ──
                    if (provider.isLoading && _compressionProgress == null) ...[
                      Container(
                          color: Colors.black.withValues(alpha: 0.55)),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 52,
                              height: 52,
                              child: CircularProgressIndicator(
                                value: provider.uploadProgress,
                                color: Colors.white,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.25),
                                strokeWidth: 4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              provider.uploadProgress != null
                                  ? 'Upload ${(provider.uploadProgress! * 100).toInt()}%'
                                  : 'Envoi...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Veuillez patienter...',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Overlay "Changer le média"
                    if (hasFile &&
                        !provider.isLoading &&
                        _contentType == 'photo')
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.50),
                              ],
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.edit_rounded,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Changer le média',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Badge "Chargé"
                    if (_uploadedContentId != null)
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.kSuccess,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Chargé',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Badge type
                    if (hasFile &&
                        _uploadedContentId == null &&
                        !provider.isLoading)
                      Positioned(
                        top: 14,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _contentType == 'photo'
                                    ? Icons.photo_camera_rounded
                                    : Icons.videocam_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _contentType == 'photo' ? 'Photo' : 'Vidéo',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Barre de progression (compression ou upload)
        if (_compressionProgress != null || (provider.isLoading && provider.uploadProgress != null)) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _compressionProgress ?? provider.uploadProgress,
              color: _compressionProgress != null
                  ? Colors.orangeAccent
                  : AppColors.kAccent,
              backgroundColor: AppColors.kBorder,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _compressionProgress != null
                ? 'Compression en cours...'
                : 'Upload en cours...',
            style: AppTextStyles.kCaption.copyWith(color: AppColors.kTextTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  // ── Section pricing ───────────────────────────────────────────────────────

  Widget _buildPricingSection(ContentProvider provider) {
    final int? earnings = _selectedPriceFcfa != null
        ? (_selectedPriceFcfa! * 0.80).toInt()
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Aperçu flou (acheteur) ──────────────────────────────────────────
        if (_blurPreviewUrl != null || _blurPolling) ...[
          const _SectionLabel('Aperçu flou (acheteur)'),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1,
              child: _blurPreviewUrl != null
                  ? Image.network(
                      _blurPreviewUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const _GradientBlurPlaceholder(loading: false),
                    )
                  : const _GradientBlurPlaceholder(loading: true),
            ),
          ),
          const SizedBox(height: AppSpacing.kSpaceLg),
        ],

        const _SectionLabel('Définir le prix'),
        const SizedBox(height: 12),

        // Input FCFA
        Container(
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.kBgSurface,
            borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
            border: Border.all(
              color: _selectedPriceFcfa != null
                  ? AppColors.kPrimary.withValues(alpha: 0.50)
                  : AppColors.kBorder,
              width: _selectedPriceFcfa != null ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.kTextPrimary.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 20, right: 8),
                child: Text(
                  'FCFA',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: AppColors.kTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 28,
                color: AppColors.kBorder,
              ),
              Expanded(
                child: TextFormField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: AppColors.kTextPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: AppColors.kTextTertiary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    setState(() {
                      _selectedPriceFcfa =
                          (parsed != null && parsed >= 100) ? parsed : null;
                    });
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Chips prix rapides
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [500, 1000, 2000, 5000].map((price) {
              final selected = _selectedPriceFcfa == price;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPriceFcfa = price;
                      _priceCtrl.text = price.toString();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.kPrimary
                          : AppColors.kBgSurface,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.kRadiusPill),
                      border: Border.all(
                        color: selected
                            ? AppColors.kPrimary
                            : AppColors.kBorder,
                      ),
                    ),
                    child: Text(
                      '$price FCFA',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? Colors.white
                            : AppColors.kTextSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 10),

        // Aide revenus
        if (earnings != null)
          Row(
            children: [
              const Icon(Icons.trending_up_rounded,
                  size: 14, color: AppColors.kSuccess),
              const SizedBox(width: 5),
              Text(
                'Vous recevrez environ $earnings FCFA (80%)',
                style: AppTextStyles.kCaption.copyWith(
                  color: AppColors.kSuccess,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          )
        else
          Text(
            'Minimum 100 FCFA · Vous recevez 80% du prix',
            style:
                AppTextStyles.kCaption.copyWith(color: AppColors.kTextSecondary),
          ),

        const SizedBox(height: 20),

        // Toggle Vue unique
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isViewOnce
                ? AppColors.kAccentViolet.withValues(alpha: 0.05)
                : AppColors.kBgSurface,
            borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
            border: Border.all(
              color: _isViewOnce
                  ? AppColors.kAccentViolet.withValues(alpha: 0.40)
                  : AppColors.kBorder,
            ),
          ),
          child: SwitchListTile(
            value: _isViewOnce,
            onChanged: (v) => setState(() => _isViewOnce = v),
            activeTrackColor: AppColors.kAccentViolet,
            activeThumbColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            title: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isViewOnce
                        ? AppColors.kAccentViolet.withValues(alpha: 0.12)
                        : AppColors.kBgElevated,
                  ),
                  child: Icon(
                    Icons.visibility_off_outlined,
                    size: 17,
                    color: _isViewOnce
                        ? AppColors.kAccentViolet
                        : AppColors.kTextSecondary,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vue unique',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.kTextPrimary,
                        ),
                      ),
                      Text(
                        'L\'acheteur ne peut voir ce contenu qu\'une seule fois',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          color: AppColors.kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Erreur publication
        if (_publishError != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.kError.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
              border: Border.all(
                  color: AppColors.kError.withValues(alpha: 0.22)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.kError, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _publishError!,
                    style: AppTextStyles.kCaption
                        .copyWith(color: AppColors.kError),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // CGU checkbox
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: Checkbox(
                value: _tosAccepted,
                onChanged: (v) =>
                    setState(() => _tosAccepted = v ?? false),
                activeColor: AppColors.kPrimary,
                checkColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
                side: const BorderSide(
                    color: AppColors.kBorder, width: 1.5),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    setState(() => _tosAccepted = !_tosAccepted),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.kBodyMedium
                          .copyWith(color: AppColors.kTextSecondary),
                      children: const [
                        TextSpan(text: 'Je certifie être '),
                        TextSpan(
                          text: 'l\'auteur ou titulaire des droits',
                          style: TextStyle(
                            color: AppColors.kPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: ' sur ce contenu, que toute personne y apparaissant est '
                              'majeure et a consenti, et j\'assume l\'entière '
                              'responsabilité de sa publication.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.kSpaceMd),
      ],
    );
  }

  // ── Section partage ───────────────────────────────────────────────────────

  Widget _buildSharingSection() {
    if (_shareUrl == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Succès banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.kSuccess.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
            border: Border.all(
                color: AppColors.kSuccess.withValues(alpha: 0.20)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.kSuccess.withValues(alpha: 0.14),
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppColors.kSuccess, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contenu publié !',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.kTextPrimary,
                      ),
                    ),
                    Text(
                      '$_selectedPriceFcfa FCFA pour déverrouiller',
                      style: AppTextStyles.kCaption
                          .copyWith(color: AppColors.kTextSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Lien copiable
        GestureDetector(
          onTap: _copyLink,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.kPrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
              border: Border.all(
                  color: AppColors.kPrimary.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                const Icon(Icons.link_rounded,
                    color: AppColors.kPrimary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _shareUrl!,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      color: AppColors.kPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.copy_rounded,
                    color: AppColors.kPrimary, size: 18),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Divider "Ou partager directement"
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.kBorder)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Ou partager directement',
                style: AppTextStyles.kCaption
                    .copyWith(color: AppColors.kTextTertiary),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.kBorder)),
          ],
        ),

        const SizedBox(height: 20),

        // Cercles sociaux
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _SocialCircle(
              label: 'WhatsApp',
              color: const Color(0xFF25D366),
              icon: Icons.chat_rounded,
              onTap: _shareLink,
            ),
            _SocialCircle(
              label: 'Facebook',
              color: const Color(0xFF1877F2),
              icon: Icons.thumb_up_outlined,
              onTap: _shareLink,
            ),
            _SocialCircle(
              label: 'TikTok',
              color: AppColors.kTextPrimary,
              icon: Icons.music_note_rounded,
              onTap: _shareLink,
            ),
            _SocialCircle(
              label: 'Contact',
              color: AppColors.kPrimary,
              icon: Icons.contacts_rounded,
              onTap: _shareToContact,
            ),
            _SocialCircle(
              label: 'Copier',
              color: AppColors.kBgElevated,
              icon: Icons.copy_rounded,
              iconColor: AppColors.kTextSecondary,
              labelColor: AppColors.kTextTertiary,
              onTap: _copyLink,
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.kSpaceMd),
      ],
    );
  }

  // ── Bouton d'action principal ─────────────────────────────────────────────

  Widget _buildActionButton(ContentProvider provider) {
    // Terminer (après publication)
    if (_shareUrl != null) {
      return SizedBox(
        width: double.infinity,
        height: AppSpacing.kButtonHeight,
        child: FilledButton.icon(
          onPressed: () {
            _reset();
            Navigator.of(context).maybePop();
          },
          icon: const Icon(Icons.home_rounded, size: 22),
          label: const Text('Retour à l\'accueil'),
          style: FilledButton.styleFrom(
            shape: const StadiumBorder(),
          ),
        ),
      );
    }

    // Générer le lien (après upload)
    if (_uploadedContentId != null) {
      return Column(
        children: [
          if (provider.isPublishing)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  color: AppColors.kAccent,
                  backgroundColor: AppColors.kBorder,
                  minHeight: 4,
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: AppSpacing.kButtonHeight,
            child: FilledButton.icon(
              onPressed:
                  _canPublish && !provider.isPublishing ? _doPublish : null,
              icon: provider.isPublishing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Icon(
                      Icons.link_rounded,
                      size: 22,
                      color: _canPublish ? AppColors.kAccent : null,
                    ),
              label: Text(provider.isPublishing
                  ? 'Publication en cours...'
                  : 'Générer & Publier le lien'),
              style: FilledButton.styleFrom(
                shape: const StadiumBorder(),
                disabledBackgroundColor:
                    AppColors.kPrimary.withValues(alpha: 0.35),
                disabledForegroundColor: Colors.white54,
                shadowColor: AppColors.kPrimary.withValues(alpha: 0.35),
                elevation: _canPublish ? 6 : 0,
              ),
            ),
          ),
          if (!_canPublish) ...[
            const SizedBox(height: 8),
            Text(
              _selectedPriceFcfa == null
                  ? 'Saisissez un prix (min. 100 FCFA)'
                  : 'Acceptez les CGU pour continuer',
              style: AppTextStyles.kCaption
                  .copyWith(color: AppColors.kTextTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      );
    }

    // Erreur upload : bouton réessayer
    if (provider.error != null &&
        _selectedFile != null &&
        !provider.isLoading) {
      return SizedBox(
        width: double.infinity,
        height: AppSpacing.kButtonHeight,
        child: FilledButton.icon(
          onPressed: _retryUpload,
          icon: const Icon(Icons.refresh_rounded, size: 22),
          label: const Text('Réessayer'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.kError,
            shape: const StadiumBorder(),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

// ─── _SectionLabel ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: AppColors.kTextTertiary,
      ),
    );
  }
}

// ─── _TypeCard ────────────────────────────────────────────────────────────────

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.kBgSurface,
      borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 36),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
            border: Border.all(
                color: color.withValues(alpha: 0.22), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 44, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.kTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: AppColors.kTextTertiary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── _SocialCircle ────────────────────────────────────────────────────────────

class _SocialCircle extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _SocialCircle({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          ClipOval(
            child: Material(
              color: color,
              child: InkWell(
                onTap: onTap,
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: Icon(
                    icon,
                    color: iconColor ?? Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: labelColor ?? AppColors.kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _DashedBorderPainter ─────────────────────────────────────────────────────

class _DashedBorderPainter extends CustomPainter {
  final Color color;

  const _DashedBorderPainter({required this.color});

  static const double _radius = 40;
  static const double _stroke = 2;
  static const double _dash = 8;
  static const double _gap = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            _stroke / 2,
            _stroke / 2,
            size.width - _stroke,
            size.height - _stroke,
          ),
          const Radius.circular(_radius - _stroke / 2),
        ),
      );

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + _dash),
          paint,
        );
        distance += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}

// ─── _SourcePickerSheet ───────────────────────────────────────────────────────

class _SourcePickerSheet extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  const _SourcePickerSheet({required this.onGallery, required this.onCamera});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        color: AppColors.kBgSurface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Choisir la source',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                color: AppColors.kTextPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _SourceOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Galerie',
                    onTap: onGallery,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SourceOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Caméra',
                    onTap: onCamera,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Annuler',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: AppColors.kTextSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _GradientBlurPlaceholder ─────────────────────────────────────────────────

/// Placeholder animé affiché pendant le polling du blur ou en cas d'erreur de chargement.
class _GradientBlurPlaceholder extends StatefulWidget {
  final bool loading;

  const _GradientBlurPlaceholder({required this.loading});

  @override
  State<_GradientBlurPlaceholder> createState() =>
      _GradientBlurPlaceholderState();
}

class _GradientBlurPlaceholderState extends State<_GradientBlurPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.kPrimary.withValues(alpha: 0.30 * _anim.value),
              AppColors.kAccent.withValues(alpha: 0.20 * _anim.value),
              AppColors.kBgElevated,
            ],
          ),
        ),
        child: widget.loading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppColors.kPrimary.withValues(alpha: 0.70),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Génération du flou...',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kTextSecondary,
                      ),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Material(
        color: AppColors.kBgElevated,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.kBorder),
            ),
            child: Column(
              children: [
                Icon(icon, size: 40, color: AppColors.kPrimary),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: AppColors.kTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
