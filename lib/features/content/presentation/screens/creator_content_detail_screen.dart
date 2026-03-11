import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/config/app_config.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/content/domain/content.dart';
import 'package:ppv_app/features/content/presentation/content_provider.dart';
import 'package:ppv_app/features/sharing/data/share_repository.dart';

/// Page de détail d'un contenu côté créateur.
///
/// Reçoit le [Content] via `GoRouter.extra`. Charge la liste des acheteurs
/// via [ContentProvider.getContentBuyers].
class CreatorContentDetailScreen extends StatefulWidget {
  final Content content;

  const CreatorContentDetailScreen({super.key, required this.content});

  @override
  State<CreatorContentDetailScreen> createState() =>
      _CreatorContentDetailScreenState();
}

class _CreatorContentDetailScreenState
    extends State<CreatorContentDetailScreen> {
  List<ContentBuyer> _buyers = [];
  bool _loadingBuyers = true;
  bool _loadingMore = false;
  String? _buyersError;
  String? _nextCursor;
  bool _hasMore = false;

  // F13 — Polling statut transcodage HLS
  String? _processingStatus;
  String? _hlsUrl;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadBuyers();
    // Initialiser avec la valeur de l'entité Content passée en paramètre
    _processingStatus = widget.content.processingStatus;
    _hlsUrl = widget.content.hlsUrl;
    // Démarrer le polling si le transcodage est en cours
    if (_shouldPoll(_processingStatus)) {
      _startPolling();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  bool _shouldPoll(String? status) =>
      status == 'uploading' || status == 'processing';

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!mounted) {
        _pollTimer?.cancel();
        return;
      }
      try {
        final result = await context
            .read<ContentProvider>()
            .getContentStatus(widget.content.id);
        if (!mounted) return;
        setState(() {
          _processingStatus = result.processingStatus;
          _hlsUrl = result.hlsUrl;
        });
        // Arrêter le polling si terminé ou en erreur
        if (!_shouldPoll(result.processingStatus)) {
          _pollTimer?.cancel();
        }
      } catch (_) {
        // Ignorer les erreurs de polling
      }
    });
  }

  Future<void> _shareContent() async {
    final slug = widget.content.slug;
    if (slug == null) return;
    final url = widget.content.shareUrl ??
        '${AppConfig.webBaseUrl}/c/$slug';
    await ShareRepositoryImpl().shareContent(url);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Supprimer ce contenu ?',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          'Cette action est irréversible. Le contenu sera supprimé et les acheteurs ne pourront plus y accéder.',
          style: TextStyle(fontFamily: 'Plus Jakarta Sans'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.kError,
              shape: const StadiumBorder(),
            ),
            child: const Text(
              'Supprimer',
              style: TextStyle(fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final success = await context
        .read<ContentProvider>()
        .deleteContent(widget.content.id);

    if (!mounted) return;
    if (success) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contenu supprimé.'),
          backgroundColor: AppColors.kSuccess,
        ),
      );
    } else {
      final err = context.read<ContentProvider>().deleteContentError
          ?? 'Erreur lors de la suppression.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.kError),
      );
    }
  }

  Future<void> _loadBuyers() async {
    setState(() {
      _loadingBuyers = true;
      _buyersError = null;
      _buyers = [];
      _nextCursor = null;
      _hasMore = false;
    });
    try {
      final result = await context
          .read<ContentProvider>()
          .getContentBuyers(widget.content.id);
      if (!mounted) return;
      setState(() {
        _buyers = result.buyers;
        _nextCursor = result.nextCursor;
        _hasMore = result.hasMore;
        _loadingBuyers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _buyersError = 'Impossible de charger les acheteurs.';
        _loadingBuyers = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _nextCursor == null) return;
    setState(() => _loadingMore = true);
    try {
      final result = await context
          .read<ContentProvider>()
          .getContentBuyers(widget.content.id, cursor: _nextCursor);
      if (!mounted) return;
      setState(() {
        _buyers = [..._buyers, ...result.buyers];
        _nextCursor = result.nextCursor;
        _hasMore = result.hasMore;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.content;
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
          'Détail du contenu',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.kTextPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
          // Bouton partager
          if (widget.content.slug != null)
            IconButton(
              icon: const Icon(Icons.share_rounded,
                  color: AppColors.kPrimary, size: 22),
              tooltip: 'Partager',
              onPressed: _shareContent,
            ),
          // Bouton supprimer
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.kError, size: 22),
            tooltip: 'Supprimer',
            onPressed: _confirmDelete,
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
              height: 1, color: AppColors.kBorder.withValues(alpha: 0.6)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          _buildContentCard(content),
          const SizedBox(height: 28),
          _buildStatsRow(content),
          const SizedBox(height: 28),
          _buildBuyersSection(),
        ],
      ),
    );
  }

  // ─── Content card ──────────────────────────────────────────────────────────

  Widget _buildContentCard(Content content) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kBgSurface,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
        border: Border.all(color: AppColors.kBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.kTextPrimary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image/thumbnail
          if (content.blurUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.kRadiusXl)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  content.blurUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _mediaPlaceholder(content.type),
                ),
              ),
            )
          else
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.kRadiusXl)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _mediaPlaceholder(content.type),
              ),
            ),
          // Infos
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badges
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _TypeBadge(type: content.type),
                    _StatusBadge(status: content.status),
                    if (content.isViewOnce) _ViewOnceBadge(),
                    // F13 — Badge statut transcodage HLS (vidéo uniquement)
                    if (content.type == 'video' && _processingStatus != null)
                      _ProcessingStatusBadge(
                        status: _processingStatus!,
                        isPolling: _shouldPoll(_processingStatus),
                        hlsUrl: _hlsUrl,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Slug
                Text(
                  content.slug ?? 'Contenu #${content.id}',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.kTextPrimary,
                  ),
                ),
                if (content.price != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${_fmt(content.price! ~/ 100)} FCFA',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.kAccent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: AppColors.kBgSurface,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (_) => _FlashSaleSheet(
                        contentId: content.id,
                        currentPriceFcfa: content.price! ~/ 100,
                      ),
                    ),
                    icon: const Icon(
                      Icons.local_fire_department_rounded,
                      size: 16,
                      color: Color(0xFFFF6B00),
                    ),
                    label: const Text(
                      'Flash Sale',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF6B00),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFF6B00)),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ],
                if (content.createdAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Publié le ${_formatDateFr(content.createdAt!)}',
                    style: AppTextStyles.kCaption
                        .copyWith(color: AppColors.kTextSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mediaPlaceholder(String type) {
    return Container(
      color: AppColors.kBgElevated,
      child: Center(
        child: Icon(
          type == 'video' ? Icons.videocam_outlined : Icons.image_outlined,
          size: 48,
          color: AppColors.kTextTertiary,
        ),
      ),
    );
  }

  // ─── Stats row ─────────────────────────────────────────────────────────────

  Widget _buildStatsRow(Content content) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.remove_red_eye_outlined,
            iconColor: AppColors.kPrimary,
            bgColor: AppColors.kPrimary.withValues(alpha: 0.10),
            label: 'Vues',
            value: '${content.viewCount}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.shopping_cart_outlined,
            iconColor: AppColors.kSuccess,
            bgColor: AppColors.kSuccess.withValues(alpha: 0.10),
            label: 'Ventes',
            value: '${content.purchaseCount}',
          ),
        ),
      ],
    );
  }

  // ─── Buyers section ────────────────────────────────────────────────────────

  Widget _buildBuyersSection() {
    final count = widget.content.purchaseCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Acheteurs', style: AppTextStyles.kTitleLarge),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.kPrimary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.kPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_loadingBuyers)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.kPrimary),
            ),
          )
        else if (_buyersError != null)
          _BuyersError(error: _buyersError!, onRetry: _loadBuyers)
        else if (_buyers.isEmpty)
          _BuyersEmpty()
        else ...[
          Container(
            decoration: BoxDecoration(
              color: AppColors.kBgSurface,
              borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
              border: Border.all(color: AppColors.kBorder),
              boxShadow: [
                BoxShadow(
                  color: AppColors.kTextPrimary.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                for (var i = 0; i < _buyers.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: AppColors.kBorder.withValues(alpha: 0.5),
                      indent: 20,
                      endIndent: 20,
                    ),
                  _BuyerRow(buyer: _buyers[i]),
                ],
              ],
            ),
          ),
          if (_hasMore) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _loadingMore ? null : _loadMore,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.kPrimary,
                  side: const BorderSide(color: AppColors.kBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.kRadiusLg),
                  ),
                ),
                child: _loadingMore
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.kPrimary,
                        ),
                      )
                    : Text(
                        'Voir plus (${count - _buyers.length} restants)',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

// ─── _StatCard ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.kBgSurface,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
        border: Border.all(color: AppColors.kBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.kTextPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(label,
              style: AppTextStyles.kCaption
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value,
              style: AppTextStyles.kHeadlineMedium
                  .copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// ─── _BuyerRow ────────────────────────────────────────────────────────────────

class _BuyerRow extends StatelessWidget {
  final ContentBuyer buyer;
  const _BuyerRow({required this.buyer});

  @override
  Widget build(BuildContext context) {
    final name = buyer.name ?? buyer.email ?? 'Acheteur anonyme';
    final sub = (buyer.name != null && buyer.email != null)
        ? buyer.email!
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Avatar initiale
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.kSuccess.withValues(alpha: 0.10),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: AppColors.kSuccess,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Nom / email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.kBodyMedium
                      .copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sub != null)
                  Text(sub,
                      style: AppTextStyles.kCaption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          // Montant + date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${_fmt(buyer.amountFcfa)} FCFA',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.kSuccess,
                ),
              ),
              Text(
                _formatDate(buyer.paidAt),
                style: AppTextStyles.kCaption.copyWith(fontSize: 11),
              ),
            ],
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
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  static String _formatDate(DateTime dt) => _formatDateFr(dt.toLocal());
}

// ─── _BuyersEmpty ─────────────────────────────────────────────────────────────

class _BuyersEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.kBgSurface,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.kBgElevated,
              ),
              child: const Icon(Icons.people_outline_rounded,
                  size: 22, color: AppColors.kTextTertiary),
            ),
            const SizedBox(height: 12),
            Text(
              'Aucun acheteur pour l\'instant',
              style: AppTextStyles.kBodyMedium
                  .copyWith(color: AppColors.kTextSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _BuyersError ─────────────────────────────────────────────────────────────

class _BuyersError extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _BuyersError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.kError.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
        border: Border.all(color: AppColors.kError.withValues(alpha: 0.20)),
      ),
      child: Column(
        children: [
          Text(error,
              style: AppTextStyles.kBodyMedium
                  .copyWith(color: AppColors.kTextSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: const Text('Réessayer',
                style: TextStyle(color: AppColors.kPrimary)),
          ),
        ],
      ),
    );
  }
}

