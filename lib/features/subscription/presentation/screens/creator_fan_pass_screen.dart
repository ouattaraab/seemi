import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/subscription/data/subscription_repository.dart';
import 'package:provider/provider.dart';

class CreatorFanPassScreen extends StatefulWidget {
  const CreatorFanPassScreen({super.key});

  @override
  State<CreatorFanPassScreen> createState() => _CreatorFanPassScreenState();
}

class _CreatorFanPassScreenState extends State<CreatorFanPassScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<SubscriptionTier> _tiers = [];
  List<FanSubscriber> _subscribers = [];
  bool _loadingTiers = true;
  bool _loadingSubscribers = true;
  String? _tiersError;
  String? _subscribersError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTiers();
      _loadSubscribers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTiers() async {
    setState(() {
      _loadingTiers = true;
      _tiersError = null;
    });
    try {
      _tiers = await context.read<SubscriptionRepository>().getMyTiers();
    } catch (_) {
      _tiersError = 'Impossible de charger vos niveaux.';
    } finally {
      if (mounted) setState(() => _loadingTiers = false);
    }
  }

  Future<void> _loadSubscribers() async {
    setState(() {
      _loadingSubscribers = true;
      _subscribersError = null;
    });
    try {
      _subscribers = await context.read<SubscriptionRepository>().getMySubscribers();
    } catch (_) {
      _subscribersError = 'Impossible de charger vos abonnés.';
    } finally {
      if (mounted) setState(() => _loadingSubscribers = false);
    }
  }

  Future<void> _toggleTier(SubscriptionTier tier) async {
    try {
      await context.read<SubscriptionRepository>().setTierActive(tier.id, isActive: !tier.isActive);
      await _loadTiers();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de modifier le niveau.')),
      );
    }
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.kBgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CreateTierSheet(
        repository: _repo,
        canCreate: _tiers.where((t) => t.isActive).length < 3,
        onCreated: _loadTiers,
      ),
    );
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
          'Fan Pass',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.kTextPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.kPrimary, size: 26),
            tooltip: 'Créer un niveau',
            onPressed: _showCreateSheet,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(children: [
            Divider(height: 1, color: AppColors.kBorder.withValues(alpha: 0.6)),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.kPrimary,
              unselectedLabelColor: AppColors.kTextSecondary,
              indicatorColor: AppColors.kPrimary,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans', fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans', fontSize: 13, fontWeight: FontWeight.w500),
              tabs: [
                Tab(text: 'Niveaux (${_tiers.length})'),
                Tab(text: 'Abonnés (${_subscribers.length})'),
              ],
            ),
          ]),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TiersTab(
            tiers: _tiers,
            loading: _loadingTiers,
            error: _tiersError,
            onRetry: _loadTiers,
            onToggle: _toggleTier,
            onCreateTap: _showCreateSheet,
          ),
          _SubscribersTab(
            subscribers: _subscribers,
            loading: _loadingSubscribers,
            error: _subscribersError,
            onRetry: _loadSubscribers,
          ),
        ],
      ),
    );
  }
}

// ── Onglet Niveaux ──────────────────────────────────────────────────────────────

class _TiersTab extends StatelessWidget {
  final List<SubscriptionTier> tiers;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final Future<void> Function(SubscriptionTier) onToggle;
  final VoidCallback onCreateTap;

  const _TiersTab({
    required this.tiers,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onToggle,
    required this.onCreateTap,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.kPrimary));
    }
    if (error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(error!,
              style: AppTextStyles.kBodyMedium.copyWith(color: AppColors.kTextSecondary)),
          const SizedBox(height: 12),
          TextButton(
              onPressed: onRetry,
              child: const Text('Réessayer',
                  style: TextStyle(color: AppColors.kPrimary))),
        ]),
      );
    }
    if (tiers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 60, height: 60,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.kBgElevated),
              child: const Icon(Icons.card_membership_rounded,
                  size: 28, color: AppColors.kTextTertiary),
            ),
            const SizedBox(height: 16),
            const Text('Aucun niveau Fan Pass',
                style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans', fontSize: 16,
                    fontWeight: FontWeight.w700, color: AppColors.kTextPrimary)),
            const SizedBox(height: 6),
            Text(
              'Créez votre premier niveau pour permettre\nà vos fans de s\'abonner.',
              style: AppTextStyles.kBodyMedium.copyWith(color: AppColors.kTextSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreateTap,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Créer un niveau'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.kPrimary,
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w700),
              ),
            ),
          ]),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: tiers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _TierCard(tier: tiers[i], onToggle: onToggle),
    );
  }
}

class _TierCard extends StatefulWidget {
  final SubscriptionTier tier;
  final Future<void> Function(SubscriptionTier) onToggle;
  const _TierCard({required this.tier, required this.onToggle});

