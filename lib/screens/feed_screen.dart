import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/video_post.dart';
import '../services/video_repository.dart';
import '../widgets/video_player_item.dart';

class FeedScreen extends StatelessWidget {
  final User usuario;

  const FeedScreen({super.key, required this.usuario});

  void _confirmarEliminacion(BuildContext context, VideoRepository repo, VideoPost post) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: const Text('¿Deseas eliminar este video de la base de datos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await repo.eliminarVideo(videoId: post.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Video eliminado')),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No se pudo eliminar el video')),
                  );
                }
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final videoRepo = VideoRepository();

    return StreamBuilder<List<VideoPost>>(
      stream: videoRepo.obtenerFeed(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error al cargar el feed: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final videos = snapshot.data ?? [];

        if (videos.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.video_library_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay videos publicados',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Presiona el botón inferior para publicar el primer video.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final post = videos[index];
            return VideoCardItem(
              key: ValueKey(post.id),
              post: post,
              currentUserId: usuario.uid,
              onToggleLike: () => videoRepo.alternarLike(
                videoId: post.id,
                uid: usuario.uid,
                estaLikeado: post.isLikedBy(usuario.uid),
              ),
              onDelete: post.authorUid == usuario.uid
                  ? () => _confirmarEliminacion(context, videoRepo, post)
                  : null,
            );
          },
        );
      },
    );
  }
}
