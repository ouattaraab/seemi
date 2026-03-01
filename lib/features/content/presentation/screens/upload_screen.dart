import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
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
/// 3. Saisir le prix (montants suggérés ou libre)
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

  // ── État upload ──
  int? _uploadedContentId;

  // ── Pricing ──
  static const List<int> _presetAmounts = [100, 200, 500, 1000, 2000, 5000];
  int? _selectedPriceFcfa;
  final TextEditingController _priceCtrl = TextEditingController();
  bool _tosAccepted = false;
  String? _publishError;

  // ── Partage ──
  String? _shareUrl;

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  // ─── Sélection photo ─────────────────────────────────────────────────────

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
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked == null) return;
      final file = File(picked.path);
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

  Future<void> _pickVideo() async {
    try {
      final picked = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 300),
      );
      if (picked == null) return;
      final file = File(picked.path);
      if (!await _validateSize(file, 50, 'La vidéo dépasse 50 Mo')) return;
      final thumb = await VideoThumbnail.thumbnailData(
        video: file.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 1920,
        quality: 50,
      );
      setState(() {
        _selectedFile = file;
        _videoThumbnail = thumb;
      });
      await _startUpload();
    } catch (e) {
      _showSnack(
        'Impossible d\'accéder à la galerie vidéo. Vérifiez les permissions dans les paramètres.',
      );
    }
  }

  Future<bool> _validateSize(File file, double maxMb, String msg) async {
    final sizeMb = await file.length() / (1024 * 1024);
    if (sizeMb > maxMb) {
      _showSnack(msg);
      return false;
    }
    return true;
  }

  // ─── Upload ──────────────────────────────────────────────────────────────

  Future<void> _startUpload() async {
    if (_selectedFile == null) return;
    final provider = context.read<ContentProvider>();
    if (provider.isLoading) return;

    bool success;
    if (_contentType == 'photo') {
      success = await provider.uploadPhoto(_selectedFile!);
    } else {
      success = await provider.uploadVideo(_selectedFile!);
    }

    if (!mounted) return;
    if (success) {
      setState(() {
        _uploadedContentId = provider.lastUploadedContent?.id;
      });
    } else {
      _showSnack(provider.error ?? 'Erreur lors du téléchargement');
    }
  }

  Future<void> _retryUpload() async {
    context.read<ContentProvider>().resetUploadState();
    await _startUpload();
  }

  // ─── Publication ─────────────────────────────────────────────────────────

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
    );

    if (!mounted) return;
    if (success) {
      setState(() => _shareUrl = provider.lastPublishedContent?.shareUrl);
    } else {
      setState(
          () => _publishError = provider.error ?? 'Erreur lors de la publication');
    }
  }

  // ─── Partage ─────────────────────────────────────────────────────────────

  Future<void> _copyLink() async {
    if (_shareUrl == null) return;
    await Clipboard.setData(ClipboardData(text: _shareUrl!));
    if (mounted) {
      _showSnack('Lien copié dans le presse-papier !',
          bg: AppColors.kSuccess);
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
        SnackBar(
          content: const Text(
              'Permission contacts refusée. Activez-la dans les paramètres.'),
          action:
              SnackBarAction(label: 'Paramètres', onPressed: openAppSettings),
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

  // ─── Reset ───────────────────────────────────────────────────────────────

  void _reset() {
    context.read<ContentProvider>().resetUploadState();
    setState(() {
      _contentType = null;
      _selectedFile = null;
      _videoThumbnail = null;
      _uploadedContentId = null;
      _selectedPriceFcfa = null;
      _priceCtrl.clear();
      _tosAccepted = false;
      _publishError = null;
      _shareUrl = null;
    });
  }

  void _showSnack(String msg, {Color? bg}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: bg ?? AppColors.kError,
    ));
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgBase,
      body: Stack(
        children: [
          // Fond dégradé bleu profond
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A1628), AppColors.kBgBase],
              ),
            ),
          ),
          // Cercles de glow pour l'effet glass
          Positioned(
            top: -100,
            right: -60,
            child: _GlowCircle(
                size: 320, color: AppColors.kPrimary.withValues(alpha: 0.08)),
          ),
          Positioned(
            bottom: 150,
            left: -80,
            child: _GlowCircle(
                size: 260, color: AppColors.kPrimary.withValues(alpha: 0.05)),
          ),
          // Contenu principal
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: Consumer<ContentProvider>(
                    builder: (context, provider, _) => SingleChildScrollView(
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
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    String title;
    if (_shareUrl != null) {
      title = 'Lien généré !';
    } else if (_uploadedContentId != null) {
      title = 'Définir le prix';
    } else if (_selectedFile != null) {
      title = 'Chargement en cours...';
    } else {
      title = 'Publier un contenu';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.kSpaceMd,
        AppSpacing.kSpaceSm,
        AppSpacing.kSpaceMd,
        AppSpacing.kSpaceSm,
      ),
      child: Row(
        children: [
          _GlassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () {
              if (_shareUrl != null) {
                _reset();
              } else {
                Navigator.of(context).maybePop();
              }
            },
          ),
          const SizedBox(width: AppSpacing.kSpaceMd),
          Expanded(
            child: Text(title, style: AppTextStyles.kTitleLarge),
          ),
          if (_selectedFile != null && _shareUrl == null)
            _GlassIconButton(
              icon: Icons.close_rounded,
              onTap: _reset,
              color: AppColors.kError,
            ),
        ],
      ),
    );
  }

  Widget _buildContent(ContentProvider provider) {
    // Phase 1 : sélection du type (si aucun fichier ni type sélectionné)
    if (_contentType == null && _selectedFile == null) {
      return _buildTypeSelection();
    }

    // Phases 2-6 : fichier en cours ou sélectionné
    return Column(
      children: [
        // Section média (preview + progression)
        _buildMediaSection(provider),

        // Section pricing (apparaît après upload)
        AnimatedSize(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          child: _uploadedContentId != null && _shareUrl == null
              ? _buildPricingSection(provider)
              : const SizedBox.shrink(),
        ),

        // Section partage (apparaît après publication)
        AnimatedSize(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          child: _shareUrl != null
              ? _buildSharingSection()
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: AppSpacing.kSpaceMd),

        // Bouton d'action principal
        _buildActionButton(provider),

        const SizedBox(height: AppSpacing.kSpaceLg),
      ],
    );
  }

  // ─── Phase 1 : sélection du type ─────────────────────────────────────────

  Widget _buildTypeSelection() {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.kSpaceXl),
        Text(
          'Que voulez-vous publier ?',
          style: AppTextStyles.kHeadlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.kSpaceSm),
        Text(
          'Sélectionnez le type de contenu\npour commencer',
          style:
              AppTextStyles.kBodyMedium.copyWith(color: AppColors.kTextSecondary),
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
                subtitle: '50 Mo max',
                color: AppColors.kAccentViolet,
                onTap: _onVideoTypeTapped,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.kSpace2xl),
      ],
    );
  }

  // ─── Section média ────────────────────────────────────────────────────────

  Widget _buildMediaSection(ContentProvider provider) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
          child: SizedBox(
            height: 260,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Miniature ou image
                if (_contentType == 'photo' && _selectedFile != null)
                  Image.file(_selectedFile!, fit: BoxFit.cover)
                else if (_videoThumbnail != null)
                  Image.memory(_videoThumbnail!, fit: BoxFit.cover)
                else
                  Container(
                    color: AppColors.kBgElevated,
                    child: const Icon(Icons.videocam_rounded,
                        size: 60, color: AppColors.kTextTertiary),
                  ),

                // Overlay de chargement
                if (provider.isLoading) ...[
                  Container(color: Colors.black.withValues(alpha: 0.6)),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 52,
                          height: 52,
                          child: CircularProgressIndicator(
                            color: AppColors.kPrimary,
                            strokeWidth: 4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.uploadProgress != null
                              ? '${(provider.uploadProgress! * 100).toInt()}%'
                              : 'Chargement...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Veuillez patienter...',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],

                // Badge "Chargé" après upload
                if (_uploadedContentId != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.kSuccess,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.kSuccess.withValues(alpha: 0.4),
                            blurRadius: 8,
                          )
                        ],
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

                // Type badge
                if (_uploadedContentId == null && !provider.isLoading)
                  Positioned(
                    top: 12,
                    left: 12,
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

        // Barre de progression upload
        if (provider.isLoading && provider.uploadProgress != null) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: provider.uploadProgress,
              color: AppColors.kPrimary,
              backgroundColor: AppColors.kOutline,
              minHeight: 5,
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.kSpaceMd),
      ],
    );
  }

  // ─── Section pricing ──────────────────────────────────────────────────────

  Widget _buildPricingSection(ContentProvider provider) {
    return Column(
      children: [
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.kPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.attach_money_rounded,
                        color: AppColors.kPrimary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text('Prix de déverrouillage',
                      style: AppTextStyles.kTitleLarge),
                ],
              ),
              const SizedBox(height: 20),

              // Montants suggérés
              Text(
                'Montants suggérés',
                style: AppTextStyles.kBodyMedium
                    .copyWith(color: AppColors.kTextSecondary),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _presetAmounts.map((amount) {
                  final isSelected = _selectedPriceFcfa == amount &&
                      _priceCtrl.text.isEmpty;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedPriceFcfa = amount;
                      _priceCtrl.clear();
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.kPrimary
                            : AppColors.kPrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.kPrimary
                              : AppColors.kPrimary.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.kPrimary.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        '$amount F',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.kPrimaryLight,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Montant personnalisé
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Autre montant (min. 100 FCFA)',
                  suffixText: 'FCFA',
                  suffixStyle: const TextStyle(
                    color: AppColors.kPrimaryLight,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.07),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.kRadiusMd),
                    borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.kRadiusMd),
                    borderSide: const BorderSide(
                        color: AppColors.kPrimary, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.kRadiusMd),
                    borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 18),
                  hintStyle: TextStyle(
                      color: AppColors.kTextTertiary, fontSize: 15),
                ),
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  setState(() {
                    _selectedPriceFcfa =
                        (parsed != null && parsed >= 100) ? parsed : null;
                  });
                },
              ),

              // Prix sélectionné
              if (_selectedPriceFcfa != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.kSuccess.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.kSuccess.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    'Prix sélectionné : $_selectedPriceFcfa FCFA',
                    style: const TextStyle(
                      color: AppColors.kSuccess,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

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
                      side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _tosAccepted = !_tosAccepted),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: RichText(
                          text: TextSpan(
                            style: AppTextStyles.kBodyMedium
                                .copyWith(color: AppColors.kTextSecondary),
                            children: [
                              const TextSpan(text: "J'accepte les "),
                              TextSpan(
                                text: 'conditions d\'utilisation',
                                style: TextStyle(
                                  color: AppColors.kPrimary,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const TextSpan(text: ' et la '),
                              TextSpan(
                                text: 'politique de confidentialité',
                                style: TextStyle(
                                  color: AppColors.kPrimary,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const TextSpan(text: ' de SeeMi.'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Erreur publication
              if (_publishError != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.kError.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.kError.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.kError, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _publishError!,
                          style: const TextStyle(
                              color: AppColors.kError, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.kSpaceMd),
      ],
    );
  }

  // ─── Section partage ──────────────────────────────────────────────────────

  Widget _buildSharingSection() {
    if (_shareUrl == null) return const SizedBox.shrink();
    return Column(
      children: [
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.kSuccess.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.check_circle_rounded,
                        color: AppColors.kSuccess, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Contenu publié !',
                          style: AppTextStyles.kTitleLarge),
                      Text(
                        '$_selectedPriceFcfa FCFA pour déverrouiller',
                        style: AppTextStyles.kCaption,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                'Lien de partage',
                style: AppTextStyles.kBodyMedium
                    .copyWith(color: AppColors.kTextSecondary),
              ),
              const SizedBox(height: 8),

              // Lien cliquable + copier
              GestureDetector(
                onTap: _copyLink,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.kPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.kPrimary.withValues(alpha: 0.3)),
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
                            color: AppColors.kPrimaryLight,
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

              const SizedBox(height: 16),

              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: _ShareActionButton(
                      icon: Icons.copy_rounded,
                      label: 'Copier',
                      color: AppColors.kPrimary,
                      onTap: _copyLink,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ShareActionButton(
                      icon: Icons.share_rounded,
                      label: 'Partager',
                      color: AppColors.kPrimary,
                      onTap: _shareLink,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ShareActionButton(
                      icon: Icons.contacts_rounded,
                      label: 'Contact',
                      color: AppColors.kAccentViolet,
                      onTap: _shareToContact,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.kSpaceMd),
      ],
    );
  }

  // ─── Bouton d'action principal ────────────────────────────────────────────

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
                  color: AppColors.kPrimary,
                  backgroundColor: AppColors.kOutline,
                  minHeight: 4,
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: AppSpacing.kButtonHeight,
            child: FilledButton.icon(
              onPressed: _canPublish && !provider.isPublishing
                  ? _doPublish
                  : null,
              icon: provider.isPublishing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Icon(Icons.link_rounded, size: 22),
              label: Text(provider.isPublishing
                  ? 'Publication en cours...'
                  : 'Générer le lien'),
              style: FilledButton.styleFrom(
                disabledBackgroundColor:
                    AppColors.kPrimary.withValues(alpha: 0.35),
                disabledForegroundColor: Colors.white54,
              ),
            ),
          ),
          if (!_canPublish) ...[
            const SizedBox(height: 8),
            Text(
              _selectedPriceFcfa == null
                  ? 'Sélectionnez un prix pour continuer'
                  : 'Acceptez les CGU pour continuer',
              style: AppTextStyles.kCaption,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      );
    }

    // Erreur upload : bouton réessayer
    if (provider.error != null && _selectedFile != null && !provider.isLoading) {
      return SizedBox(
        width: double.infinity,
        height: AppSpacing.kButtonHeight,
        child: FilledButton.icon(
          onPressed: _retryUpload,
          icon: const Icon(Icons.refresh_rounded, size: 22),
          label: const Text('Réessayer'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.kError),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

// ─── Widgets privés ───────────────────────────────────────────────────────────

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
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 36),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.10),
                  Colors.white.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
              border: Border.all(
                  color: color.withValues(alpha: 0.25), width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 44, color: color),
                ),
                const SizedBox(height: 16),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
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

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.kSpaceLg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.10),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.13), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Icon(
              icon,
              color: color ?? Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourcePickerSheet extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  const _SourcePickerSheet({required this.onGallery, required this.onCamera});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1C35),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
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
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Choisir la source',
              style: TextStyle(
                color: Colors.white,
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
                child: Text(
                  'Annuler',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 16,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppColors.kPrimary),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