  @override
  State<_TierCard> createState() => _TierCardState();
}

class _TierCardState extends State<_TierCard> {
  bool _toggling = false;

  Future<void> _handleToggle() async {
    setState(() => _toggling = true);
    await widget.onToggle(widget.tier);
    if (mounted) setState(() => _toggling = false);
  }

  @override
  Widget build(BuildContext context) {
    final tier = widget.tier;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kBgSurface,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
        border: Border.all(
          color: tier.isActive
              ? AppColors.kBorder
              : AppColors.kBorder.withValues(alpha: 0.4),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(
              tier.name,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans', fontSize: 15,
                fontWeight: FontWeight.w800,
                color: tier.isActive ? AppColors.kTextPrimary : AppColors.kTextSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.kPrimary,
              borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
            ),
            child: Text(
              '${_fmt(tier.priceMonthlyFcfa)} F/mois',
              style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans', fontSize: 12,
                  fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ]),
        if (tier.description != null && tier.description!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(tier.description!,
              style: AppTextStyles.kBodyMedium.copyWith(color: AppColors.kTextSecondary)),
        ],
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.people_outline_rounded, size: 14, color: AppColors.kTextTertiary),
          const SizedBox(width: 4),
          Text('${tier.activeSubscribers} abonné(s)',
              style: AppTextStyles.kCaption.copyWith(color: AppColors.kTextSecondary)),
          if (tier.maxSubscribers != null)
            Text(' / ${tier.maxSubscribers} max',
                style: AppTextStyles.kCaption.copyWith(color: AppColors.kTextTertiary)),
          const Spacer(),
          Text(
            tier.isActive ? 'Actif' : 'Inactif',
            style: AppTextStyles.kCaption.copyWith(
              color: tier.isActive ? AppColors.kSuccess : AppColors.kTextTertiary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          _toggling
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.kPrimary))
              : GestureDetector(
                  onTap: _handleToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40, height: 22,
                    decoration: BoxDecoration(
                      color: tier.isActive ? AppColors.kSuccess : AppColors.kBgElevated,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: tier.isActive ? AppColors.kSuccess : AppColors.kBorder,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 200),
                        alignment: tier.isActive ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          width: 16, height: 16,
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle),
                        ),
                      ),
                    ),
                  ),
                ),
        ]),
      ]),
    );
  }
}

// ── Onglet Abonnés ──────────────────────────────────────────────────────────────

class _SubscribersTab extends StatelessWidget {
  final List<FanSubscriber> subscribers;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  const _SubscribersTab({
    required this.subscribers,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.kPrimary));
    }
    if (error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(error!,
              style: AppTextStyles.kBodyMedium.copyWith(color: AppColors.kTextSecondary)),
          const SizedBox(height: 12),
          TextButton(
              onPressed: onRetry,
              child: const Text('Réessayer',
                  style: TextStyle(color: AppColors.kPrimary))),
        ]),
      );
    }
    if (subscribers.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 60, height: 60,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: AppColors.kBgElevated),
            child: const Icon(Icons.people_outline_rounded,
                size: 28, color: AppColors.kTextTertiary),
          ),
          const SizedBox(height: 16),
          const Text('Aucun abonné actif',
              style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans', fontSize: 16,
                  fontWeight: FontWeight.w700, color: AppColors.kTextPrimary)),
          const SizedBox(height: 6),
          Text('Vos abonnés Fan Pass apparaîtront ici.',
              style: AppTextStyles.kBodyMedium.copyWith(color: AppColors.kTextSecondary)),
        ]),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: subscribers.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: AppColors.kBorder.withValues(alpha: 0.5)),
      itemBuilder: (_, i) {
        final sub = subscribers[i];
        final initials =
            (sub.subscriberName?.isNotEmpty == true) ? sub.subscriberName![0].toUpperCase() : '?';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.kPrimary.withValues(alpha: 0.12),
              backgroundImage:
                  sub.subscriberAvatar != null ? NetworkImage(sub.subscriberAvatar!) : null,
              child: sub.subscriberAvatar == null
                  ? Text(initials,
                      style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans', fontSize: 15,
                          fontWeight: FontWeight.w800, color: AppColors.kPrimary))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  sub.subscriberName ?? sub.subscriberUsername ?? 'Anonyme',
                  style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans', fontSize: 14,
                      fontWeight: FontWeight.w700, color: AppColors.kTextPrimary),
                ),
                if (sub.subscriberUsername != null)
                  Text('@${sub.subscriberUsername}',
                      style: AppTextStyles.kCaption.copyWith(color: AppColors.kTextSecondary)),
              ]),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.kPrimary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
                ),
                child: Text(
                  sub.tierName ?? 'Fan Pass',
                  style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans', fontSize: 11,
                      fontWeight: FontWeight.w700, color: AppColors.kPrimary),
                ),
              ),
              if (sub.expiresAt != null) ...[
                const SizedBox(height: 3),
                Text(
                  'exp. ${_fmtDate(sub.expiresAt!)}',
                  style: AppTextStyles.kCaption.copyWith(color: AppColors.kTextTertiary),
                ),
              ],
            ]),
          ]),
        );
      },
    );
  }

  String _fmtDate(DateTime dt) {
    const m = ['Jan','Fév','Mar','Avr','Mai','Jun','Jul','Aoû','Sep','Oct','Nov','Déc'];
    return '${dt.day} ${m[dt.month - 1]}';
  }
}

