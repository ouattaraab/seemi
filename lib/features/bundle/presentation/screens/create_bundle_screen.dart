import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/bundle/data/bundle_repository.dart';
import 'package:ppv_app/features/bundle/presentation/create_bundle_provider.dart';
import 'package:ppv_app/features/content/domain/content.dart';
import 'package:ppv_app/features/content/presentation/content_provider.dart';

/// Écran de création d'un bundle.
///
/// Nécessite [CreateBundleProvider] et [ContentProvider] dans l'arbre.
class CreateBundleScreen extends StatefulWidget {
  const CreateBundleScreen({super.key});

  @override
  State<CreateBundleScreen> createState() => _CreateBundleScreenState();
}

class _CreateBundleScreenState extends State<CreateBundleScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ContentProvider>().loadMyContents(refresh: true);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgBase,
      appBar: AppBar(
        backgroundColor: AppColors.kBgBase,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.kTextPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Créer un bundle',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.kTextPrimary,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
              height: 1, color: AppColors.kBorder.withValues(alpha: 0.6)),
        ),
      ),
      body: Consumer<CreateBundleProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Titre ──────────────────────────────────────────────
                  _SectionLabel(label: 'Titre du bundle *'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    onChanged: provider.setTitle,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      color: AppColors.kTextPrimary,
                    ),
                    decoration: _inputDecoration('Ex : Pack Exclusif Été 2024'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Titre obligatoire' : null,
                  ),
                  const SizedBox(height: 20),
                  // ── Description ────────────────────────────────────────
                  _SectionLabel(label: 'Description (optionnel)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descController,
                    onChanged: provider.setDescription,
                    maxLines: 3,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      color: AppColors.kTextPrimary,
                    ),
                    decoration:
                        _inputDecoration('Décrivez ce que contient ce bundle…'),
                  ),
                  const SizedBox(height: 24),
                  // ── Remise ─────────────────────────────────────────────
                  _SectionLabel(label: 'Remise'),
                  const SizedBox(height: 10),
                  _DiscountChips(
                    selected: provider.discountPercent,
                    onSelected: provider.setDiscountPercent,
                  ),
                  const SizedBox(height: 24),
                  // ── Sélection des contenus ─────────────────────────────
                  _SectionLabel(label: 'Contenus inclus *'),
                  const SizedBox(height: 4),
                  Text(
                    '${provider.selectedContentIds.length} sélectionné(s)',
                    style: AppTextStyles.kCaption,
                  ),
                  const SizedBox(height: 12),
                  Consumer<ContentProvider>(
                    builder: (ctx, contentProv, _) {
                      if (contentProv.isFetchingContents &&
                          contentProv.myContents.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(
                                color: AppColors.kPrimary),
                          ),
                        );
                      }
                      if (contentProv.myContents.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.kBgSurface,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.kRadiusLg),
                            border: Border.all(color: AppColors.kBorder),
                          ),
                          child: Center(
                            child: Text(
                              'Aucun contenu disponible. Uploadez du contenu d\'abord.',
                              style: AppTextStyles.kBodyMedium
                                  .copyWith(color: AppColors.kTextSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      return _MultiSelectContentList(
                        contents: contentProv.myContents,
                        selectedIds: provider.selectedContentIds,
                        onToggle: provider.toggleContent,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // ── Preview prix ───────────────────────────────────────
                  Consumer<ContentProvider>(
                    builder: (ctx, contentProv, _) {
                      return _PricePreviewCard(
                        contents: contentProv.myContents,
                        selectedIds: provider.selectedContentIds,
                        discountPercent: provider.discountPercent,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // ── Erreur ─────────────────────────────────────────────
                  if (provider.error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.kError.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.kRadiusMd),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppColors.kError, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              provider.error!,
                              style: AppTextStyles.kCaption
                                  .copyWith(color: AppColors.kError),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // ── Bouton créer ───────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: AppSpacing.kButtonHeight,
                    child: FilledButton(
                      onPressed:
                          provider.isSaving ? null : () => _submit(context, provider),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.kPrimary,
                        disabledBackgroundColor:
                            AppColors.kPrimary.withValues(alpha: 0.4),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: provider.isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text('Créer le bundle'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit(
      BuildContext context, CreateBundleProvider provider) async {
    if (!_formKey.currentState!.validate()) return;

    final repo = BundleRepositoryImpl();
    final bundle = await provider.save(repo);

    if (!context.mounted) return;
    if (bundle != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bundle créé avec succès !'),
          backgroundColor: AppColors.kSuccess,
        ),
      );
      context.pop(true); // retourne true pour signaler un refresh
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        color: AppColors.kTextTertiary,
        fontSize: 14,
      ),
      filled: true,
      fillColor: AppColors.kBgSurface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.kBorder),
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.kPrimary, width: 1.5),
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.kError),
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.kError, width: 1.5),
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
      ),
    );
  }
}

