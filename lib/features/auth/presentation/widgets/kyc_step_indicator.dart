import 'package:flutter/material.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';

/// Indicateur de progression KYC — 3 étapes numérotées reliées par des lignes.
class KycStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const KycStepIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps * 2 - 1, (index) {
        if (index.isEven) {
          final stepNumber = index ~/ 2 + 1;
          return _buildStepCircle(stepNumber);
        } else {
          final beforeStep = index ~/ 2 + 1;
          return _buildConnectorLine(beforeStep);
        }
      }),
    );
  }

  Widget _buildStepCircle(int stepNumber) {
    final isCompleted = stepNumber < currentStep;
    final isCurrent = stepNumber == currentStep;

    Color bgColor;
    Widget child;

    if (isCompleted) {
      bgColor = AppColors.kSuccess;
      child = const Icon(Icons.check, color: Colors.white, size: 16);
    } else if (isCurrent) {
      bgColor = AppColors.kPrimary;
      child = Text(
        '$stepNumber',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      );
    } else {
      bgColor = AppColors.kBgOverlay;
      child = Text(
        '$stepNumber',
        style: const TextStyle(
          color: AppColors.kTextDisabled,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      );
    }

    return Container(
      width: AppSpacing.kSpaceXl,
      height: AppSpacing.kSpaceXl,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _buildConnectorLine(int beforeStep) {
    final isCompleted = beforeStep < currentStep;

    return Expanded(
      child: Container(
        height: 2,
        color: isCompleted ? AppColors.kSuccess : AppColors.kBgOverlay,
      ),
    );
  }
}
