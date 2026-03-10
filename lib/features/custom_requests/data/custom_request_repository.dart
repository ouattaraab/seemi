import 'package:dio/dio.dart';
import 'package:ppv_app/core/network/dio_client.dart';
import 'package:ppv_app/core/network/api_exceptions.dart';
import 'package:ppv_app/core/storage/secure_storage_service.dart';

class CustomRequest {
  final int id;
  final String status;
  final String description;
  final int agreedPriceFcfa;
  final String? deadlineAt;
  final String? creatorName;
  final String? fanName;
  final String role;
  final String createdAt;

  const CustomRequest({
    required this.id,
    required this.status,
    required this.description,
    required this.agreedPriceFcfa,
    this.deadlineAt,
    this.creatorName,
    this.fanName,
    required this.role,
    required this.createdAt,
  });

  factory CustomRequest.fromJson(Map<String, dynamic> j) => CustomRequest(
        id: j['id'] as int,
        status: j['status'] as String,
        description: j['description'] as String,
        agreedPriceFcfa: j['agreed_price_fcfa'] as int? ?? 0,
        deadlineAt: j['deadline_at'] as String?,
        creatorName: j['creator_name'] as String?,
        fanName: j['fan_name'] as String?,
        role: j['role'] as String? ?? 'fan',
        createdAt: j['created_at'] as String,
      );
}

class CustomRequestRepository {
  final DioClient _client;

  CustomRequestRepository({DioClient? client})
      : _client = client ??
            DioClient(
              storageService: const SecureStorageService(),
            );

  Future<List<CustomRequest>> getRequests() async {
    try {
      final res = await _client.dio.get('/custom-requests');
      final list = res.data['data']['data'] as List<dynamic>? ?? [];
      return list
          .map((e) => CustomRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }

  Future<void> createRequest({
    required int creatorId,
    required String description,
    required int agreedPriceFcfa,
    String? deadlineAt,
  }) async {
    try {
      await _client.dio.post('/custom-requests', data: {
        'creator_id': creatorId,
        'description': description,
        'agreed_price': agreedPriceFcfa * 100,
        if (deadlineAt != null) 'deadline_at': deadlineAt,
      });
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }

  Future<void> accept(int id) async {
    try {
      await _client.dio.put('/custom-requests/$id/accept');
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }

  Future<void> reject(int id) async {
    try {
      await _client.dio.put('/custom-requests/$id/reject');
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }

  Future<void> deliver(int id, int contentId) async {
    try {
      await _client.dio.post(
        '/custom-requests/$id/deliver',
        data: {'content_id': contentId},
      );
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }

  Future<void> dispute(int id) async {
    try {
      await _client.dio.post('/custom-requests/$id/dispute');
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }
}
