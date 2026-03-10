import 'package:flutter/material.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/features/payment/data/tip_repository.dart';

class TipBottomSheet extends StatefulWidget {
  final String slug;
  final String creatorName;
  const TipBottomSheet({
    super.key,
    required this.slug,
    required this.creatorName,
  });
  @override
  State<TipBottomSheet> createState() => _TipBottomSheetState();
}

class _TipBottomSheetState extends State<TipBottomSheet> {
  int? _selectedAmount;
  final _customController = TextEditingController();
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;

  final List<int> _quickAmounts = [100, 250, 500, 1000];

  @override
  void dispose() {
    _customController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendTip() async {
    final amount =
        _selectedAmount ?? int.tryParse(_customController.text.trim());
    if (amount == null || amount < 100) {
      setState(() => _error = 'Montant minimum : 100 FCFA');
      return;
    }
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Email requis pour le reçu');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final creatorName = widget.creatorName;
    try {
      await TipRepository()
          .sendTip(slug: widget.slug, amountFcfa: amount, email: email);
      if (!mounted) return;
      nav.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Pourboire envoyé à $creatorName !')),
      );
    } catch (e) {
      setState(() {
        _error = 'Impossible d\'envoyer le pourboire.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Laisser un pourboire à ${widget.creatorName}',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.kTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickAmounts.map((a) {
              final selected = _selectedAmount == a;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedAmount = a;
                  _customController.clear();
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.kSuccess
                        : AppColors.kBgSurface,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.kRadiusPill),
                    border: Border.all(
                        color: selected
                            ? AppColors.kSuccess
                            : AppColors.kBorder),
                  ),
                  child: Text(
                    '$a F',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? Colors.white
                          : AppColors.kTextPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() => _selectedAmount = null),
            decoration: InputDecoration(
              labelText: 'Montant personnalisé (FCFA)',
              border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.kRadiusLg)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Votre email (pour le reçu)',
              border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.kRadiusLg)),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style:
                  const TextStyle(color: AppColors.kError, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: AppSpacing.kButtonHeight,
            child: FilledButton.icon(
              onPressed: _loading ? null : _sendTip,
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.kSuccess,
                  shape: const StadiumBorder()),
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.favorite_rounded, size: 18),
              label: const Text(
                'Envoyer le pourboire',
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
