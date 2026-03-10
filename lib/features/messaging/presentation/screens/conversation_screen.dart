import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/auth/presentation/profile_provider.dart';
import 'package:ppv_app/features/messaging/domain/conversation.dart';
import 'package:ppv_app/features/messaging/presentation/conversation_provider.dart';

class ConversationScreen extends StatefulWidget {
  final int conversationId;

  const ConversationScreen({super.key, required this.conversationId});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<ConversationProvider>();
      provider.loadMessages().then((_) {
        _scrollToBottom();
        provider.startPolling();
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendText() async {
    final body = _textController.text.trim();
    if (body.isEmpty) return;
    _textController.clear();
    await context.read<ConversationProvider>().sendText(body);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConversationProvider>(
      builder: (context, provider, _) {
        // Determine the current user id
        final profileProvider = context.watch<ProfileProvider>();
        final currentUserId = profileProvider.user?.id ?? 0;
        final isCreator = profileProvider.user?.role == 'creator';

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
            title: _AppBarTitle(provider: provider),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(
                height: 1,
                color: AppColors.kBorder.withValues(alpha: 0.6),
              ),
            ),
          ),
          body: Column(
            children: [
              // ── Messages list ──────────────────────────────────────────
              Expanded(
                child: provider.isLoading && provider.messages.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.kPrimary),
                      )
                    : provider.messages.isEmpty
                        ? Center(
                            child: Text(
                              'Aucun message. Dites bonjour !',
                              style: AppTextStyles.kBodyMedium.copyWith(
                                color: AppColors.kTextSecondary,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.kSpaceMd,
                              vertical: AppSpacing.kSpaceSm,
                            ),
                            itemCount: provider.messages.length,
                            itemBuilder: (_, i) {
                              final msg = provider.messages[i];
                              final isMine = msg.senderId == currentUserId;
                              return _MessageBubble(
                                message: msg,
                                isMine: isMine,
                              );
                            },
                          ),
              ),

              // ── Input bar ────────────────────────────────────────────
              _InputBar(
                controller: _textController,
                isSending: provider.isSending,
                isCreator: isCreator,
                conversationId: widget.conversationId,
                onSendText: _sendText,
                onScrollToBottom: _scrollToBottom,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── AppBar Title ─────────────────────────────────────────────────────────────

class _AppBarTitle extends StatelessWidget {
  final ConversationProvider provider;

  const _AppBarTitle({required this.provider});

  @override
  Widget build(BuildContext context) {
    // We show a placeholder if messages haven't loaded yet
    // The other user info would need to be passed separately in a full impl.
    return const Text(
      'Conversation',
      style: TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: AppColors.kTextPrimary,
      ),
    );
  }
}

// ─── Message Bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMine;

  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) const SizedBox(width: 4),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            child: switch (message.type) {
              MessageType.text => _TextBubble(message: message, isMine: isMine),
              MessageType.voice =>
                _VoiceBubble(message: message, isMine: isMine),
              MessageType.lockedContent =>
                _LockedContentBubble(message: message),
            },
          ),
          if (isMine) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ─── Text Bubble ─────────────────────────────────────────────────────────────

class _TextBubble extends StatelessWidget {
  final Message message;
  final bool isMine;

  const _TextBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMine ? AppColors.kPrimaryDark : AppColors.kBgSurface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMine ? 18 : 4),
          bottomRight: Radius.circular(isMine ? 4 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            message.body ?? '',
            style: AppTextStyles.kBodyMedium.copyWith(
              color: isMine ? Colors.white : AppColors.kTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatTime(message.createdAt),
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 10,
              color: isMine
                  ? Colors.white.withValues(alpha: 0.65)
                  : AppColors.kTextTertiary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ─── Voice Bubble ─────────────────────────────────────────────────────────────

class _VoiceBubble extends StatefulWidget {
  final Message message;
  final bool isMine;

  const _VoiceBubble({required this.message, required this.isMine});

  @override
  State<_VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<_VoiceBubble> {
  late final AudioPlayer _player;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription? _positionSub;
  StreamSubscription? _stateSub;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _positionSub = _player.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _stateSub = _player.playerStateStream.listen((s) {
      if (mounted) {
        setState(() => _isPlaying = s.playing);
        if (s.processingState == ProcessingState.completed) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
      return;
    }
    final url = widget.message.voiceUrl;
    if (url == null) return;
    try {
      if (_player.processingState == ProcessingState.idle) {
        final duration = await _player.setUrl(url);
        setState(() => _duration = duration ?? Duration.zero);
      }
      await _player.play();
    } catch (_) {}
  }

  String _fmtDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isMine = widget.isMine;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isMine ? AppColors.kPrimaryDark : AppColors.kBgSurface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMine ? 18 : 4),
          bottomRight: Radius.circular(isMine ? 4 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isMine
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.kPrimarySurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: isMine ? Colors.white : AppColors.kPrimary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: SliderComponentShape.noOverlay,
                    trackHeight: 2,
                    activeTrackColor:
                        isMine ? Colors.white : AppColors.kPrimary,
                    inactiveTrackColor: isMine
                        ? Colors.white.withValues(alpha: 0.3)
                        : AppColors.kBorder,
                    thumbColor:
                        isMine ? Colors.white : AppColors.kPrimaryDark,
                  ),
                  child: Slider(
                    value: _duration.inSeconds > 0
                        ? (_position.inSeconds / _duration.inSeconds).clamp(
                            0.0, 1.0)
                        : 0.0,
                    onChanged: (v) {
                      if (_duration.inSeconds > 0) {
                        _player.seek(Duration(
                            seconds: (v * _duration.inSeconds).round()));
                      }
                    },
                  ),
                ),
                Text(
                  _duration > Duration.zero
                      ? '${_fmtDuration(_position)} / ${_fmtDuration(_duration)}'
                      : '🎤 Vocal',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 10,
                    color: isMine
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppColors.kTextTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Locked Content Bubble ────────────────────────────────────────────────────

class _LockedContentBubble extends StatelessWidget {
  final Message message;

  const _LockedContentBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final lc = message.lockedContent;
    if (lc == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.kBgSurface,
          borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
          border: Border.all(color: AppColors.kBorder),
        ),
        child: const Text('🔒 Contenu exclusif'),
      );
    }

    return GestureDetector(
      onTap: () => context.push('/c/${lc.slug}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.kBgSurface,
          borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
          border: Border.all(color: AppColors.kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail / blur
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.kRadiusMd)),
              child: Stack(
                children: [
                  lc.blurUrl != null
                      ? Image.network(
                          lc.blurUrl!,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 120,
                            color: AppColors.kBgElevated,
                          ),
                        )
                      : Container(
                          height: 120,
                          color: AppColors.kBgElevated,
                        ),
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.35),
                      child: const Center(
                        child: Icon(
                          Icons.lock_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (lc.title != null)
                    Text(
                      lc.title!,
                      style: AppTextStyles.kBodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${lc.priceFcfa} FCFA',
                        style: AppTextStyles.kBodyMedium.copyWith(
                          color: AppColors.kSuccess,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.kPrimaryDark,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.kRadiusPill),
                        ),
                        child: const Text(
                          'Voir',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
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

// ─── Input Bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final bool isSending;
  final bool isCreator;
  final int conversationId;
  final VoidCallback onSendText;
  final VoidCallback onScrollToBottom;

  const _InputBar({
    required this.controller,
    required this.isSending,
    required this.isCreator,
    required this.conversationId,
    required this.onSendText,
    required this.onScrollToBottom,
  });

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    // Check microphone permission
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Permission micro requise'),
            content: const Text(
              'Autorisez l\'accès au microphone pour envoyer des messages vocaux.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
                child: const Text('Paramètres'),
              ),
            ],
          ),
        );
      }
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      setState(() {
        _isRecording = true;
        _recordingPath = path;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur enregistrement: $e'),
            backgroundColor: AppColors.kError,
          ),
        );
      }
    }
  }

  Future<void> _stopRecordingAndSend() async {
    if (!_isRecording) return;
    try {
      final path = await _recorder.stop();
      setState(() => _isRecording = false);
      if (path != null && mounted) {
        await context
            .read<ConversationProvider>()
            .sendVoice(File(path));
        widget.onScrollToBottom();
      }
    } catch (e) {
      setState(() => _isRecording = false);
    }
  }

  Future<void> _cancelRecording() async {
    if (!_isRecording) return;
    await _recorder.cancel();
    setState(() => _isRecording = false);
  }

  void _showLockedContentPicker() {
    // Navigate to MyContents and pick a content ID
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.kBgBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _LockedContentPickerSheet(
        onSelect: (contentId) async {
          Navigator.of(ctx).pop();
          await context
              .read<ConversationProvider>()
              .sendLockedContent(contentId);
          widget.onScrollToBottom();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.kBgSurface,
        border: Border(top: BorderSide(color: AppColors.kBorder, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.kSpaceMd,
            vertical: AppSpacing.kSpaceSm,
          ),
          child: _isRecording
              ? _RecordingBar(
                  onCancel: _cancelRecording,
                  onStop: _stopRecordingAndSend,
                )
              : Row(
                  children: [
                    // Locked content button (creator only)
                    if (widget.isCreator)
                      IconButton(
                        icon: const Icon(
                          Icons.lock_rounded,
                          color: AppColors.kTextSecondary,
                          size: 22,
                        ),
                        onPressed: _showLockedContentPicker,
                        tooltip: 'Envoyer un contenu exclusif',
                      ),
                    // Text input
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        style: AppTextStyles.kBodyMedium,
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Message...',
                          hintStyle: AppTextStyles.kCaption,
                          filled: true,
                          fillColor: AppColors.kBgElevated,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                AppSpacing.kRadiusPill),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.kSpaceSm),
                    // Send or mic button
                    widget.controller.text.trim().isNotEmpty
                        ? GestureDetector(
                            onTap: widget.isSending ? null : widget.onSendText,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: AppColors.kPrimaryDark,
                                shape: BoxShape.circle,
                              ),
                              child: widget.isSending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.send_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                            ),
                          )
                        : GestureDetector(
                            onLongPressStart: (_) => _startRecording(),
                            onLongPressEnd: (_) => _stopRecordingAndSend(),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.kBgElevated,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.kBorder),
                              ),
                              child: const Icon(
                                Icons.mic_rounded,
                                color: AppColors.kTextSecondary,
                                size: 20,
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

// ─── Recording Bar ────────────────────────────────────────────────────────────

class _RecordingBar extends StatefulWidget {
  final VoidCallback onCancel;
  final VoidCallback onStop;

  const _RecordingBar({required this.onCancel, required this.onStop});

  @override
  State<_RecordingBar> createState() => _RecordingBarState();
}

class _RecordingBarState extends State<_RecordingBar> {
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _elapsed {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Cancel
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              color: AppColors.kError, size: 24),
          onPressed: widget.onCancel,
        ),
        // Indicator
        const Icon(Icons.fiber_manual_record, color: AppColors.kError, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Enregistrement $_elapsed',
            style: AppTextStyles.kBodyMedium
                .copyWith(color: AppColors.kTextPrimary),
          ),
        ),
        // Send
        GestureDetector(
          onTap: widget.onStop,
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.kPrimaryDark,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.send_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Locked Content Picker Sheet ─────────────────────────────────────────────

class _LockedContentPickerSheet extends StatelessWidget {
  final void Function(int contentId) onSelect;

  const _LockedContentPickerSheet({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, controller) => Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.kBorder,
              borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.kSpaceMd, vertical: 8),
            child: Text(
              'Choisir un contenu exclusif',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.kTextPrimary,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.kBorder),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.kSpaceMd),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Entrez l\'ID du contenu à envoyer :',
                      style: AppTextStyles.kBodyMedium
                          .copyWith(color: AppColors.kTextSecondary),
                    ),
                    const SizedBox(height: AppSpacing.kSpaceMd),
                    _ContentIdInput(onSelect: onSelect),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentIdInput extends StatefulWidget {
  final void Function(int contentId) onSelect;

  const _ContentIdInput({required this.onSelect});

  @override
  State<_ContentIdInput> createState() => _ContentIdInputState();
}

class _ContentIdInputState extends State<_ContentIdInput> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'ID du contenu',
              hintStyle: AppTextStyles.kCaption,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
                borderSide: const BorderSide(color: AppColors.kBorder),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.kSpaceSm),
        ElevatedButton(
          onPressed: () {
            final id = int.tryParse(_ctrl.text.trim());
            if (id != null) widget.onSelect(id);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.kPrimaryDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
            ),
          ),
          child: const Text(
            'Envoyer',
            style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
                color: Colors.white),
          ),
        ),
      ],
    );
  }
}
