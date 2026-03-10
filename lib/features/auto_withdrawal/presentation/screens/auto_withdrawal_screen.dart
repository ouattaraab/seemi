import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/auto_withdrawal/presentation/auto_withdrawal_provider.dart';

class AutoWithdrawalScreen extends StatefulWidget {
  const AutoWithdrawalScreen({super.key});

  @override
  State<AutoWithdrawalScreen> createState() => _AutoWithdrawalScreenState();
}

class _AutoWithdrawalScreenState extends State<AutoWithdrawalScreen> {
  String _triggerType = 'schedule';
  String _scheduleDay = 'monday';
  final _thresholdController = TextEditingController();
  final _minController = TextEditingController(text: '5000');

  final List<String> _days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];
  final Map<String, String> _dayLabels = {
    'monday': 'Lundi',
    'tuesday': 'Mardi',
    'wednesday': 'Mercredi',
    'thursday': 'Jeudi',
    'friday': 'Vendredi',
    'saturday': 'Samedi',
    'sunday': 'Dimanche',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<AutoWithdrawalProvider>();
      await provider.load();
      if (!mounted) return;
      final rule = provider.rule;
      if (rule != null) {
        setState(() {
          _triggerType = rule.triggerType;
          _scheduleDay = rule.scheduleDay ?? 'monday';
          if (rule.thresholdAmountFcfa != null) {
            _thresholdController.text = '${rule.thresholdAmountFcfa}';
          }
          _minController.text = '${rule.minWithdrawAmountFcfa}';
        });
      }
    });
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    _minController.dispose();
    super.dispose();
  }

  Future<void> _save(AutoWithdrawalProvider provider) async {
    await provider.save(
      triggerType: _triggerType,
      scheduleDay: _triggerType == 'schedule' ? _scheduleDay : null,
      thresholdFcfa: _triggerType == 'threshold'
          ? int.tryParse(_thresholdController.text)
          : null,
      minFcfa: int.tryParse(_minController.text),
    );
    if (!mounted) return;
    if (provider.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Règle sauvegardée !')),
      );
    }
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.kTextPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Retrait automatique',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 18,
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
      body: Consumer<AutoWithdrawalProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.kPrimary),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.kPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.kPrimary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Retirez automatiquement vos gains chaque semaine ou dès qu\'un seuil est atteint.',
                          style: AppTextStyles.kCaption
                              .copyWith(color: AppColors.kPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Type de déclencheur', style: AppTextStyles.kTitleLarge),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _TriggerOption(
                        label: 'Planifié',
                        icon: Icons.calendar_today_rounded,
                        selected: _triggerType == 'schedule',
                        onTap: () => setState(() => _triggerType = 'schedule'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TriggerOption(
                        label: 'Seuil',
                        icon: Icons.account_balance_wallet_rounded,
                        selected: _triggerType == 'threshold',
                        onTap: () =>
                            setState(() => _triggerType = 'threshold'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_triggerType == 'schedule') ...[
                  Text('Jour du retrait', style: AppTextStyles.kTitleLarge),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _days.map((d) {
                      final selected = _scheduleDay == d;
                      return GestureDetector(
                        onTap: () => setState(() => _scheduleDay = d),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.kPrimary
                                : AppColors.kBgSurface,
                            borderRadius: BorderRadius.circular(
                                AppSpacing.kRadiusPill),
                            border: Border.all(
                              color: selected
                                  ? AppColors.kPrimary
                                  : AppColors.kBorder,
                            ),
                          ),
                          child: Text(
                            _dayLabels[d]!,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: selected
                                  ? Colors.white
                                  : AppColors.kTextSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ] else ...[
                  Text(
                    'Seuil de déclenchement',
                    style: AppTextStyles.kTitleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _thresholdController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Déclencher quand balance ≥ X FCFA',
                      suffixText: 'FCFA',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.kRadiusLg),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Montant minimum par retrait',
                  style: AppTextStyles.kTitleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _minController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Minimum (FCFA)',
                    suffixText: 'FCFA',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.kRadiusLg),
                    ),
                  ),
                ),
                if (provider.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    provider.error!,
                    style: const TextStyle(color: AppColors.kError),
                  ),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: AppSpacing.kButtonHeight,
                  child: FilledButton(
                    onPressed:
                        provider.isSaving ? null : () => _save(provider),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.kPrimary,
                      shape: const StadiumBorder(),
                    ),
                    child: provider.isSaving
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : const Text(
                            'Sauvegarder',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
                if (provider.rule != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: AppSpacing.kButtonHeight,
                    child: OutlinedButton(
                      onPressed: () => provider.disable(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.kError,
                        side: BorderSide(
                          color: AppColors.kError.withValues(alpha: 0.5),
                        ),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        'Désactiver le retrait automatique',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TriggerOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TriggerOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.kPrimary.withValues(alpha: 0.08)
              : AppColors.kBgSurface,
          borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
          border: Border.all(
            color: selected ? AppColors.kPrimary : AppColors.kBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color:
                  selected ? AppColors.kPrimary : AppColors.kTextSecondary,
              size: 22,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected
                    ? AppColors.kPrimary
                    : AppColors.kTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
