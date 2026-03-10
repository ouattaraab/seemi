import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/messaging/domain/conversation.dart';
import 'package:ppv_app/features/messaging/presentation/conversations_provider.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ConversationsProvider>().loadConversations();
    });
  }

  Future<void> _showStartConversationDialog() async {
    final controller = TextEditingController();
    final provider = context.read<ConversationsProvider>();

    final creatorIdStr = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.kBgSurface,
        title: const Text(
          'Nouveau message',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w800,
            color: AppColors.kTextPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'ID du créateur',
            hintStyle: AppTextStyles.kCaption,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
              borderSide: const BorderSide(color: AppColors.kBorder),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Démarrer'),
          ),
        ],
      ),
    );

    if (creatorIdStr == null || creatorIdStr.isEmpty) return;
    final creatorId = int.tryParse(creatorIdStr);
    if (creatorId == null) return;

    if (!mounted) return;
    try {
      final conv = await provider.startConversation(creatorId);
      if (!mounted) return;
      context.push(RouteNames.conversation(conv.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.kError,
        ),
      );
    }
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.kTextPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.kTextPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: AppColors.kBorder.withValues(alpha: 0.6),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showStartConversationDialog,
        backgroundColor: AppColors.kPrimaryDark,
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
      body: Consumer<ConversationsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.conversations.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.kPrimary),
            );
          }
          if (provider.error != null && provider.conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Impossible de charger les messages.',
                    style: AppTextStyles.kBodyMedium
                        .copyWith(color: AppColors.kTextSecondary),
                  ),
                  const SizedBox(height: AppSpacing.kSpaceMd),
                  TextButton(
                    onPressed: provider.refresh,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }
          if (provider.conversations.isEmpty) {
            return Center(
              child: Text(
                'Aucune conversation pour l\'instant.',
                style: AppTextStyles.kBodyMedium
                    .copyWith(color: AppColors.kTextSecondary),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: provider.refresh,
            color: AppColors.kPrimary,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: provider.conversations.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 72,
                color: AppColors.kBorder.withValues(alpha: 0.5),
              ),
              itemBuilder: (_, i) {
                return _ConversationTile(
                  conversation: provider.conversations[i],
                  onTap: () => context.push(
                    RouteNames.conversation(provider.conversations[i].id),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ─── ConversationTile ─────────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays >= 1) {
      return '${dt.day}/${dt.month}';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes}m';
    }
    return 'maintenant';
  }

  @override
  Widget build(BuildContext context) {
    final other = conversation.otherUser;
    final hasUnread = conversation.unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.kSpaceMd,
          vertical: 12,
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.kPrimaryDark.withValues(alpha: 0.15),
              backgroundImage: other.avatarUrl != null
                  ? NetworkImage(other.avatarUrl!)
                  : null,
              child: other.avatarUrl == null
                  ? Text(
                      (other.name.isNotEmpty ? other.name[0] : '?')
                          .toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        color: AppColors.kPrimaryDark,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.kSpaceMd),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          other.name,
                          style: AppTextStyles.kBodyMedium.copyWith(
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: AppColors.kTextPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(conversation.lastMessageAt),
                        style: AppTextStyles.kCaption.copyWith(
                          color: hasUnread
                              ? AppColors.kPrimary
                              : AppColors.kTextTertiary,
                          fontWeight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage ?? 'Aucun message',
                          style: AppTextStyles.kCaption.copyWith(
                            color: hasUnread
                                ? AppColors.kTextPrimary
                                : AppColors.kTextSecondary,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: AppSpacing.kSpaceSm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.kPrimary,
                            borderRadius: BorderRadius.circular(
                                AppSpacing.kRadiusPill),
                          ),
                          child: Text(
                            conversation.unreadCount > 99
                                ? '99+'
                                : '${conversation.unreadCount}',
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
