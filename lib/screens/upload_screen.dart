import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/video_repository.dart';

class UploadScreen extends StatefulWidget {
  final User usuario;

  const UploadScreen({super.key, required this.usuario});

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
      'caption': 'Explorando nuevos lugares 🌿✨',
    },
    {
      'titulo': 'Deportes',
      'url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      'caption': 'Superando límites 🔥⚡',
    },
    {
      'titulo': 'Aventura',
      'url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
      'caption': 'Viviendo el momento 🚀',
    },
    {
      'titulo': 'Música',
      'url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyBlazes.mp4',
      'caption': 'Buena música y buena vibra 🎵',
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
    } catch (_) {
      if (mounted) {
        setState(() {
          _previewController = null;
          _isLoadingPreview = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo reproducir la URL del video.')),
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
        const SnackBar(content: Text('Ingresa la URL de un video')),
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
          const SnackBar(content: Text('Video publicado con éxito en Firestore')),
        );
        Navigator.of(context).pop();
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicar video'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vista previa
            Card(
              clipBehavior: Clip.antiAlias,
              child: Container(
                height: 220,
                color: Colors.black12,
                child: _isLoadingPreview
                    ? const Center(child: CircularProgressIndicator())
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
                              Icon(Icons.video_library_outlined, size: 48),
                              SizedBox(height: 8),
                              Text('Vista previa del video'),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 16),

            // Chips rápidos
            Text(
              'Videos de muestra rápidos:',
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _videosEjemplo.map((preset) {
                final isSelected = _urlController.text == preset['url'];
                return ChoiceChip(
                  label: Text(preset['titulo']!),
                  selected: isSelected,
                  onSelected: (_) => _seleccionarPreset(preset),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // URL del video
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'URL del video (MP4)',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Previsualizar',
                  onPressed: () => _cargarVistaPrevia(_urlController.text),
                ),
              ),
              onSubmitted: _cargarVistaPrevia,
            ),
            const SizedBox(height: 16),

            // Descripción
            TextField(
              controller: _captionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Descripción de la publicación',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Botón publicar
            FilledButton.icon(
              onPressed: _isPublishing ? null : _publicar,
              icon: _isPublishing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: const Text('Publicar en Firestore'),
            ),
          ],
        ),
      ),
    );
  }
}
