import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ppv_app/core/network/api_exceptions.dart';
import 'package:ppv_app/core/network/dio_client.dart';
import 'package:ppv_app/core/storage/secure_storage_service.dart';
import 'package:ppv_app/features/messaging/domain/conversation.dart';

// ─── Abstract ────────────────────────────────────────────────────────────────

abstract class MessagingRepository {
  Future<List<Conversation>> getConversations({int page = 1});
  Future<Conversation> startConversation(int creatorId);
  Future<List<Message>> getMessages(int conversationId, {int? afterId});
  Future<Message> sendTextMessage(int conversationId, String body);
  Future<Message> sendVoiceMessage(int conversationId, File audioFile);
  Future<Message> sendLockedContent(int conversationId, int contentId);
}

// ─── Implementation ──────────────────────────────────────────────────────────

class MessagingRepositoryImpl implements MessagingRepository {
  final DioClient _client;

  MessagingRepositoryImpl({DioClient? client})
      : _client = client ??
            DioClient(
              storageService: const SecureStorageService(),
            );

  @override
  Future<List<Conversation>> getConversations({int page = 1}) async {
    try {
      final res = await _client.dio.get(
        '/conversations',
        queryParameters: {'page': page},
      );
      final List<dynamic> list =
          (res.data['data']['data'] as List<dynamic>?) ?? [];
      return list
          .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }

  @override
  Future<Conversation> startConversation(int creatorId) async {
    try {
      final res = await _client.dio.post(
        '/conversations',
        data: {'creator_id': creatorId},
      );
      return Conversation.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }

  @override
  Future<List<Message>> getMessages(int conversationId,
      {int? afterId}) async {
    try {
      final res = await _client.dio.get(
        '/conversations/$conversationId/messages',
        queryParameters: {
          if (afterId != null && afterId > 0) 'after_id': afterId,
        },
      );
      final List<dynamic> list =
          (res.data['data']['data'] as List<dynamic>?) ?? [];
      return list
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }

  @override
  Future<Message> sendTextMessage(int conversationId, String body) async {
    try {
      final res = await _client.dio.post(
        '/conversations/$conversationId/messages',
        data: {'type': 'text', 'body': body},
      );
      return Message.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }

  @override
  Future<Message> sendVoiceMessage(int conversationId, File audioFile) async {
    try {
      final formData = FormData.fromMap({
        'type': 'voice',
        'voice_file': await MultipartFile.fromFile(
          audioFile.path,
          filename: 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
        ),
      });
      final res = await _client.dio.post(
        '/conversations/$conversationId/messages',
        data: formData,
      );
      return Message.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }

  @override
  Future<Message> sendLockedContent(
      int conversationId, int contentId) async {
    try {
      final res = await _client.dio.post(
        '/conversations/$conversationId/messages',
        data: {'type': 'locked_content', 'locked_content_id': contentId},
      );
      return Message.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }
}
