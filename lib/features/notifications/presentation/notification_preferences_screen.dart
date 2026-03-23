import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/features/notifications/data/notification_repository.dart';

/// Écran de préférences de notifications.
///
/// Charge depuis l'API au démarrage (avec fallback SharedPreferences hors-ligne).
/// Sauvegarde vers l'API en fire-and-forget à chaque toggle, avec copie locale.
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  static const _kPaymentKey    = 'notif_pref_payment';
  static const _kWithdrawalKey = 'notif_pref_withdrawal';
  static const _kModerationKey = 'notif_pref_moderation';
  static const _kNewSaleKey    = 'notif_pref_new_sale';

  bool _payment    = true;
  bool _withdrawal = true;
  bool _moderation = true;
  bool _newSale    = true;
  bool _loading    = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPreferences());
  }

  Future<void> _loadPreferences() async {
    // 1. Afficher le cache local immédiatement
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _payment    = prefs.getBool(_kPaymentKey)    ?? true;
        _withdrawal = prefs.getBool(_kWithdrawalKey) ?? true;
        _moderation = prefs.getBool(_kModerationKey) ?? true;
        _newSale    = prefs.getBool(_kNewSaleKey)    ?? true;
        _loading    = false;
      });
    }

    // 2. Charger depuis l'API en arrière-plan et mettre à jour si différent
    try {
      final repo = context.read<NotificationRepository>();
      final apiPrefs = await repo.getNotificationPreferences();
      if (!mounted) return;
      setState(() {
        _payment    = apiPrefs['payment']    ?? _payment;
        _withdrawal = apiPrefs['withdrawal'] ?? _withdrawal;
        _moderation = apiPrefs['moderation'] ?? _moderation;
        _newSale    = apiPrefs['new_sale']   ?? _newSale;
      });
      // Mettre à jour le cache local avec les valeurs API
      await _saveLocally();
    } catch (_) {
      // API indisponible — les préférences locales sont déjà affichées
    }
  }

  Future<void> _saveLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPaymentKey,    _payment);
    await prefs.setBool(_kWithdrawalKey, _withdrawal);
    await prefs.setBool(_kModerationKey, _moderation);
    await prefs.setBool(_kNewSaleKey,    _newSale);
  }

  void _toggle(String key, bool value) {
    setState(() {
      switch (key) {
        case _kPaymentKey:    _payment    = value;
        case _kWithdrawalKey: _withdrawal = value;
        case _kModerationKey: _moderation = value;
        case _kNewSaleKey:    _newSale    = value;
      }
    });

    // Sauvegarder localement (synchrone) + API (fire-and-forget)
    _saveLocally().ignore();
    _pushToApi().ignore();

    // Note: les préférences n'affectent pas le compteur de notifications non lues
  }

  Future<void> _pushToApi() async {
    try {
      final repo = context.read<NotificationRepository>();
      await repo.updateNotificationPreferences({
        'payment':    _payment,
        'withdrawal': _withdrawal,
        'moderation': _moderation,
        'new_sale':   _newSale,
      });
    } catch (_) {
      // API indisponible — préférences locales conservées
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgBase,
      appBar: AppBar(
        backgroundColor: AppColors.kBgBase,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.kTextPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Préférences de notifications',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.kTextPrimary,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  const _SectionLabel('TRANSACTIONS'),
                  const SizedBox(height: 8),
                  _PrefTile(
                    title: 'Paiements reçus',
                    subtitle: 'Alerte quand un acheteur paie votre contenu',
                    value: _payment,
                    onChanged: (v) => _toggle(_kPaymentKey, v),
                  ),
                  _PrefTile(
                    title: 'Retraits traités',
                    subtitle: 'Statut de vos demandes de retrait',
                    value: _withdrawal,
                    onChanged: (v) => _toggle(_kWithdrawalKey, v),
                  ),
                  const SizedBox(height: 24),
                  const _SectionLabel('CONTENU'),
                  const SizedBox(height: 8),
                  _PrefTile(
                    title: 'Nouvelles ventes',
                    subtitle: 'Résumé des ventes par contenu',
                    value: _newSale,
                    onChanged: (v) => _toggle(_kNewSaleKey, v),
                  ),
                  _PrefTile(
                    title: 'Modération',
                    subtitle: 'Décisions KYC et signalements de vos contenus',
                    value: _moderation,
                    onChanged: (v) => _toggle(_kModerationKey, v),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Ces préférences contrôlent les notifications in-app. Les notifications push dépendent également des réglages système de votre appareil.',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      color: AppColors.kTextTertiary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.kTextTertiary,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _PrefTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrefTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.kBgSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.kTextPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 12,
            color: AppColors.kTextSecondary,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.kPrimary,
      ),
    );
  }
}
