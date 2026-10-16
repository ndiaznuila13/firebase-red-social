import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/video_post.dart';
import '../services/auth_service.dart';
import '../services/video_repository.dart';

class ProfileScreen extends StatelessWidget {
  final User usuario;

  const ProfileScreen({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    final videoRepo = VideoRepository();
    final authService = AuthService();
    final username = usuario.email?.split('@').first ?? 'usuario';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          '@$username',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            onPressed: () => _mostrarDialogoCerrarSesion(context, authService),
          ),
        ],
      ),
      body: StreamBuilder<List<VideoPost>>(
        stream: videoRepo.obtenerVideosDeUsuario(usuario.uid),
        builder: (context, snapshot) {
          final misVideos = snapshot.data ?? [];
          final totalLikes = misVideos.fold<int>(
            0,
            (acc, video) => acc + video.likesCount,
          );

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF20D5EC),
                            width: 3,
                          ),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF20D5EC), Color(0xFFFF2B54)],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            username.isNotEmpty ? username[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        usuario.email ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStatItem('Videos', misVideos.length.toString()),
                          _buildDivider(),
                          _buildStatItem('Likes recibidos', totalLikes.toString()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: Colors.white12),
                    ],
                  ),
                ),
              ),
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF20D5EC),
                    ),
                  ),
                )
              else if (misVideos.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.video_camera_back_outlined,
                            size: 48,
                            color: Colors.white24,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No has subido ningún video aún',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(4),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 3,
                      mainAxisSpacing: 3,
                      childAspectRatio: 0.75,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final video = misVideos[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF141414),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              const Center(
                                child: Icon(
                                  Icons.play_circle_outline_rounded,
                                  color: Colors.white38,
                                  size: 32,
                                ),
                              ),
                              Positioned(
                                bottom: 6,
                                left: 6,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.favorite_rounded,
                                      size: 14,
                                      color: Color(0xFFFF2B54),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      video.likesCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: misVideos.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.white12,
    );
  }

  void _mostrarDialogoCerrarSesion(
      BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Cerrar sesión', style: TextStyle(color: Colors.white)),
        content: const Text(
          '¿Estás seguro de que deseas salir de tu cuenta?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF2B54),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await authService.cerrarSesion();
            },
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }
}
