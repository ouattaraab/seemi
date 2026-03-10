import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/analytics/data/analytics_repository.dart';
import 'package:ppv_app/features/analytics/presentation/analytics_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgBase,
      appBar: AppBar(
        backgroundColor: AppColors.kBgBase,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.kTextPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Analytics',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.kTextPrimary,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
              height: 1, color: AppColors.kBorder.withValues(alpha: 0.6)),
        ),
      ),
      body: Consumer<AnalyticsProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            color: AppColors.kPrimary,
            onRefresh: () => provider.load(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                _buildPeriodSelector(provider),
                const SizedBox(height: 20),
                if (provider.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child:
                          CircularProgressIndicator(color: AppColors.kPrimary),
                    ),
                  )
                else if (provider.error != null)
                  _buildError(provider)
                else if (provider.data != null) ...[
                  _buildSummaryCards(provider.data!),
                  const SizedBox(height: 24),
                  _buildRevenueChart(provider.data!),
                  const SizedBox(height: 24),
                  _buildTopContents(provider.data!),
                  const SizedBox(height: 24),
                  _buildInsights(provider.data!),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector(AnalyticsProvider provider) {
    return Row(
      children: provider.periods.map((p) {
        final selected = provider.selectedPeriod == p;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => provider.load(period: p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.kPrimary
                    : AppColors.kBgSurface,
                borderRadius:
                    BorderRadius.circular(AppSpacing.kRadiusPill),
                border: Border.all(
                    color: selected
                        ? AppColors.kPrimary
                        : AppColors.kBorder),
              ),
              child: Text(
                '${p}j',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.white
                      : AppColors.kTextSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCards(AnalyticsData data) {
    final totalRevenue =
        data.dailyRevenue.fold(0, (sum, d) => sum + d.revenueFcfa);
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.payments_outlined,
            iconColor: AppColors.kSuccess,
            label: 'Revenus',
            value: '${_fmt(totalRevenue)} FCFA',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            icon: Icons.shopping_bag_outlined,
            iconColor: AppColors.kPrimary,
            label: 'Ventes',
            value: '${data.periodSales}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            icon: Icons.trending_up_rounded,
            iconColor: AppColors.kAccent,
            label: 'Conversion',
            value: '${data.overallConversionRate}%',
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueChart(AnalyticsData data) {
    if (data.dailyRevenue.isEmpty) {
      return _buildEmptyState('Aucune vente sur cette période');
    }
    final maxRevenue = data.dailyRevenue
        .map((d) => d.revenueFcfa)
        .reduce((a, b) => a > b ? a : b);
    return _SectionCard(
      title: 'Revenus par jour',
      child: SizedBox(
        height: 160,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: data.dailyRevenue.map((d) {
            final ratio =
                maxRevenue > 0 ? d.revenueFcfa / maxRevenue : 0.0;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: double.infinity,
                          height:
                              120 * ratio + (d.revenueFcfa > 0 ? 4 : 0),
                          decoration: BoxDecoration(
                            color: AppColors.kPrimary
                                .withValues(alpha: 0.75),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      d.day.length >= 5
                          ? d.day.substring(5)
                          : d.day,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 9,
                        color: AppColors.kTextTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTopContents(AnalyticsData data) {
    if (data.topContents.isEmpty) return const SizedBox.shrink();
    return _SectionCard(
      title: 'Top contenus',
      child: Column(
        children:
            data.topContents.map((c) => _TopContentRow(content: c)).toList(),
      ),
    );
  }

  Widget _buildInsights(AnalyticsData data) {
    final insights = <String>[];
    if (data.peakHour != null) {
      insights.add(
          'Vos acheteurs achètent surtout vers ${data.peakHour}h00');
    }
    if (data.peakDay != null) {
      insights.add('${data.peakDay} est votre meilleur jour');
    }
    if (data.overallConversionRate > 10) {
      insights.add('Excellent taux de conversion !');
    } else if (data.overallConversionRate > 0) {
      insights.add(
          'Essayez de baisser le prix pour améliorer la conversion.');
    }
    if (insights.isEmpty) return const SizedBox.shrink();
    return _SectionCard(
      title: 'Insights',
      child: Column(
        children: insights
            .map((insight) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded,
                          size: 16, color: AppColors.kWarning),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          insight,
                          style: AppTextStyles.kBodyMedium.copyWith(
                              color: AppColors.kTextSecondary),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildError(AnalyticsProvider provider) {
    return Center(
      child: Column(
        children: [
          Text(
            provider.error!,
            style: AppTextStyles.kBodyMedium
                .copyWith(color: AppColors.kTextSecondary),
          ),
          TextButton(
            onPressed: provider.load,
            child: const Text('Réessayer',
                style: TextStyle(color: AppColors.kPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          msg,
          style: AppTextStyles.kBodyMedium
              .copyWith(color: AppColors.kTextSecondary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ─── _SummaryCard ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.kBgSurface,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.kTextPrimary,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.kCaption
                .copyWith(color: AppColors.kTextSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── _SectionCard ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kBgSurface,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.kTitleLarge),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ─── _TopContentRow ───────────────────────────────────────────────────────────

class _TopContentRow extends StatelessWidget {
  final TopContent content;
  const _TopContentRow({required this.content});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.kPrimary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              content.type == 'video'
                  ? Icons.videocam_rounded
                  : Icons.image_rounded,
              size: 16,
              color: AppColors.kPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.slug,
                  style: AppTextStyles.kBodyMedium
                      .copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${content.purchaseCount} ventes · ${content.conversionRate}% conversion',
                  style: AppTextStyles.kCaption
                      .copyWith(color: AppColors.kTextSecondary),
                ),
              ],
            ),
          ),
          Text(
            '${_fmt(content.priceFcfa)} F',
            style: AppTextStyles.kBodyMedium.copyWith(
                fontWeight: FontWeight.w700, color: AppColors.kSuccess),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _fmt(int n) {
  if (n == 0) return '0';
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('\u202F');
    buf.write(s[i]);
  }
  return buf.toString();
}
