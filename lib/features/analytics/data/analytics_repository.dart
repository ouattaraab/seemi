import 'package:dio/dio.dart';
import 'package:ppv_app/core/network/dio_client.dart';
import 'package:ppv_app/core/network/api_exceptions.dart';
import 'package:ppv_app/core/storage/secure_storage_service.dart';

class DailyRevenue {
  final String day;
  final int revenueFcfa;
  final int salesCount;
  const DailyRevenue({
    required this.day,
    required this.revenueFcfa,
    required this.salesCount,
  });
  factory DailyRevenue.fromJson(Map<String, dynamic> j) => DailyRevenue(
        day: j['day'] as String,
        revenueFcfa: j['revenue_fcfa'] as int? ?? 0,
        salesCount: j['sales_count'] as int? ?? 0,
      );
}

class TopContent {
  final int id;
  final String slug;
  final String type;
  final int priceFcfa;
  final int purchaseCount;
  final int viewCount;
  final double conversionRate;
  const TopContent({
    required this.id,
    required this.slug,
    required this.type,
    required this.priceFcfa,
    required this.purchaseCount,
    required this.viewCount,
    required this.conversionRate,
  });
  factory TopContent.fromJson(Map<String, dynamic> j) => TopContent(
        id: j['id'] as int,
        slug: j['slug'] as String? ?? '',
        type: j['type'] as String? ?? 'photo',
        priceFcfa: j['price_fcfa'] as int? ?? 0,
        purchaseCount: j['purchase_count'] as int? ?? 0,
        viewCount: j['view_count'] as int? ?? 0,
        conversionRate:
            (j['conversion_rate'] as num?)?.toDouble() ?? 0.0,
      );
}

class AnalyticsData {
  final int periodDays;
  final List<DailyRevenue> dailyRevenue;
  final List<TopContent> topContents;
  final double overallConversionRate;
  final int? peakHour;
  final String? peakDay;
  final int periodSales;

  const AnalyticsData({
    required this.periodDays,
    required this.dailyRevenue,
    required this.topContents,
    required this.overallConversionRate,
    this.peakHour,
    this.peakDay,
    required this.periodSales,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> j) => AnalyticsData(
        periodDays: j['period_days'] as int? ?? 30,
        dailyRevenue: (j['daily_revenue'] as List<dynamic>? ?? [])
            .map((e) => DailyRevenue.fromJson(e as Map<String, dynamic>))
            .toList(),
        topContents: (j['top_contents'] as List<dynamic>? ?? [])
            .map((e) => TopContent.fromJson(e as Map<String, dynamic>))
            .toList(),
        overallConversionRate:
            (j['overall_conversion_rate'] as num?)?.toDouble() ?? 0.0,
        peakHour: j['peak_hour'] as int?,
        peakDay: j['peak_day'] as String?,
        periodSales: j['period_sales'] as int? ?? 0,
      );
}

class AnalyticsRepository {
  final DioClient _client;

  AnalyticsRepository({DioClient? client})
      : _client = client ??
            DioClient(
              storageService: const SecureStorageService(),
            );

  Future<AnalyticsData> getAnalytics(int periodDays) async {
    try {
      final response = await _client.dio.get(
        '/stats/analytics',
        queryParameters: {'period': periodDays},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return AnalyticsData.fromJson(data);
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }
}
