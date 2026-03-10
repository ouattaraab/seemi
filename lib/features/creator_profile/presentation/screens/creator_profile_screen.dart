import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/features/creator_profile/domain/creator_profile.dart';
import 'package:ppv_app/features/creator_profile/presentation/creator_profile_provider.dart';

class CreatorProfileScreen extends StatefulWidget {
  final String username;

  const CreatorProfileScreen({super.key, required this.username});

  @override
  State<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CreatorProfileProvider>();
      provider.loadProfile();
      provider.loadContents(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<CreatorProfileProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgBase,
      body: Consumer<CreatorProfileProvider>(
        builder: (context, provider, _) {
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildAppBar(context, provider),
              if (provider.isLoadingProfile)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.kPrimary),
                  ),
                )
              else if (provider.profileError != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          provider.profileError!,
                          style: AppTextStyles.kBodyMedium.copyWith(
                            color: AppColors.kTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: provider.loadProfile,
                          child: const Text(
                            'Réessayer',
                            style: TextStyle(color: AppColors.kPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (provider.profile != null) ...[
                SliverToBoxAdapter(
                  child: _buildProfileHeader(provider.profile!),
                ),
                SliverToBoxAdapter(
                  child: _buildStatsRow(provider.profile!),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Text(
                      'Contenus (${provider.profile!.contentCount})',
                      style: AppTextStyles.kTitleLarge,
                    ),
                  ),
                ),
                if (provider.isLoadingContents)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.kPrimary,
                      ),
                    ),
                  )
                else if (provider.contents.isEmpty)
                  SliverToBoxAdapter(child: _buildEmptyContents())
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          if (i == provider.contents.length) {
                            return provider.isLoadingMore
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(
                                        color: AppColors.kPrimary,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink();
                          }
                          return _buildContentCard(provider.contents[i]);
                        },
                        childCount: provider.contents.length +
                            (provider.hasMore ? 1 : 0),
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, CreatorProfileProvider provider) {
    return SliverAppBar(
      backgroundColor: AppColors.kBgBase,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      pinned: true,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.kTextPrimary,
          size: 20,
        ),
        onPressed: () => context.pop(),
      ),
      title: Text(
        provider.profile != null
            ? '@${provider.profile!.username ?? provider.username}'
            : '@${widget.username}',
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.kTextPrimary,
        ),
      ),
      centerTitle: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          color: AppColors.kBorder.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(CreatorProfile profile) {
    final initials =
        profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.kPrimary.withValues(alpha: 0.12),
                  border: Border.all(color: AppColors.kBorder, width: 2),
                ),
                child: profile.avatarUrl != null
                    ? ClipOval(
                        child: Image.network(
                          profile.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.kPrimary,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.kPrimary,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              // Name + username
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.kTextPrimary,
                      ),
                    ),
                    if (profile.username != null)
                      Text(
                        '@${profile.username}',
                        style: AppTextStyles.kBodyMedium.copyWith(
                          color: AppColors.kTextSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              profile.bio!,
              style: AppTextStyles.kBodyMedium.copyWith(
                color: AppColors.kTextSecondary,
                height: 1.5,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow(CreatorProfile profile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          _StatPill(value: '${profile.contentCount}', label: 'contenus'),
          const SizedBox(width: 10),
          _StatPill(value: '${profile.totalSales}', label: 'déblocages'),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push(
              '${RouteNames.fanPass(profile.id)}?name=${Uri.encodeComponent(profile.name)}',
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.kPrimary,
                borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.card_membership_rounded,
                      size: 14, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Fan Pass',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContents() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.kBgElevated,
              ),
              child: const Icon(
                Icons.image_outlined,
                size: 24,
                color: AppColors.kTextTertiary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Aucun contenu publié',
              style: AppTextStyles.kBodyMedium.copyWith(
                color: AppColors.kTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard(CreatorContentItem item) {
    return GestureDetector(
      onTap: () {
        if (item.slug != null) {
          context.push('/c/${item.slug}');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.kBgSurface,
          borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
          border: Border.all(color: AppColors.kBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail
              if (item.blurPathUrl != null)
                Image.network(
                  item.blurPathUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.kBgElevated,
                    child: Icon(
                      item.type == 'video'
                          ? Icons.videocam_outlined
                          : Icons.image_outlined,
                      color: AppColors.kTextTertiary,
                      size: 32,
                    ),
                  ),
                )
              else
                Container(
                  color: AppColors.kBgElevated,
                  child: Icon(
                    item.type == 'video'
                        ? Icons.videocam_outlined
                        : Icons.image_outlined,
                    color: AppColors.kTextTertiary,
                    size: 32,
                  ),
                ),
              // Gradient overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.70),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // Price badge
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.kPrimary,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.kRadiusPill),
                      ),
                      child: Text(
                        '${_fmt(item.priceFcfa)} FCFA',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (item.isTrending)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B00),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.kRadiusPill),
                        ),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
              // Video badge
              if (item.type == 'video')
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.videocam_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  const _StatPill({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.kBgSurface,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
          children: [
            TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.kTextPrimary,
              ),
            ),
            const TextSpan(text: ' '),
            TextSpan(
              text: label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.kTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
