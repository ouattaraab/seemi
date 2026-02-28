import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/payout/presentation/payout_method_provider.dart';

/// Écran de configuration du moyen de reversement.
class PayoutMethodScreen extends StatefulWidget {
  const PayoutMethodScreen({super.key});

  @override
  State<PayoutMethodScreen> createState() => _PayoutMethodScreenState();
}

class _PayoutMethodScreenState extends State<PayoutMethodScreen> {
  final _accountNumberController = TextEditingController();
  final _accountHolderNameController = TextEditingController();
  final _bankNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingData();
    });
  }

  Future<void> _loadExistingData() async {
    final provider = context.read<PayoutMethodProvider>();
    await provider.loadExistingPayoutMethod();
    final existing = provider.existingPayoutMethod;
    if (existing != null && mounted) {
      _accountHolderNameController.text = existing.accountHolderName;
      if (existing.bankName != null) {
        _bankNameController.text = existing.bankName!;
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountHolderNameController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  bool _isFormValid(PayoutMethodProvider provider) {
    final holderName = _accountHolderNameController.text.trim();
    final accountNumber = _accountNumberController.text.trim();

    if (holderName.isEmpty || accountNumber.isEmpty) return false;

    if (provider.selectedType == 'mobile_money') {
      return provider.isValidMobileMoneyNumber(accountNumber);
    } else {
      return _bankNameController.text.trim().isNotEmpty;
    }
  }

  Future<void> _onSubmit() async {
    final provider = context.read<PayoutMethodProvider>();
    final success = await provider.submitPayoutMethod(
      accountNumber: _accountNumberController.text.trim(),
      accountHolderName: _accountHolderNameController.text.trim(),
      bankName: provider.selectedType == 'bank_account'
          ? _bankNameController.text.trim()
          : null,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Moyen de reversement enregistré'),
          duration: Duration(seconds: 3),
        ),
      );
      context.go(RouteNames.kRouteHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PayoutMethodProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Moyen de reversement'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.kScreenMargin),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Choisissez votre moyen de reversement',
                            style: AppTextStyles.kTitleLarge,
                          ),
                          const SizedBox(height: AppSpacing.kSpaceLg),
                          _buildTypeSelector(provider),
                          const SizedBox(height: AppSpacing.kSpaceLg),
                          if (provider.selectedType == 'mobile_money')
                            _buildMobileMoneyForm(provider)
                          else
                            _buildBankAccountForm(provider),
                        ],
                      ),
                    ),
                  ),
                  if (provider.error != null) ...[
                    const SizedBox(height: AppSpacing.kSpaceSm),
                    Text(
                      provider.error!,
                      style: AppTextStyles.kBodyMedium.copyWith(
                        color: AppColors.kError,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (provider.isLoading) ...[
                    const SizedBox(height: AppSpacing.kSpaceSm),
                    const LinearProgressIndicator(),
                  ],
                  const SizedBox(height: AppSpacing.kSpaceMd),
                  SizedBox(
                    height: AppSpacing.kSpace2xl,
                    child: FilledButton(
                      onPressed: _isFormValid(provider) && !provider.isLoading
                          ? _onSubmit
                          : null,
                      child: const Text('Enregistrer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeSelector(PayoutMethodProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _TypeCard(
            icon: Icons.phone_android,
            label: 'Mobile Money',
            isSelected: provider.selectedType == 'mobile_money',
            onTap: () {
              if (provider.selectedType != 'mobile_money') {
                _accountNumberController.clear();
              }
              provider.setPayoutType('mobile_money');
            },
          ),
        ),
        const SizedBox(width: AppSpacing.kSpaceMd),
        Expanded(
          child: _TypeCard(
            icon: Icons.account_balance,
            label: 'Compte bancaire',
            isSelected: provider.selectedType == 'bank_account',
            onTap: () {
              if (provider.selectedType != 'bank_account') {
                _accountNumberController.clear();
              }
              provider.setPayoutType('bank_account');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileMoneyForm(PayoutMethodProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opérateur',
          style: AppTextStyles.kCaption.copyWith(
            color: AppColors.kTextTertiary,
          ),
        ),
        const SizedBox(height: AppSpacing.kSpaceSm),
        DropdownButtonFormField<String>(
          initialValue: provider.selectedProvider,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.kSpaceMd,
              vertical: AppSpacing.kSpaceSm,
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'orange', child: Text('Orange Money')),
            DropdownMenuItem(value: 'mtn', child: Text('MTN MoMo')),
            DropdownMenuItem(value: 'wave', child: Text('Wave')),
          ],
          onChanged: (value) {
            if (value != null) provider.setProvider(value);
          },
        ),
        const SizedBox(height: AppSpacing.kSpaceMd),
        TextField(
          controller: _accountNumberController,
          decoration: InputDecoration(
            labelText: 'Numéro de téléphone',
            hintText: provider.existingPayoutMethod != null
                ? 'Actuel : ${provider.existingPayoutMethod!.accountNumberMasked}'
                : '07 XX XX XX XX',
            prefixText: '+225 ',
          ),
          keyboardType: TextInputType.phone,
          maxLength: 10,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.kSpaceMd),
        TextField(
          controller: _accountHolderNameController,
          decoration: const InputDecoration(
            labelText: 'Nom du titulaire',
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildBankAccountForm(PayoutMethodProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _bankNameController,
          decoration: const InputDecoration(
            labelText: 'Nom de la banque',
          ),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.kSpaceMd),
        TextField(
          controller: _accountNumberController,
          decoration: InputDecoration(
            labelText: 'Numéro de compte (RIB)',
            hintText: provider.existingPayoutMethod != null
                ? 'Actuel : ${provider.existingPayoutMethod!.accountNumberMasked}'
                : null,
          ),
          keyboardType: TextInputType.text,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.kSpaceMd),
        TextField(
          controller: _accountHolderNameController,
          decoration: const InputDecoration(
            labelText: 'Titulaire du compte',
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}

/// Carte de sélection de type de reversement.
class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppSpacing.kRadiusMd);
    return Semantics(
      label: label,
      selected: isSelected,
      button: true,
      child: Material(
        color: AppColors.kBgSurface,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.kSpaceMd),
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(
                color: isSelected ? AppColors.kPrimary : AppColors.kOutline,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 32,
                  color:
                      isSelected ? AppColors.kPrimary : AppColors.kTextSecondary,
                ),
                const SizedBox(height: AppSpacing.kSpaceSm),
                Text(
                  label,
                  style: AppTextStyles.kLabelLarge.copyWith(
                    color: isSelected
                        ? AppColors.kPrimary
                        : AppColors.kTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
