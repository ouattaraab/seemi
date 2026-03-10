import 'package:dio/dio.dart';
import 'package:ppv_app/core/network/dio_client.dart';
import 'package:ppv_app/core/network/api_exceptions.dart';
import 'package:ppv_app/core/storage/secure_storage_service.dart';

class SubscriptionTier {
  final int id;
  final String name;
  final String? description;
  final int priceMonthlyFcfa;
  final int activeSubscribers;
  final int? maxSubscribers;

  const SubscriptionTier({
    required this.id,
    required this.name,
    this.description,
    required this.priceMonthlyFcfa,
    required this.activeSubscribers,
    this.maxSubscribers,
  });

  factory SubscriptionTier.fromJson(Map<String, dynamic> j) => SubscriptionTier(
        id: j['id'] as int,
        name: j['name'] as String,
        description: j['description'] as String?,
        priceMonthlyFcfa: j['price_monthly_fcfa'] as int? ?? 0,
        activeSubscribers: j['active_subscribers'] as int? ?? 0,
        maxSubscribers: j['max_subscribers'] as int?,
      );
}

class ActiveSubscription {
  final int id;
  final int tierId;
  final String? tierName;
  final int priceMonthlyFcfa;
  final String? creatorName;
  final String? creatorUsername;
  final DateTime? expiresAt;

  const ActiveSubscription({
    required this.id,
    required this.tierId,
    this.tierName,
    required this.priceMonthlyFcfa,
    this.creatorName,
    this.creatorUsername,
    this.expiresAt,
  });

  factory ActiveSubscription.fromJson(Map<String, dynamic> j) =>
      ActiveSubscription(
        id: j['id'] as int,
        tierId: j['tier_id'] as int,
        tierName: j['tier_name'] as String?,
        priceMonthlyFcfa: j['price_monthly_fcfa'] as int? ?? 0,
        creatorName: j['creator_name'] as String?,
        creatorUsername: j['creator_username'] as String?,
        expiresAt: j['expires_at'] != null
            ? DateTime.parse(j['expires_at'] as String)
            : null,
      );
}

class SubscriptionRepository {
  final DioClient _authClient;

  SubscriptionRepository({DioClient? authClient})
      : _authClient = authClient ??
            DioClient(
              storageService: const SecureStorageService(),
            );

  Future<List<SubscriptionTier>> getTiersByCreator(int creatorId) async {
    try {
      final res = await _authClient.dio.get('/subscriptions/tiers/$creatorId');
      final list = res.data['data']['data'] as List<dynamic>? ?? [];
      return list
          .map((e) => SubscriptionTier.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }

  Future<List<ActiveSubscription>> mySubscriptions() async {
    try {
      final res = await _authClient.dio.get('/subscriptions/my');
      final list = res.data['data']['data'] as List<dynamic>? ?? [];
      return list
          .map((e) => ActiveSubscription.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }

  Future<SubscriptionTier> createTier({
    required String name,
    String? description,
    required int priceMonthlyFcfa,
  }) async {
    try {
      final res = await _authClient.dio.post('/subscriptions/tiers', data: {
        'name': name,
        'description': description,
        'price_monthly': priceMonthlyFcfa * 100,
      });
      return SubscriptionTier.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> initiateSubscription({
    required int tierId,
    required String email,
    String? phone,
  }) async {
    try {
      final res = await _authClient.dio.post('/payments/subscribe', data: {
        'tier_id': tierId,
        'email': email,
        if (phone != null) 'phone': phone,
      });
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }
}