// ─── Badges ───────────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final isVideo = type == 'video';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isVideo
            ? AppColors.kAccentViolet.withValues(alpha: 0.10)
            : AppColors.kPrimary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVideo ? Icons.videocam_rounded : Icons.image_rounded,
            size: 12,
            color: isVideo ? AppColors.kAccentViolet : AppColors.kPrimary,
          ),
          const SizedBox(width: 4),
          Text(
            isVideo ? 'Vidéo' : 'Photo',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isVideo ? AppColors.kAccentViolet : AppColors.kPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'active' => ('Actif', AppColors.kSuccess),
      'pending' => ('En attente', AppColors.kWarning),
      'rejected' => ('Rejeté', AppColors.kError),
      _ => (status, AppColors.kTextSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ViewOnceBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.kAccentViolet.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_off_outlined,
              size: 12, color: AppColors.kAccentViolet),
          SizedBox(width: 4),
          Text(
            'Vue unique',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.kAccentViolet,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _ProcessingStatusBadge ───────────────────────────────────────────────────

/// F13 — Badge indiquant le statut du transcodage HLS Bunny Stream.
///
/// Affiché uniquement pour les vidéos côté créateur.
/// Couleurs : uploading/processing = orange, done = vert, failed = rouge.
class _ProcessingStatusBadge extends StatelessWidget {
  final String status;
  final bool isPolling;
  /// URL HLS disponible quand status == 'done'
  final String? hlsUrl;

  const _ProcessingStatusBadge({
    required this.status,
    this.isPolling = false,
    this.hlsUrl,
  });

  @override
  Widget build(BuildContext context) {
    final doneLabel = hlsUrl != null ? 'Prêt (HLS)' : 'Prêt';
    final (label, color, icon) = switch (status) {
      'uploading'  => ('Envoi en cours…',         const Color(0xFFFF6B00), Icons.upload_rounded),
      'processing' => ('Traitement en cours…',    const Color(0xFFFF6B00), Icons.settings_rounded),
      'done'       => (doneLabel,                  AppColors.kSuccess,     Icons.check_circle_outline_rounded),
      'failed'     => ('Erreur transcodage',       AppColors.kError,       Icons.error_outline_rounded),
      _            => (status,                     AppColors.kTextSecondary, Icons.info_outline_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPolling)
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: color,
              ),
            )
          else
            Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

const _kMonths = [
  '', 'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
  'juil', 'août', 'sep', 'oct', 'nov', 'déc'
];

String _formatDateFr(DateTime dt) {
  final local = dt.toLocal();
  final month = _kMonths[local.month];
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '${local.day} $month ${local.year} · $h:$m';
}

String _fmt(int n) {
  if (n == 0) return '0';
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

// ─── _FlashSaleSheet ──────────────────────────────────────────────────────────

class _FlashSaleSheet extends StatefulWidget {
  final int contentId;
  final int currentPriceFcfa;
  const _FlashSaleSheet({
    required this.contentId,
    required this.currentPriceFcfa,
  });
  @override
  State<_FlashSaleSheet> createState() => _FlashSaleSheetState();
}

class _FlashSaleSheetState extends State<_FlashSaleSheet> {
  final _priceController = TextEditingController();
  int _selectedHours = 24;
  bool _loading = false;
  String? _error;

  final List<int> _durations = [1, 6, 12, 24, 48];

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _activate(BuildContext context) async {
    final price = int.tryParse(_priceController.text.trim());
    if (price == null || price <= 0 || price >= widget.currentPriceFcfa) {
      setState(() =>
          _error = 'Le prix flash doit être inférieur au prix normal');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<ContentProvider>().updateContent(
        widget.contentId,
        {
          'flash_price': price * 100,
          'flash_ends_at': DateTime.now()
              .add(Duration(hours: _selectedHours))
              .toIso8601String(),
        },
      );
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Flash sale activée !')),
      );
    } catch (_) {
      setState(() {
        _error = 'Impossible d\'activer la flash sale.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Flash Sale',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.kTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText:
                  'Prix flash (FCFA) — moins de ${widget.currentPriceFcfa} FCFA',
              border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.kRadiusLg)),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Durée :',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w600,
              color: AppColors.kTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _durations.map((h) {
              final selected = _selectedHours == h;
              return GestureDetector(
                onTap: () => setState(() => _selectedHours = h),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.kPrimary
                        : AppColors.kBgSurface,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.kRadiusPill),
                    border: Border.all(
                        color: selected
                            ? AppColors.kPrimary
                            : AppColors.kBorder),
                  ),
                  child: Text(
                    '${h}h',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? Colors.white
                          : AppColors.kTextSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(
                  color: AppColors.kError, fontSize: 13),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: AppSpacing.kButtonHeight,
            child: FilledButton(
              onPressed: _loading ? null : () => _activate(context),
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  shape: const StadiumBorder()),
              child: _loading
                  ? const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)
                  : const Text(
                      'Activer la Flash Sale',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
