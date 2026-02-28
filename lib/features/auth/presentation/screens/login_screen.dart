import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/auth/presentation/auth_provider.dart';

/// Regex validation numéro ivoirien : 10 chiffres, commence par 01/05/07.
final _phoneRegex = RegExp(r'^(01|05|07)\d{8}$');

/// Écran de connexion — saisie du numéro de téléphone (+225) pour OTP login.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  String? _phoneError;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir votre numéro de téléphone';
    }
    final digits = value.replaceAll(RegExp(r'\s'), '');
    if (!_phoneRegex.hasMatch(digits)) {
      return 'Numéro invalide. Format : 01/05/07 XX XX XX XX';
    }
    return null;
  }

  Future<void> _onLogin() async {
    setState(() {
      _phoneError = _validatePhone(_phoneController.text);
    });

    if (_phoneError != null) return;

    final digits = _phoneController.text.replaceAll(RegExp(r'\s'), '');
    final phoneNumber = '+225$digits';

    final authProvider = context.read<AuthProvider>();
    await authProvider.loginSendOtp(phoneNumber);

    if (!mounted) return;

    if (authProvider.verificationId != null) {
      context.go(RouteNames.kRouteOtp, extra: {'phoneNumber': phoneNumber, 'isLoginFlow': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.kScreenMargin),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  const Icon(
                    Icons.lock_outline,
                    size: AppSpacing.kIconSizeHero,
                    color: AppColors.kPrimary,
                  ),
                  const SizedBox(height: AppSpacing.kSpaceLg),
                  const Text(
                    'Connexion',
                    style: AppTextStyles.kHeadlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.kSpaceSm),
                  Text(
                    'Entrez votre numéro pour vous connecter.',
                    style: AppTextStyles.kBodyLarge.copyWith(
                      color: AppColors.kTextSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.kSpaceXl),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: AppSpacing.kSpace2xl,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.kSpaceMd,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.kBgElevated,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.kRadiusButton,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '+225',
                          style: AppTextStyles.kBodyLarge.copyWith(
                            color: AppColors.kTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.kSpaceSm),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: InputDecoration(
                            hintText: 'XX XX XX XX XX',
                            errorText: _phoneError ?? authProvider.error,
                          ),
                          onChanged: (_) {
                            if (_phoneError != null) {
                              setState(() => _phoneError = null);
                            }
                            if (authProvider.error != null) {
                              authProvider.clearError();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.kSpaceLg),
                  SizedBox(
                    height: AppSpacing.kSpace2xl,
                    child: FilledButton(
                      onPressed: authProvider.isLoading ? null : _onLogin,
                      child: authProvider.isLoading
                          ? const SizedBox(
                              width: AppSpacing.kSpaceLg,
                              height: AppSpacing.kSpaceLg,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.kTextPrimary,
                              ),
                            )
                          : const Text('Se connecter'),
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go(RouteNames.kRouteRegister),
                      child: Text(
                        'Pas encore de compte ? S\'inscrire',
                        style: AppTextStyles.kBodyMedium.copyWith(
                          color: AppColors.kPrimary,
                        ),
                      ),
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
