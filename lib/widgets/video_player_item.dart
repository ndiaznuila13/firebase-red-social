import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/post_filter.dart';
import '../models/video_post.dart';
import '../services/video_repository.dart';
import 'media_filter_overlay.dart';

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

class _VideoCardItemState extends State<VideoCardItem>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _showHeartAnimation = false;
  late AnimationController _heartAnimController;
  late Animation<double> _heartScaleAnimation;
  final VideoRepository _videoRepo = VideoRepository();

  @override
  void initState() {
    super.initState();
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _heartScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40),
    ]).animate(_heartAnimController);

    if (widget.post.isVideo) {
      _initController();
    }
  }

  @override
  void didUpdateWidget(covariant VideoCardItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post.isVideo && oldWidget.post.videoUrl != widget.post.videoUrl) {
      _controller?.dispose();
      _isInitialized = false;
      _initController();
    }
  }

  Future<void> _initController() async {
    final uri = Uri.tryParse(widget.post.videoUrl);
    if (uri == null) return;

    _controller = VideoPlayerController.networkUrl(uri);
    try {
      await _controller!.initialize();
      _controller!.setLooping(true);
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
    _heartAnimController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  void _handleDoubleTap() {
    if (!widget.post.isLikedBy(widget.currentUserId)) {
      widget.onToggleLike();
    }
    setState(() => _showHeartAnimation = true);
    _heartAnimController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() => _showHeartAnimation = false);
      }
    });
  }

  void _abrirSelectorFiltros(BuildContext context) {
    String? tempFilter = widget.post.filter;
    double? tempNormX = widget.post.filterX;
    double? tempNormY = widget.post.filterY;
    double tempScale = widget.post.filterScale ?? 1.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        'Filtros para esta publicación',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (tempFilter != null)
                        Text(
                          'Arrastra a la cara',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Vista previa interactiva con el filtro seleccionado
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      alignment: Alignment.center,
                      children: [
                        if (widget.post.isVideo &&
                            _controller != null &&
                            _isInitialized)
                          FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: _controller!.value.size.width,
                              height: _controller!.value.size.height,
                              child: VideoPlayer(_controller!),
                            ),
                          )
                        else if (widget.post.isImage)
                          Builder(
                            builder: (context) {
                              if (widget.post.videoUrl.startsWith('data:image')) {
                                try {
                                  final base64Part = widget.post.videoUrl.contains(',')
                                      ? widget.post.videoUrl.substring(widget.post.videoUrl.indexOf(',') + 1)
                                      : widget.post.videoUrl;
                                  final cleanStr = base64Part.replaceAll(RegExp(r'\s+'), '');
                                  return Image.memory(
                                    base64Decode(cleanStr),
                                    fit: BoxFit.contain,
                                  );
                                } catch (_) {
                                  return const Center(
                                    child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
                                  );
                                }
                              }
                              return Image.network(
                                widget.post.videoUrl,
                                fit: BoxFit.contain,
                              );
                            },
                          )
                        else
                          const Center(
                            child: Icon(Icons.videocam, color: Colors.white54, size: 48),
                          ),
                        if (tempFilter != null)
                          MediaFilterOverlay(
                            filterId: tempFilter,
                            interactive: true,
                            normalizedX: tempNormX,
                            normalizedY: tempNormY,
                            scale: tempScale,
                            onTransformChanged: (nx, ny, s) {
                              tempNormX = nx;
                              tempNormY = ny;
                              tempScale = s;
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Selecciona un filtro divertido:',
                    style: theme.textTheme.labelMedium,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: PostFilterOption.options.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final option = PostFilterOption.options[i];
                        final isSelected = (tempFilter == null && option.type == PostFilterType.none) ||
                            tempFilter == option.id;

                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              tempFilter = option.type == PostFilterType.none ? null : option.id;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 75,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  option.emoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  option.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected
                                        ? theme.colorScheme.onPrimaryContainer
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      try {
                        await _videoRepo.actualizarFiltro(
                          videoId: widget.post.id,
                          filter: tempFilter,
                          filterX: tempNormX,
                          filterY: tempNormY,
                          filterScale: tempScale,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Filtro guardado en la publicación'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al actualizar filtro: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Guardar filtro en el video'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
            subtitle: widget.post.filter != null
                ? Row(
                    children: [
                      Text(
                        '${PostFilterOption.fromId(widget.post.filter).emoji} ${PostFilterOption.fromId(widget.post.filter).label}',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : null,
            trailing: isAuthor && widget.onDelete != null
                ? IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: 'Eliminar publicación',
                    onPressed: widget.onDelete,
                  )
                : null,
          ),

          // Contenedor multimedia (Imagen o Video) con overlay de filtro y doble tap
          GestureDetector(
            onDoubleTap: _handleDoubleTap,
            onTap: widget.post.isVideo ? _togglePlay : null,
            child: Container(
              color: Colors.black12,
              constraints: const BoxConstraints(minHeight: 240, maxHeight: 420),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.post.isVideo) ...[
                    if (_isInitialized && _controller != null)
                      AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      )
                    else
                      const SizedBox(
                        height: 240,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    if (_isInitialized &&
                        _controller != null &&
                        !_controller!.value.isPlaying)
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
                    if (_isInitialized && _controller != null)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: VideoProgressIndicator(
                          _controller!,
                          allowScrubbing: true,
                          colors: VideoProgressColors(
                            playedColor: theme.colorScheme.primary,
                            bufferedColor: Colors.white24,
                          ),
                        ),
                      ),
                  ] else ...[
                    if (widget.post.videoUrl.startsWith('data:image'))
                      Builder(
                        builder: (context) {
                          try {
                            final base64Part = widget.post.videoUrl.contains(',')
                                ? widget.post.videoUrl.substring(widget.post.videoUrl.indexOf(',') + 1)
                                : widget.post.videoUrl;
                            final cleanStr = base64Part.replaceAll(RegExp(r'\s+'), '');
                            final bytes = base64Decode(cleanStr);
                            return Image.memory(
                              bytes,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              gaplessPlayback: true,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 240,
                                  color: Colors.black12,
                                  alignment: Alignment.center,
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('No se pudo cargar la imagen'),
                                    ],
                                  ),
                                );
                              },
                            );
                          } catch (_) {
                            return Container(
                              height: 240,
                              color: Colors.black12,
                              alignment: Alignment.center,
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Error al decodificar imagen'),
                                ],
                              ),
                            );
                          }
                        },
                      )
                    else
                      Image.network(
                        widget.post.videoUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const SizedBox(
                          height: 240,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.black12,
                          alignment: Alignment.center,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('No se pudo cargar la imagen'),
                            ],
                          ),
                        );
                      },
                    ),
                  ],

                  // Filtro superpuesto sobre el video o imagen
                  if (widget.post.filter != null)
                    MediaFilterOverlay(
                      filterId: widget.post.filter,
                      normalizedX: widget.post.filterX,
                      normalizedY: widget.post.filterY,
                      scale: widget.post.filterScale,
                    ),

                  // Animación de corazón gigante al hacer doble tap
                  if (_showHeartAnimation)
                    ScaleTransition(
                      scale: _heartScaleAnimation,
                      child: const Icon(
                        Icons.favorite,
                        size: 100,
                        color: Colors.redAccent,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Botones de acción (Like, Filtro y contador)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : null,
                        size: 26,
                      ),
                      tooltip: isLiked ? 'Ya no me gusta' : 'Me gusta',
                      onPressed: widget.onToggleLike,
                    ),
                    Text(
                      '${widget.post.likesCount} me gusta',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // Botón para agregar o cambiar filtros a videos ya existentes
                    TextButton.icon(
                      onPressed: () => _abrirSelectorFiltros(context),
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: Text(
                        widget.post.filter == null ? 'Filtro' : 'Editar filtro',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                if (widget.post.caption.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 4),
                    child: Text(
                      widget.post.caption,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
