import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/features/content/data/content_model.dart';

void main() {
  group('ContentModel.fromJson', () {
    test('maps snake_case API fields to camelCase Dart properties', () {
      final json = {
        'id': 42,
        'type': 'photo',
        'status': 'draft',
        'slug': 'abc123',
        'price': 500,
        'blur_url': 'https://example.com/blur.jpg',
        'view_count': 10,
        'purchase_count': 3,
        'created_at': '2026-02-25T10:30:00.000000Z',
      };

      final content = ContentModel.fromJson(json);

      expect(content.id, 42);
      expect(content.type, 'photo');
      expect(content.status, 'draft');
      expect(content.slug, 'abc123');
      expect(content.price, 500);
      expect(content.blurUrl, 'https://example.com/blur.jpg');
      expect(content.viewCount, 10);
      expect(content.purchaseCount, 3);
      expect(content.createdAt, isNotNull);
      expect(content.createdAt!.year, 2026);
    });

    test('handles null optional fields', () {
      final json = {
        'id': 1,
        'type': 'photo',
        'status': 'active',
        'slug': null,
        'price': null,
        'blur_url': null,
        'view_count': null,
        'purchase_count': null,
        'created_at': null,
      };

      final content = ContentModel.fromJson(json);

      expect(content.id, 1);
      expect(content.type, 'photo');
      expect(content.status, 'active');
      expect(content.slug, isNull);
      expect(content.price, isNull);
      expect(content.blurUrl, isNull);
      expect(content.viewCount, 0);
      expect(content.purchaseCount, 0);
      expect(content.createdAt, isNull);
    });

    test('throws FormatException when id is not int', () {
      final json = {
        'id': 'not-an-int',
        'type': 'photo',
        'status': 'draft',
      };

      expect(() => ContentModel.fromJson(json), throwsFormatException);
    });

    test('throws FormatException when type is not String', () {
      final json = {
        'id': 1,
        'type': 123,
        'status': 'draft',
      };

      expect(() => ContentModel.fromJson(json), throwsFormatException);
    });

    test('throws FormatException when status is not String', () {
      final json = {
        'id': 1,
        'type': 'photo',
        'status': null,
      };

      expect(() => ContentModel.fromJson(json), throwsFormatException);
    });
  });
}
