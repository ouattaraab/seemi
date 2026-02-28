import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/config/app_config.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/auth/presentation/auth_provider.dart';
import 'package:ppv_app/features/auth/presentation/tos_provider.dart';

/// Écran de saisie OTP — 6 champs individuels avec auto-avancement.
///
/// Supporte le flow login ([isLoginFlow] = true) et register (false).
class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final bool isLoginFlow;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    this.isLoginFlow = false,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _otpLength = 6;
  static const _resendDelaySeconds = 60;

  final List<TextEditingController> _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_otpLength, (_) => FocusNode());

  Timer? _resendTimer;
  int _resendCountdown = _resendDelaySeconds;
  bool _canResend = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = _resendDelaySeconds;
    _canResend = false;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  void _onOtpDigitChanged(int index, String value) {
    if (value.length == 1 && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-verify when all 6 digits are filled
    final code = _controllers.map((c) => c.text).join();
    if (code.length == _otpLength) {
      _verifyCode(code);
    }
  }

  Future<void> _verifyCode(String code) async {
    if (_isVerifying) return;
    _isVerifying = true;

    try {
      final authProvider = context.read<AuthProvider>();
      final verified = await authProvider.verifyOtp(code);

      if (!mounted) return;

      if (verified) {
        if (widget.isLoginFlow) {
          await _handleLoginFlow(authProvider);
        } else {
          await _handleRegisterFlow(authProvider);
        }
      }
    } finally {
      _isVerifying = false;
    }
  }

  Future<void> _handleLoginFlow(AuthProvider authProvider) async {
    final success = await authProvider.loginAfterOtp();
    if (!mounted) return;

    if (success) {
      final user = authProvider.user;
      if (user != null &&
          (user.acceptedTosAt == null ||
              user.tosVersion != AppConfig.currentTosVersion)) {
        // CGU requise — null ou version obsolète → modale non-dismissible
        await _showTosDialog();
      } else {
        context.go(RouteNames.kRouteHome);
      }
    } else if (authProvider.accountNotFound) {
      // Compte introuvable → proposer l'inscription
      _showAccountNotFoundSnackBar();
    }
  }

  Future<void> _handleRegisterFlow(AuthProvider authProvider) async {
    final registered = await authProvider.register();
    if (!mounted) return;
    if (registered) {
      context.go(RouteNames.kRouteTos);
    }
  }

  void _showAccountNotFoundSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Aucun compte associé à ce numéro.'),
        backgroundColor: AppColors.kBgOverlay,
        action: SnackBarAction(
          label: 'S\'inscrire',
          textColor: AppColors.kPrimary,
          onPressed: () => context.go(RouteNames.kRouteRegister),
        ),
      ),
    );
  }

  Future<void> _showTosDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Conditions Générales d\'Utilisation'),
          content: const SingleChildScrollView(
            child: Text(
              'En continuant, vous acceptez les Conditions Générales '
              'd\'Utilisation de PPV. Veuillez les lire attentivement '
              'avant de poursuivre.',
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () async {
                final tosProvider = dialogContext.read<TosProvider>();
                final accepted = await tosProvider.acceptTos('creator');
                if (!dialogContext.mounted) return;
                if (accepted) {
                  Navigator.of(dialogContext).pop();
                  if (mounted) {
                    context.go(RouteNames.kRouteHome);
                  }
                }
              },
              child: const Text('Accepter'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resendCode() async {
    if (!_canResend) return;
    final authProvider = context.read<AuthProvider>();
    await authProvider.sendOtp(widget.phoneNumber);
    if (mounted) {
      _startResendTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final backRoute = widget.isLoginFlow
        ? RouteNames.kRouteLogin
        : RouteNames.kRouteRegister;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go(backRoute),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.kScreenMargin),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.kSpaceLg),
                  const Text(
                    'Vérification',
                    style: AppTextStyles.kHeadlineLarge,
                  ),
                  const SizedBox(height: AppSpacing.kSpaceSm),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Code envoyé au ${widget.phoneNumber}',
                          style: AppTextStyles.kBodyLarge.copyWith(
                            color: AppColors.kTextSecondary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go(backRoute),
                        child: Text(
                          'Modifier',
                          style: AppTextStyles.kLabelLarge.copyWith(
                            color: AppColors.kPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.kSpaceXl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_otpLength, (index) {
                      return SizedBox(
                        width: AppSpacing.kSpace2xl,
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: AppTextStyles.kHeadlineLarge,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            counterText: '',
                          ),
                          onChanged: (value) =>
                              _onOtpDigitChanged(index, value),
                        ),
                      );
                    }),
                  ),
                  if (authProvider.error != null) ...[
                    const SizedBox(height: AppSpacing.kSpaceMd),
                    Text(
                      authProvider.error!,
                      style: AppTextStyles.kBodyMedium.copyWith(
                        color: AppColors.kError,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.kSpaceLg),
                  Center(
                    child: TextButton(
                      onPressed: _canResend ? _resendCode : null,
                      child: Text(
                        _canResend
                            ? 'Renvoyer le code'
                            : 'Renvoyer le code (${_resendCountdown}s)',
                        style: AppTextStyles.kBodyMedium.copyWith(
                          color: _canResend
                              ? AppColors.kPrimary
                              : AppColors.kTextDisabled,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.kSpaceLg),
                  SizedBox(
                    height: AppSpacing.kSpace2xl,
                    child: FilledButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : () {
                              final code =
                                  _controllers.map((c) => c.text).join();
                              if (code.length == _otpLength) {
                                _verifyCode(code);
                              }
                            },
                      child: authProvider.isLoading
                          ? const SizedBox(
                              width: AppSpacing.kSpaceLg,
                              height: AppSpacing.kSpaceLg,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.kTextPrimary,
                              ),
                            )
                          : const Text('Vérifier'),
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
}
