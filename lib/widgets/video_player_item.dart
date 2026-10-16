import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/video_post.dart';

class VideoCardItem extends StatefulWidget {
  final VideoPost post;
  final String currentUserId;
  final VoidCallback onToggleLike;
  final VoidCallback? onDelete;

  const VideoCardItem({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onToggleLike,
    this.onDelete,
  });

  @override
  State<VideoCardItem> createState() => _VideoCardItemState();
}

class _VideoCardItemState extends State<VideoCardItem> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.post.videoUrl),
    );
    try {
      await _controller.initialize();
      _controller.setLooping(true);
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isInitialized = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (!_isInitialized) return;
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = widget.post.isLikedBy(widget.currentUserId);
    final isAuthor = widget.post.authorUid == widget.currentUserId;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera con datos del autor
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                widget.post.authorEmail.isNotEmpty
                    ? widget.post.authorEmail[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              widget.post.authorEmail,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            trailing: isAuthor && widget.onDelete != null
                ? IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: 'Eliminar video',
                    onPressed: widget.onDelete,
                  )
                : null,
          ),

          // Reproductor de video
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              color: Colors.black12,
              constraints: const BoxConstraints(maxHeight: 400),
              child: _isInitialized
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                        if (!_controller.value.isPlaying)
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.black38,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(12),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: VideoProgressIndicator(
                            _controller,
                            allowScrubbing: true,
                            colors: VideoProgressColors(
                              playedColor: theme.colorScheme.primary,
                              bufferedColor: Colors.white24,
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox(
                      height: 220,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
            ),
          ),

          // Descripción y acciones
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.post.caption.isNotEmpty) ...[
                  Text(
                    widget.post.caption,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : null,
                      ),
                      onPressed: widget.onToggleLike,
                    ),
                    Text(
                      '${widget.post.likesCount} me gusta',
                      style: theme.textTheme.labelLarge,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
