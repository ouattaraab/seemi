import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/features/auth/data/user_model.dart';

void main() {
  group('UserModel.fromJson', () {
    test('maps snake_case API fields to camelCase Dart properties', () {
      final json = {
        'id': 42,
        'phone': '+2250701020304',
        'first_name': 'Aminata',
        'last_name': 'Koné',
        'role': 'creator',
        'kyc_status': 'none',
        'is_active': true,
        'created_at': '2026-02-24T10:30:00.000000Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 42);
      expect(user.phone, '+2250701020304');
      expect(user.firstName, 'Aminata');
      expect(user.lastName, 'Koné');
      expect(user.role, 'creator');
      expect(user.kycStatus, 'none');
      expect(user.isActive, true);
      expect(user.createdAt, isNotNull);
      expect(user.createdAt!.year, 2026);
    });

    test('handles null optional fields', () {
      final json = {
        'id': 1,
        'phone': '+2250501020304',
        'first_name': null,
        'last_name': null,
        'role': 'buyer',
        'kyc_status': 'pending',
        'is_active': false,
        'created_at': null,
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 1);
      expect(user.phone, '+2250501020304');
      expect(user.firstName, isNull);
      expect(user.lastName, isNull);
      expect(user.role, 'buyer');
      expect(user.kycStatus, 'pending');
      expect(user.isActive, false);
      expect(user.createdAt, isNull);
    });

    test('parses all role values correctly', () {
      for (final role in ['creator', 'buyer', 'admin']) {
        final json = {
          'id': 1,
          'phone': '+2250701020304',
          'first_name': null,
          'last_name': null,
          'role': role,
          'kyc_status': 'none',
          'is_active': true,
          'created_at': null,
        };
        final user = UserModel.fromJson(json);
        expect(user.role, role);
      }
    });

    test('parses all kyc_status values correctly', () {
      for (final status in ['none', 'pending', 'approved', 'rejected']) {
        final json = {
          'id': 1,
          'phone': '+2250701020304',
          'first_name': null,
          'last_name': null,
          'role': 'creator',
          'kyc_status': status,
          'is_active': true,
          'created_at': null,
        };
        final user = UserModel.fromJson(json);
        expect(user.kycStatus, status);
      }
    });
  });
}
