import 'package:flutter/material.dart';
import 'package:ppv_app/core/network/api_exceptions.dart';
import 'package:ppv_app/features/payment/data/payment_repository.dart';

/// Provider paiement — gère l'initiation et la vérification de paiement Paystack.
///
/// Conforme au pattern obligatoire : état loading / error / data + ChangeNotifier.
class PaymentProvider extends ChangeNotifier {
  final PaymentRepository _repository;

  bool _isLoading = false;
  String? _error;
  String? _authorizationUrl;

  // État reveal (post-paiement)
  bool _isCheckingReveal = false;
  bool _isPaid = false;
  String? _originalUrl;
  bool _paymentFailed = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get authorizationUrl => _authorizationUrl;
  bool get hasUrl => _authorizationUrl != null;

  bool get isCheckingReveal => _isCheckingReveal;
  bool get isPaid => _isPaid;
  String? get originalUrl => _originalUrl;
  bool get paymentFailed => _paymentFailed;

  PaymentProvider({required PaymentRepository repository})
      : _repository = repository;

  Future<void> initiatePayment({
    required String slug,
    required String email,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    _authorizationUrl = null;
    notifyListeners();

    try {
      final result = await _repository.initiatePayment(
        slug: slug,
        email: email,
        phone: phone,
      );
      _authorizationUrl = result.authorizationUrl;
    } on ApiException catch (e) {
      if (e.isNotFound) {
        _error = 'Ce contenu n\'existe plus ou n\'est plus disponible.';
      } else if (e.isValidationError) {
        _error = 'Erreur de validation. Vérifiez votre adresse email.';
      } else if (e.isServerError) {
        _error = 'Erreur lors de la connexion au service de paiement. Réessayez.';
      } else {
        _error = e.message.isNotEmpty
            ? e.message
            : 'Une erreur est survenue. Réessayez.';
      }
    } catch (_) {
      _error = 'Impossible d\'initier le paiement. Vérifiez votre connexion.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Vérifie le statut de paiement par polling et déclenche le reveal.
  ///
  /// Interroge l'API toutes les 2s, max 8 tentatives (≈ 16s).
  /// Met à jour [isPaid] et [originalUrl] dès confirmation.
  Future<void> checkPaymentAndReveal({
    required String slug,
    required String reference,
  }) async {
    _isCheckingReveal = true;
    _isPaid = false;
    _originalUrl = null;
    _paymentFailed = false;
    notifyListeners();

    const maxAttempts = 8;
    const pollInterval = Duration(seconds: 2);
    int attempts = 0;

    // Délai initial : laisser le webhook Paystack arriver
    await Future.delayed(const Duration(seconds: 1));

    while (attempts < maxAttempts) {
      try {
        final result = await _repository.checkPaymentStatus(
          slug: slug,
          reference: reference,
        );
        if (result.isPaid) {
          _isPaid = true;
          _originalUrl = result.originalUrl;
          _isCheckingReveal = false;
          notifyListeners();
          return;
        }
        // Sortie immédiate si le paiement est explicitement échoué
        if (result.paymentStatus == 'failed') {
          _paymentFailed = true;
          _isCheckingReveal = false;
          notifyListeners();
          return;
        }
      } catch (_) {
        // Continuer le polling même en cas d'erreur réseau passagère
      }
      attempts++;
      if (attempts < maxAttempts) {
        await Future.delayed(pollInterval);
      }
    }

    _isCheckingReveal = false;
    notifyListeners();
  }

  /// Remet le provider à l'état initial (utile après fermeture du dialog).
  void reset() {
    _isLoading = false;
    _error = null;
    _authorizationUrl = null;
    _isCheckingReveal = false;
    _isPaid = false;
    _originalUrl = null;
    _paymentFailed = false;
    notifyListeners();
  }
}