// ── Sheet création ──────────────────────────────────────────────────────────────

class _CreateTierSheet extends StatefulWidget {
  final SubscriptionRepository repository;
  final bool canCreate;
  final VoidCallback onCreated;

  const _CreateTierSheet({
    required this.repository,
    required this.canCreate,
    required this.onCreated,
  });

  @override
  State<_CreateTierSheet> createState() => _CreateTierSheetState();
}

class _CreateTierSheetState extends State<_CreateTierSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final price = int.tryParse(_priceCtrl.text.trim());
    if (name.isEmpty) {
      setState(() => _error = 'Le nom est requis.');
      return;
    }
    if (price == null || price < 1) {
      setState(() => _error = 'Prix invalide (minimum 1 FCFA).');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await widget.repository.createTier(
        name: name,
        description: desc.isEmpty ? null : desc,
        priceMonthlyFcfa: price,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onCreated();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de créer le niveau. Réessayez.';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.kBorder,
                borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
              ),
            ),
          ),
          const Text('Nouveau niveau Fan Pass',
              style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans', fontSize: 17,
                  fontWeight: FontWeight.w800, color: AppColors.kTextPrimary)),
          if (!widget.canCreate) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.kError.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
                border: Border.all(color: AppColors.kError.withValues(alpha: 0.3)),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline_rounded, color: AppColors.kError, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Limite de 3 niveaux actifs atteinte. Désactivez un niveau existant pour en créer un nouveau.',
                    style: TextStyle(fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13, color: AppColors.kError),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            _FullButton(
              label: 'Fermer',
              onPressed: () => Navigator.of(context).pop(),
              bgColor: AppColors.kBgElevated,
              textColor: AppColors.kTextPrimary,
            ),
          ] else ...[
            const SizedBox(height: 20),
            _SheetField(label: 'Nom du niveau', controller: _nameCtrl, hint: 'Ex : Fan, VIP…'),
            const SizedBox(height: 14),
            _SheetField(label: 'Description (optionnelle)', controller: _descCtrl,
                hint: 'Ce que les abonnés obtiennent…', maxLines: 3),
            const SizedBox(height: 14),
            _SheetField(label: 'Prix mensuel (FCFA)', controller: _priceCtrl,
                hint: 'Ex : 2000',
                inputType: const TextInputType.numberWithOptions(decimal: false, signed: false)),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: const TextStyle(color: AppColors.kError,
                      fontFamily: 'Plus Jakarta Sans', fontSize: 13)),
            ],
            const SizedBox(height: 20),
            _saving
                ? const Center(child: CircularProgressIndicator(color: AppColors.kPrimary))
                : _FullButton(label: 'Créer le niveau', onPressed: _save),
          ],
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType inputType;

  const _SheetField({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.inputType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: AppTextStyles.kCaption.copyWith(
              color: AppColors.kTextSecondary, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: inputType,
        style: const TextStyle(fontFamily: 'Plus Jakarta Sans',
            fontSize: 14, color: AppColors.kTextPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.kTextTertiary,
              fontFamily: 'Plus Jakarta Sans', fontSize: 14),
          filled: true,
          fillColor: AppColors.kBgElevated,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
            borderSide: const BorderSide(color: AppColors.kBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
            borderSide: const BorderSide(color: AppColors.kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
            borderSide: const BorderSide(color: AppColors.kPrimary, width: 1.5),
          ),
        ),
      ),
    ]);
  }
}

class _FullButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color bgColor;
  final Color textColor;

  const _FullButton({
    required this.label,
    required this.onPressed,
    this.bgColor = AppColors.kPrimary,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.kButtonHeight,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: bgColor,
          shape: const StadiumBorder(),
        ),
        child: Text(label,
            style: TextStyle(fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700, color: textColor)),
      ),
    );
  }
}

String _fmt(int n) {
  if (n == 0) return '0';
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('\u202F');
    buf.write(s[i]);
  }
  return buf.toString();
}
