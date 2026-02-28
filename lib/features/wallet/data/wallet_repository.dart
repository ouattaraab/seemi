import 'package:dio/dio.dart';
import 'package:ppv_app/core/network/api_exceptions.dart';
import 'package:ppv_app/features/wallet/domain/wallet_transaction.dart';
import 'package:ppv_app/features/wallet/domain/withdrawal_summary.dart';

/// Résultat de la consultation du solde wallet.
class WalletBalanceResult {
  /// Solde en centimes FCFA.
  final int balance;

  const WalletBalanceResult({required this.balance});

  factory WalletBalanceResult.fromJson(Map<String, dynamic> json) {
    return WalletBalanceResult(
      balance: json['balance'] as int? ?? 0,
    );
  }
}

/// Résultat paginé de la liste des transactions.
class WalletTransactionsResult {
  final List<WalletTransaction> transactions;
  final String? nextCursor;
  final bool hasMore;
  final int totalCredits; // centimes FCFA

  const WalletTransactionsResult({
    required this.transactions,
    required this.nextCursor,
    required this.hasMore,
    required this.totalCredits,
  });
}

/// Résultat d'une demande de retrait.
class WithdrawalResult {
  final int withdrawalId;
  final String status;
  final int amount; // centimes FCFA

  const WithdrawalResult({
    required this.withdrawalId,
    required this.status,
    required this.amount,
  });

  factory WithdrawalResult.fromJson(Map<String, dynamic> json) {
    return WithdrawalResult(
      withdrawalId: json['withdrawal_id'] as int,
      status: json['status'] as String,
      amount: json['amount'] as int,
    );
  }
}

/// Résultat d'un appel GET /wallet/withdrawals.
class WithdrawalsResult {
  final List<WithdrawalSummary> withdrawals;
  final bool hasMore;
  final String? nextCursor;

  const WithdrawalsResult({
    required this.withdrawals,
    required this.hasMore,
    this.nextCursor,
  });
}

/// Repository wallet — appels authentifiés.
/// Le [Dio] injecté doit déjà porter l'intercepteur JWT (DioClient).
class WalletRepository {
  final Dio _dio;

  WalletRepository({required Dio dio}) : _dio = dio;

  /// Récupère le solde courant via GET /api/v1/wallet/balance.
  Future<WalletBalanceResult> getBalance() async {
    try {
      final response = await _dio.get('/wallet/balance');
      final data = response.data['data'] as Map<String, dynamic>;
      return WalletBalanceResult.fromJson(data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException.fromDioException(e);
      }
      throw NetworkException.fromDioException(e);
    }
  }

  /// Récupère la liste paginée des transactions via GET /api/v1/wallet/transactions.
  Future<WalletTransactionsResult> getTransactions({String? cursor}) async {
    try {
      final response = await _dio.get(
        '/wallet/transactions',
        queryParameters: cursor != null ? {'cursor': cursor} : null,
      );
      final data = response.data['data'] as Map<String, dynamic>;
      final rawList = data['transactions'] as List;
      return WalletTransactionsResult(
        transactions: rawList
            .cast<Map<String, dynamic>>()
            .map(WalletTransaction.fromJson)
            .toList(),
        nextCursor:   data['next_cursor'] as String?,
        hasMore:      data['has_more'] as bool? ?? false,
        totalCredits: data['total_credits'] as int? ?? 0,
      );
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }

  /// Soumet une demande de retrait via POST /api/v1/wallet/withdraw.
  Future<WithdrawalResult> postWithdrawal({
    required int amountCentimes,
    required int payoutMethodId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/wallet/withdraw',
        data: {
          'amount': amountCentimes,
          'payout_method_id': payoutMethodId,
        },
      );
      final data = response.data!['data'] as Map<String, dynamic>;
      return WithdrawalResult.fromJson(data);
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }

  /// GET /api/v1/wallet/withdrawals
  Future<WithdrawalsResult> getWithdrawals({String? cursor}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/wallet/withdrawals',
        queryParameters: cursor != null ? {'cursor': cursor} : null,
      );
      final raw = response.data!;
      final data = raw['data'] as List<dynamic>;
      final meta = raw['meta'] as Map<String, dynamic>? ?? {};

      return WithdrawalsResult(
        withdrawals: data
            .cast<Map<String, dynamic>>()
            .map(WithdrawalSummary.fromJson)
            .toList(),
        hasMore: meta['has_more'] as bool? ?? false,
        nextCursor: meta['next_cursor'] as String?,
      );
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }
}