// ─── _SectionLabel ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.kBodyMedium.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

// ─── _DiscountChips ───────────────────────────────────────────────────────────

class _DiscountChips extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  const _DiscountChips({required this.selected, required this.onSelected});

  static const _values = [0, 5, 10, 15, 20];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: _values.map((v) {
        final isSelected = selected == v;
        return GestureDetector(
          onTap: () => onSelected(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.kPrimary
                  : AppColors.kBgSurface,
              borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
              border: Border.all(
                color: isSelected ? AppColors.kPrimary : AppColors.kBorder,
              ),
            ),
            child: Text(
              v == 0 ? 'Aucune' : '-$v%',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color:
                    isSelected ? Colors.white : AppColors.kTextSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── _MultiSelectContentList ──────────────────────────────────────────────────

class _MultiSelectContentList extends StatelessWidget {
  final List<Content> contents;
  final List<int> selectedIds;
  final void Function(int id, bool selected) onToggle;

  const _MultiSelectContentList({
    required this.contents,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kBgSurface,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < contents.length; i++) ...[
            if (i > 0)
              Divider(
                  height: 1,
                  color: AppColors.kBorder.withValues(alpha: 0.5),
                  indent: 16,
                  endIndent: 16),
            _ContentCheckTile(
              content: contents[i],
              isSelected: selectedIds.contains(contents[i].id),
              onToggle: (selected) => onToggle(contents[i].id, selected),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContentCheckTile extends StatelessWidget {
  final Content content;
  final bool isSelected;
  final ValueChanged<bool> onToggle;

  const _ContentCheckTile({
    required this.content,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onToggle(!isSelected),
      borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.kRadiusSm),
              child: SizedBox(
                width: 52,
                height: 52,
                child: content.blurUrl != null
                    ? Image.network(
                        content.blurUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _placeholder(content.type),
                      )
                    : _placeholder(content.type),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.slug ?? 'Contenu #${content.id}',
                    style: AppTextStyles.kBodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        content.type == 'video'
                            ? Icons.videocam_rounded
                            : Icons.image_rounded,
                        size: 12,
                        color: AppColors.kTextTertiary,
                      ),
                      const SizedBox(width: 4),
                      if (content.price != null)
                        Text(
                          '${_fmt(content.price! ~/ 100)} FCFA',
                          style: AppTextStyles.kCaption.copyWith(
                            color: AppColors.kAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Checkbox(
              value: isSelected,
              onChanged: (v) => onToggle(v ?? false),
              activeColor: AppColors.kPrimary,
              side: const BorderSide(color: AppColors.kBorder, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(String type) {
    return Container(
      color: AppColors.kBgElevated,
      child: Icon(
        type == 'video' ? Icons.videocam_outlined : Icons.image_outlined,
        size: 22,
        color: AppColors.kTextTertiary,
      ),
    );
  }

  static String _fmt(int n) {
    if (n == 0) return '0';
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('\u202F');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ─── _PricePreviewCard ────────────────────────────────────────────────────────

class _PricePreviewCard extends StatelessWidget {
  final List<Content> contents;
  final List<int> selectedIds;
  final int discountPercent;

  const _PricePreviewCard({
    required this.contents,
    required this.selectedIds,
    required this.discountPercent,
  });

  @override
  Widget build(BuildContext context) {
    final selected =
        contents.where((c) => selectedIds.contains(c.id)).toList();
    if (selected.isEmpty) return const SizedBox.shrink();

    int totalCentimes = 0;
    for (final c in selected) {
      totalCentimes += c.price ?? 0;
    }
    final totalFcfa = totalCentimes ~/ 100;
    final discountedFcfa =
        (totalFcfa * (1 - discountPercent / 100)).round();
    final hasDiscount = discountPercent > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
        border: Border.all(color: AppColors.kPrimary.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_rounded,
              color: AppColors.kPrimary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${selected.length} contenu${selected.length > 1 ? 's' : ''} sélectionné${selected.length > 1 ? 's' : ''}',
                  style: AppTextStyles.kCaption
                      .copyWith(color: AppColors.kPrimary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (hasDiscount) ...[
                      Text(
                        '${_fmt(totalFcfa)} FCFA',
                        style: AppTextStyles.kCaption.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.kTextTertiary,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      '${_fmt(discountedFcfa)} FCFA',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.kPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(int n) {
    if (n == 0) return '0';
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('\u202F');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
