import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/video_repository.dart';

class UploadScreen extends StatefulWidget {
  final User usuario;
  final VoidCallback onVideoSubido;

  const UploadScreen({
    super.key,
    required this.usuario,
    required this.onVideoSubido,
  });

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final VideoRepository _videoRepo = VideoRepository();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();

  VideoPlayerController? _previewController;
  bool _isPublishing = false;
  bool _isLoadingPreview = false;

  final List<Map<String, String>> _videosEjemplo = [
    {
      'titulo': 'Naturaleza',
      'url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
      'caption': 'Explorando nuevos lugares 🌿✨ #naturaleza #viajes',
    },
    {
      'titulo': 'Deportes',
      'url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      'caption': 'Superando límites 🔥⚡ #fitness #motivacion',
    },
    {
      'titulo': 'Aventura',
      'url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
      'caption': 'Viviendo el momento 🚀 #aventura #lifestyle',
    },
    {
      'titulo': 'Música / Fiesta',
      'url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyBlazes.mp4',
      'caption': 'Buena vibra hoy 🎵🎉 #musica #fiesta',
    },
  ];

  @override
  void dispose() {
    _urlController.dispose();
    _captionController.dispose();
    _previewController?.dispose();
    super.dispose();
  }

  Future<void> _cargarVistaPrevia(String url) async {
    if (url.trim().isEmpty) return;

    setState(() => _isLoadingPreview = true);
    _previewController?.dispose();

    try {
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(url.trim()));
      await controller.initialize();
      controller.setLooping(true);
      controller.play();

      if (mounted) {
        setState(() {
          _previewController = controller;
          _isLoadingPreview = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _previewController = null;
          _isLoadingPreview = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo reproducir la URL del video.'),
            backgroundColor: Color(0xFFFF2B54),
          ),
        );
      }
    }
  }

  void _seleccionarPreset(Map<String, String> preset) {
    _urlController.text = preset['url']!;
    _captionController.text = preset['caption']!;
    _cargarVistaPrevia(preset['url']!);
  }

  Future<void> _publicar() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa o selecciona un video')),
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      await _videoRepo.publicarVideo(
        videoUrl: url,
        caption: _captionController.text,
        usuario: widget.usuario,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Video publicado en tu feed!'),
            backgroundColor: Color(0xFF20D5EC),
          ),
        );
        _urlController.clear();
        _captionController.clear();
        _previewController?.dispose();
        _previewController = null;
        setState(() => _isPublishing = false);
        widget.onVideoSubido();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPublishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al publicar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Nuevo video',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vista previa del video
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _isLoadingPreview
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF20D5EC),
                        ),
                      )
                    : _previewController != null &&
                            _previewController!.value.isInitialized
                        ? AspectRatio(
                            aspectRatio:
                                _previewController!.value.aspectRatio,
                            child: VideoPlayer(_previewController!),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.play_circle_outline_rounded,
                                size: 54,
                                color: Colors.white38,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Selecciona o pega un video para previsualizar',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 20),

            // Plantillas rápidas de prueba
            const Text(
              'Videos de muestra rápidos:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _videosEjemplo.map((preset) {
                  final isSelected = _urlController.text == preset['url'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      backgroundColor: isSelected
                          ? const Color(0xFFFF2B54)
                          : const Color(0xFF1F1F1F),
                      label: Text(
                        preset['titulo']!,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      onPressed: () => _seleccionarPreset(preset),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Campo de URL personalizada
            TextField(
              controller: _urlController,
              enabled: !_isPublishing,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Enlace del video (MP4)',
                labelStyle: const TextStyle(color: Colors.white60),
                hintText: 'https://ejemplo.com/video.mp4',
                hintStyle: const TextStyle(color: Colors.white24),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: Color(0xFF20D5EC)),
                  tooltip: 'Cargar previsualización',
                  onPressed: () => _cargarVistaPrevia(_urlController.text),
                ),
                filled: true,
                fillColor: const Color(0xFF141414),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF20D5EC)),
                ),
              ),
              onSubmitted: _cargarVistaPrevia,
            ),
            const SizedBox(height: 16),

            // Campo de descripción
            TextField(
              controller: _captionController,
              enabled: !_isPublishing,
              maxLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Descripción / Hashtags',
                labelStyle: const TextStyle(color: Colors.white60),
                hintText: 'Escribe algo sobre este video...',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF141414),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF20D5EC)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botón de publicar
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF2B54),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isPublishing ? null : _publicar,
              child: _isPublishing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Publicar en Firestore',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
