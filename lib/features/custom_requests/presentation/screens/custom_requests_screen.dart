import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/custom_requests/data/custom_request_repository.dart';
import 'package:provider/provider.dart';

class CustomRequestsScreen extends StatefulWidget {
  const CustomRequestsScreen({super.key});

  @override
  State<CustomRequestsScreen> createState() => _CustomRequestsScreenState();
}

class _CustomRequestsScreenState extends State<CustomRequestsScreen> {
  List<CustomRequest> _requests = [];
  bool _loading = true;
  String? _error;
  final Set<int> _processingIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final data = await context.read<CustomRequestRepository>().getRequests();
      if (mounted) setState(() { _requests = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Impossible de charger les demandes. Réessayez.'; _loading = false; });
    }
  }

  Future<void> _handleAction(int id, Future<void> Function() action) async {
    if (_processingIds.contains(id)) return;
    if (mounted) setState(() => _processingIds.add(id));
    try {
      await action();
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action impossible. Réessayez.')),
      );
    } finally {
      if (mounted) setState(() => _processingIds.remove(id));
    }
  }

  Color _statusColor(String status) => switch (status) {
        'delivered' => AppColors.kSuccess,
        'cancelled' || 'disputed' => AppColors.kError,
        'accepted' || 'in_progress' => AppColors.kPrimary,
        _ => AppColors.kWarning,
      };

  String _statusLabel(String status) => switch (status) {
        'pending_payment' => 'En attente paiement',
        'paid' => 'Payé',
        'accepted' => 'Accepté',
        'in_progress' => 'En cours',
        'delivered' => 'Livré',
        'cancelled' => 'Annulé',
        'disputed' => 'Litige',
        _ => status,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgBase,
      appBar: AppBar(
        backgroundColor: AppColors.kBgBase,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.kTextPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Demandes personnalisées',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.kTextPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: AppColors.kBorder.withValues(alpha: 0.6),
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.kPrimary),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        style: AppTextStyles.kBodyMedium
                            .copyWith(color: AppColors.kTextSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
          : _requests.isEmpty
              ? Center(
                  child: Text(
                    'Aucune demande pour l\'instant.',
                    style: AppTextStyles.kBodyMedium
                        .copyWith(color: AppColors.kTextSecondary),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final r = _requests[i];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.kBgSurface,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.kRadiusLg),
                          border: Border.all(color: AppColors.kBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  r.role == 'creator'
                                      ? 'De : ${r.fanName ?? '?'}'
                                      : 'À : ${r.creatorName ?? '?'}',
                                  style: AppTextStyles.kBodyMedium
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(r.status)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.kRadiusPill),
                                  ),
                                  child: Text(
                                    _statusLabel(r.status),
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _statusColor(r.status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              r.description,
                              style: AppTextStyles.kBodyMedium.copyWith(
                                color: AppColors.kTextSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${r.agreedPriceFcfa} FCFA',
                              style: AppTextStyles.kBodyMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.kSuccess,
                              ),
                            ),
                            if (r.role == 'creator' &&
                                r.status == 'paid') ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _processingIds.contains(r.id)
                                          ? null
                                          : () => _handleAction(r.id, () => context.read<CustomRequestRepository>().accept(r.id)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.kSuccess,
                                        side: BorderSide(
                                          color: AppColors.kSuccess
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                      child: _processingIds.contains(r.id)
                                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                          : const Text('Accepter'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _processingIds.contains(r.id)
                                          ? null
                                          : () => _handleAction(r.id, () => context.read<CustomRequestRepository>().reject(r.id)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.kError,
                                        side: BorderSide(
                                          color: AppColors.kError
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                      child: _processingIds.contains(r.id)
                                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                          : const Text('Refuser'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
