import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// Lecteur vidéo HLS adaptatif.
///
/// Utilise [VideoPlayerController.networkUrl] qui supporte nativement
/// les flux HLS (.m3u8) sur iOS (AVPlayer) et Android (ExoPlayer).
///
/// Fonctionnalités :
///  - Indicateur de chargement pendant l'initialisation
///  - Lecture / pause via tap ou bouton
///  - Barre de progression [VideoProgressIndicator]
///  - Ratio d'affichage 16:9 par défaut via [AspectRatio]
///  - Bouton plein écran (push d'une nouvelle route avec contrôleur partagé)
class HlsVideoPlayer extends StatefulWidget {
  final String hlsUrl;

  const HlsVideoPlayer({super.key, required this.hlsUrl});

  @override
  State<HlsVideoPlayer> createState() => _HlsVideoPlayerState();
}

class _HlsVideoPlayerState extends State<HlsVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.hlsUrl),
    );

    _controller.addListener(_onControllerUpdate);

    try {
      await _controller.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
        _controller.play();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _showControls = true;
      } else {
        _controller.play();
        _showControls = false;
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  Future<void> _openFullscreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FullscreenPlayer(controller: _controller),
      ),
    );
    // Restaurer l'orientation portrait au retour
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    color: Colors.white54, size: 40),
                SizedBox(height: 8),
                Text(
                  'Impossible de lire la vidéo',
                  style: TextStyle(
                    color: Colors.white54,
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // ── Vidéo ────────────────────────────────────────────────────────
            VideoPlayer(_controller),

            // ── Overlay contrôles ────────────────────────────────────────────
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black54],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Boutons centraux
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Reculer 10 s
                        IconButton(
                          icon: const Icon(Icons.replay_10_rounded,
                              color: Colors.white, size: 32),
                          onPressed: () {
                            final pos = _controller.value.position;
                            _controller.seekTo(
                              pos - const Duration(seconds: 10),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        // Play / Pause
                        GestureDetector(
                          onTap: _togglePlayPause,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                            child: Icon(
                              _controller.value.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Avancer 10 s
                        IconButton(
                          icon: const Icon(Icons.forward_10_rounded,
                              color: Colors.white, size: 32),
                          onPressed: () {
                            final pos = _controller.value.position;
                            _controller.seekTo(
                              pos + const Duration(seconds: 10),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Barre de progression
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: Colors.white,
                          bufferedColor: Colors.white38,
                          backgroundColor: Colors.white12,
                        ),
                      ),
                    ),
                    // Durée + plein écran
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 8, 6),
                      child: Row(
                        children: [
                          Text(
                            _formatDuration(_controller.value.position),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                            ),
                          ),
                          const Text(
                            ' / ',
                            style: TextStyle(
                                color: Colors.white38,
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 12),
                          ),
                          Text(
                            _formatDuration(_controller.value.duration),
                            style: const TextStyle(
                              color: Colors.white38,
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.fullscreen_rounded,
                                color: Colors.white70, size: 22),
                            onPressed: _openFullscreen,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$m:$s';
    }
    return '$m:$s';
  }
}

// ─── _FullscreenPlayer ────────────────────────────────────────────────────────

/// Route plein écran — utilise le même [VideoPlayerController] sans l'initialiser
/// à nouveau. Passe en landscape automatiquement.
class _FullscreenPlayer extends StatefulWidget {
  final VideoPlayerController controller;

  const _FullscreenPlayer({required this.controller});

  @override
  State<_FullscreenPlayer> createState() => _FullscreenPlayerState();
}

class _FullscreenPlayerState extends State<_FullscreenPlayer> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    widget.controller.addListener(_update);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _update() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: AspectRatio(
            aspectRatio: widget.controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                VideoPlayer(widget.controller),
                // Bouton fermer
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                      child: const Icon(Icons.fullscreen_exit_rounded,
                          color: Colors.white, size: 24),
                    ),
                  ),
                ),
                // Barre de progression
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
                  child: VideoProgressIndicator(
                    widget.controller,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Colors.white,
                      bufferedColor: Colors.white38,
                      backgroundColor: Colors.white12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
