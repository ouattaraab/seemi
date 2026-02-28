import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/content/presentation/content_provider.dart';
import 'package:ppv_app/features/content/presentation/screens/pricing_screen.dart';

/// Écran de publication de photo ou vidéo — galerie ou appareil photo.
class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final ImagePicker _picker = ImagePicker();

  // Type sélectionné : null = vue initiale, 'photo' ou 'video'
  String? _contentType;

  // État photo
  File? _selectedPhoto;

  // État vidéo
  File? _selectedVideo;
  Uint8List? _videoThumbnail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _retrieveLostData();
    });
  }

  Future<void> _retrieveLostData() async {
    final response = await _picker.retrieveLostData();
    if (!response.isEmpty && response.file != null) {
      final file = File(response.file!.path);
      if (await _validatePhotoSize(file)) {
        setState(() {
          _contentType = 'photo';
          _selectedPhoto = file;
        });
      }
    }
  }

  // ─── Validation taille ───────────────────────────────────────────────────

  Future<bool> _validatePhotoSize(File file) async {
    final sizeInMb = await file.length() / (1024 * 1024);
    if (sizeInMb > 10) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('La photo dépasse 10 Mo'),
            backgroundColor: AppColors.kError,
          ),
        );
      }
      return false;
    }
    return true;
  }

  Future<bool> _validateVideoSize(File file) async {
    final sizeInMb = await file.length() / (1024 * 1024);
    if (sizeInMb > 50) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('La vidéo dépasse 50 Mo'),
            backgroundColor: AppColors.kError,
          ),
        );
      }
      return false;
    }
    return true;
  }

  // ─── Sélection médias ────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (picked == null) return;

      final file = File(picked.path);
      if (await _validatePhotoSize(file)) {
        setState(() => _selectedPhoto = file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Impossible d\'accéder à la galerie ou la caméra. Vérifiez les permissions dans les paramètres.',
            ),
            backgroundColor: AppColors.kError,
          ),
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      final picked = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 300),
      );

      if (picked == null) return;

      final file = File(picked.path);
      if (!await _validateVideoSize(file)) return;

      final thumbData = await VideoThumbnail.thumbnailData(
        video: file.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 1920,
        quality: 50,
      );

      setState(() {
        _selectedVideo = file;
        _videoThumbnail = thumbData;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Impossible d\'accéder à la galerie vidéo. Vérifiez les permissions dans les paramètres.',
            ),
            backgroundColor: AppColors.kError,
          ),
        );
      }
    }
  }

  // ─── Upload ──────────────────────────────────────────────────────────────

  Future<void> _uploadPhoto() async {
    if (_selectedPhoto == null) return;

    final provider = context.read<ContentProvider>();
    if (provider.isLoading) return;

    final success = await provider.uploadPhoto(_selectedPhoto!);

    if (!mounted) return;

    if (success) {
      final content = provider.lastUploadedContent;
      setState(() => _selectedPhoto = null);
      provider.resetUploadState();
      if (content != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PricingScreen(
              contentId: content.id,
              contentType: content.type,
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Erreur lors du téléchargement'),
          backgroundColor: AppColors.kError,
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: AppColors.kTextPrimary,
            onPressed: _uploadPhoto,
          ),
        ),
      );
    }
  }

  Future<void> _uploadVideo() async {
    if (_selectedVideo == null) return;

    final provider = context.read<ContentProvider>();
    if (provider.isLoading) return;

    final success = await provider.uploadVideo(_selectedVideo!);

    if (!mounted) return;

    if (success) {
      final content = provider.lastUploadedContent;
      setState(() {
        _selectedVideo = null;
        _videoThumbnail = null;
      });
      provider.resetUploadState();
      if (content != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PricingScreen(
              contentId: content.id,
              contentType: content.type,
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Erreur lors du téléchargement'),
          backgroundColor: AppColors.kError,
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: AppColors.kTextPrimary,
            onPressed: _uploadVideo,
          ),
        ),
      );
    }
  }

  // ─── Annulation ──────────────────────────────────────────────────────────

  void _cancelPhotoSelection() {
    setState(() => _selectedPhoto = null);
    context.read<ContentProvider>().resetUploadState();
  }

  void _cancelVideoSelection() {
    setState(() {
      _selectedVideo = null;
      _videoThumbnail = null;
    });
    context.read<ContentProvider>().resetUploadState();
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  String get _appBarTitle {
    switch (_contentType) {
      case 'photo':
        return 'Publier une photo';
      case 'video':
        return 'Publier une vidéo';
      default:
        return 'Publier du contenu';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgBase,
      appBar: AppBar(
        title: Text(_appBarTitle, style: AppTextStyles.kHeadlineMedium),
        backgroundColor: AppColors.kBgBase,
      ),
      body: Consumer<ContentProvider>(
        builder: (context, provider, _) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.kScreenMargin),
              child: _buildBody(provider),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(ContentProvider provider) {
    if (_contentType == null) return _buildTypeSelectionView();
    if (_contentType == 'photo') {
      return _selectedPhoto == null
          ? _buildPhotoSourceView()
          : _buildPhotoPreviewView(provider);
    }
    // _contentType == 'video'
    return _selectedVideo == null
        ? _buildVideoSourceView()
        : _buildVideoPreviewView(provider);
  }

  // ─── Vue initiale — sélection du type ───────────────────────────────────

  Widget _buildTypeSelectionView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_circle_outline,
            size: AppSpacing.kIconSizeHero,
            color: AppColors.kTextTertiary,
          ),
          const SizedBox(height: AppSpacing.kSpaceLg),
          Text(
            'Que voulez-vous publier ?',
            style: AppTextStyles.kTitleLarge,
          ),
          const SizedBox(height: AppSpacing.kSpaceXl),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () => setState(() => _contentType = 'photo'),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Photo'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.kPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.kSpaceMd),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () => setState(() => _contentType = 'video'),
              icon: const Icon(Icons.videocam_outlined),
              label: const Text('Vidéo'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.kPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Vue source photo ────────────────────────────────────────────────────

  Widget _buildPhotoSourceView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_camera_outlined,
            size: AppSpacing.kIconSizeHero,
            color: AppColors.kTextTertiary,
          ),
          const SizedBox(height: AppSpacing.kSpaceLg),
          Text(
            'Sélectionnez une photo',
            style: AppTextStyles.kTitleLarge,
          ),
          const SizedBox(height: AppSpacing.kSpaceSm),
          Text(
            'JPEG, PNG ou WEBP — 10 Mo max',
            style: AppTextStyles.kCaption,
          ),
          const SizedBox(height: AppSpacing.kSpaceXl),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Galerie'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.kPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.kSpaceMd),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Appareil photo'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.kPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.kSpaceMd),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => setState(() => _contentType = null),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.kTextSecondary,
                side: BorderSide(color: AppColors.kTextSecondary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
                ),
              ),
              child: const Text('Retour'),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Vue source vidéo ────────────────────────────────────────────────────

  Widget _buildVideoSourceView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: AppSpacing.kIconSizeHero,
            color: AppColors.kTextTertiary,
          ),
          const SizedBox(height: AppSpacing.kSpaceLg),
          Text(
            'Sélectionnez une vidéo',
            style: AppTextStyles.kTitleLarge,
          ),
          const SizedBox(height: AppSpacing.kSpaceSm),
          Text(
            'MP4 ou MOV — 50 Mo max',
            style: AppTextStyles.kCaption,
          ),
          const SizedBox(height: AppSpacing.kSpaceXl),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _pickVideo,
              icon: const Icon(Icons.video_library_outlined),
              label: const Text('Galerie vidéo'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.kPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.kSpaceMd),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => setState(() => _contentType = null),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.kTextSecondary,
                side: BorderSide(color: AppColors.kTextSecondary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
                ),
              ),
              child: const Text('Retour'),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Preview photo ───────────────────────────────────────────────────────

  Widget _buildPhotoPreviewView(ContentProvider provider) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: Image.file(
                  _selectedPhoto!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.kSpaceMd),
        if (provider.isLoading) ...[
          LinearProgressIndicator(
            value: provider.uploadProgress,
            color: AppColors.kPrimary,
            backgroundColor: AppColors.kOutline,
          ),
          const SizedBox(height: AppSpacing.kSpaceSm),
          Text(
            provider.uploadProgress != null
                ? 'Téléchargement en cours... ${(provider.uploadProgress! * 100).toInt()}%'
                : 'Téléchargement en cours...',
            style: AppTextStyles.kBodyMedium.copyWith(
              color: AppColors.kTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.kSpaceMd),
        ],
        if (!provider.isLoading) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _uploadPhoto,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.kPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
                ),
              ),
              child: const Text('Télécharger'),
            ),
          ),
          const SizedBox(height: AppSpacing.kSpaceSm),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _cancelPhotoSelection,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.kTextSecondary,
                side: BorderSide(color: AppColors.kTextSecondary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
                ),
              ),
              child: const Text('Annuler'),
            ),
          ),
        ],
      ],
    );
  }

  // ─── Preview vidéo ───────────────────────────────────────────────────────

  Widget _buildVideoPreviewView(ContentProvider provider) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: _videoThumbnail != null
                    ? Image.memory(_videoThumbnail!, fit: BoxFit.contain)
                    : Icon(
                        Icons.videocam,
                        size: AppSpacing.kIconSizeHero,
                        color: AppColors.kTextTertiary,
                      ),
              ),
            ),
          ),
        ),
        FutureBuilder<int>(
          future: _selectedVideo!.length(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final sizeInMb = snapshot.data! / (1024 * 1024);
            final fileName = _selectedVideo!.path.split('/').last;
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.kSpaceSm),
              child: Column(
                children: [
                  Text(
                    fileName,
                    style: AppTextStyles.kCaption.copyWith(
                      color: AppColors.kTextSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${sizeInMb.toStringAsFixed(1)} Mo',
                    style: AppTextStyles.kCaption.copyWith(
                      color: AppColors.kTextSecondary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.kSpaceMd),
        if (provider.isLoading) ...[
          LinearProgressIndicator(
            value: provider.uploadProgress,
            color: AppColors.kPrimary,
            backgroundColor: AppColors.kOutline,
          ),
          const SizedBox(height: AppSpacing.kSpaceSm),
          Text(
            provider.uploadProgress != null
                ? 'Téléchargement en cours... ${(provider.uploadProgress! * 100).toInt()}%'
                : 'Téléchargement en cours...',
            style: AppTextStyles.kBodyMedium.copyWith(
              color: AppColors.kTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.kSpaceMd),
        ],
        if (!provider.isLoading) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _uploadVideo,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.kPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
                ),
              ),
              child: const Text('Télécharger'),
            ),
          ),
          const SizedBox(height: AppSpacing.kSpaceSm),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _cancelVideoSelection,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.kTextSecondary,
                side: BorderSide(color: AppColors.kTextSecondary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
                ),
              ),
              child: const Text('Annuler'),
            ),
          ),
        ],
      ],
    );
  }
}
