import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/video_post.dart';

class VideoPlayerItem extends StatefulWidget {
  final VideoPost post;
  final String currentUserId;
  final bool isCurrentPage;
  final VoidCallback onToggleLike;
  final VoidCallback? onDelete;

  const VideoPlayerItem({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.isCurrentPage,
    required this.onToggleLike,
    this.onDelete,
  });

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showPlayIcon = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.post.videoUrl),
    );

    try {
      await _controller.initialize();
      _controller.setLooping(true);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        if (widget.isCurrentPage) {
          _controller.play();
          _isPlaying = true;
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant VideoPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCurrentPage != widget.isCurrentPage && _isInitialized) {
      if (widget.isCurrentPage) {
        _controller.play();
        setState(() => _isPlaying = true);
      } else {
        _controller.pause();
        setState(() => _isPlaying = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (!_isInitialized) return;
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
        _showPlayIcon = true;
      } else {
        _controller.play();
        _isPlaying = true;
        _showPlayIcon = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = widget.post.isLikedBy(widget.currentUserId);
    final isAuthor = widget.post.authorUid == widget.currentUserId;
    final username = widget.post.authorEmail.split('@').first;

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: _togglePlayPause,
          onDoubleTap: () {
            if (!isLiked) {
              widget.onToggleLike();
            }
          },
          child: Container(
            color: Colors.black,
            child: _isInitialized
                ? Center(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
          ),
        ),

        // Gradiente superior e inferior para legibilidad
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black54,
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black87,
                  ],
                  stops: [0.0, 0.15, 0.65, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),

        // Indicador de pausa al tocar
        if (_showPlayIcon && !_isPlaying)
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                size: 56,
                color: Colors.white70,
              ),
            ),
          ),

        // Barra de acciones a la derecha
        Positioned(
          right: 12,
          bottom: 40,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAvatar(username),
              const SizedBox(height: 18),
              _buildActionButton(
                icon: isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? const Color(0xFFFF2B54) : Colors.white,
                label: widget.post.likesCount.toString(),
                onTap: widget.onToggleLike,
              ),
              const SizedBox(height: 18),
              _buildActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                color: Colors.white,
                label: 'Comentar',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sección de comentarios'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              _buildActionButton(
                icon: Icons.share_rounded,
                color: Colors.white,
                label: 'Compartir',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enlace copiado al portapapeles'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              if (isAuthor && widget.onDelete != null) ...[
                const SizedBox(height: 18),
                _buildActionButton(
                  icon: Icons.delete_outline_rounded,
                  color: Colors.white70,
                  label: 'Borrar',
                  onTap: widget.onDelete!,
                ),
              ],
            ],
          ),
        ),

        // Información inferior (Usuario, Caption, Audio)
        Positioned(
          left: 16,
          right: 90,
          bottom: 30,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    '@$username',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.verified_rounded,
                    color: Color(0xFF20D5EC),
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (widget.post.caption.isNotEmpty)
                Text(
                  widget.post.caption,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.3,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.music_note_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Sonido original - @$username',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Barra de progreso del video
        if (_isInitialized)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Color(0xFFFF2B54),
                bufferedColor: Colors.white24,
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatar(String username) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        gradient: const LinearGradient(
          colors: [Color(0xFF20D5EC), Color(0xFFFF2B54)],
        ),
      ),
      child: Center(
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 34, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(blurRadius: 4, color: Colors.black)],
            ),
          ),
        ],
      ),
    );
  }
}
