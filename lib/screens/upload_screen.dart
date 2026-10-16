import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../models/post_filter.dart';
import '../services/face_detector_service.dart';
import '../services/storage_service.dart';
import '../services/video_repository.dart';
import '../widgets/media_filter_overlay.dart';

class UploadScreen extends StatefulWidget {
  final User usuario;

  const UploadScreen({super.key, required this.usuario});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final VideoRepository _videoRepo = VideoRepository();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _captionController = TextEditingController();

  File? _selectedFile;
  bool _isImage = false;
  VideoPlayerController? _previewController;

  String? _selectedFilter;
  double? _filterNormX;
  double? _filterNormY;
  double _filterScale = 1.0;
  double? _imageAspectRatio;

  bool _isPublishing = false;
  bool _isLoadingMedia = false;
  bool _isDetectingFace = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _recuperarDatosPerdidosAndroid();
  }

  Future<void> _recuperarDatosPerdidosAndroid() async {
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty || response.file == null) return;

      final file = File(response.file!.path);
      final isImg = !file.path.toLowerCase().endsWith('.mp4') &&
          !file.path.toLowerCase().endsWith('.mov');
      final imageSize =
          isImg ? await FaceDetectorService.obtenerTamanoImagen(file) : null;

      setState(() {
        _selectedFile = file;
        _isImage = isImg;
        _imageAspectRatio = imageSize == null
            ? null
            : imageSize.width / imageSize.height;
      });

      if (isImg) {
        _detectarYUbicarEnRostro(file);
      } else {
        _inicializarVideo(file);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _captionController.dispose();
    _previewController?.dispose();
    super.dispose();
  }

  Future<void> _inicializarVideo(File file) async {
    _previewController?.dispose();
    final controller = VideoPlayerController.file(file);
    await controller.initialize();
    controller.setLooping(true);
    controller.play();
    if (mounted) {
      setState(() => _previewController = controller);
    }
  }

  Future<void> _detectarYUbicarEnRostro(File imageFile) async {
    setState(() => _isDetectingFace = true);
    final faceInfo = await FaceDetectorService.detectarRostro(imageFile);
    if (!mounted) return;

    if (faceInfo != null) {
      // Ajustamos posición según el tipo de filtro
      double targetY = faceInfo.eyesY;
      final opt = PostFilterOption.fromId(_selectedFilter);
      if (opt.type == PostFilterType.sunglasses ||
          opt.type == PostFilterType.partyGlasses) {
        targetY = faceInfo.eyesY;
      } else if (opt.type == PostFilterType.mustache) {
        targetY = faceInfo.noseY + (faceInfo.faceWidth * 0.10);
      } else if (opt.type == PostFilterType.birthdayCone ||
          opt.type == PostFilterType.funnyHat ||
          opt.type == PostFilterType.crown ||
          opt.type == PostFilterType.catEars) {
        targetY = faceInfo.headTopY;
      }

      setState(() {
        _filterNormX = faceInfo.centerX;
        _filterNormY = targetY.clamp(0.0, 1.0).toDouble();
        _filterScale = faceInfo.scale;
        _isDetectingFace = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rostro detectado: filtro alineado a la persona'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      setState(() => _isDetectingFace = false);
    }
  }

  Future<void> _seleccionarImagen(ImageSource source) async {
    try {
      setState(() => _isLoadingMedia = true);
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 960,
        maxHeight: 1280,
        imageQuality: 75,
      );

      if (file == null) {
        setState(() => _isLoadingMedia = false);
        return;
      }

      _previewController?.dispose();
      _previewController = null;

      final imageFile = File(file.path);
      final imageSize = await FaceDetectorService.obtenerTamanoImagen(imageFile);
      setState(() {
        _selectedFile = imageFile;
        _isImage = true;
        _imageAspectRatio = imageSize.width / imageSize.height;
        _isLoadingMedia = false;
      });

      await _detectarYUbicarEnRostro(imageFile);
    } catch (e) {
      setState(() => _isLoadingMedia = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al capturar foto: $e')),
        );
      }
    }
  }

  Future<void> _seleccionarVideo(ImageSource source) async {
    try {
      setState(() => _isLoadingMedia = true);
      final XFile? file = await _picker.pickVideo(source: source);

      if (file == null) {
        setState(() => _isLoadingMedia = false);
        return;
      }

      final videoFile = File(file.path);
      setState(() {
        _selectedFile = videoFile;
        _isImage = false;
        _imageAspectRatio = null;
        _isLoadingMedia = false;
      });

      await _inicializarVideo(videoFile);
    } catch (e) {
      setState(() => _isLoadingMedia = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al capturar video: $e')),
        );
      }
    }
  }

  Future<void> _publicar() async {
    if (_selectedFile == null) {
      _mostrarOpcionesOrigen();
      return;
    }

    setState(() {
      _isPublishing = true;
      _uploadProgress = 0.0;
    });

    try {
      final mediaType = _isImage ? 'image' : 'video';

      final downloadUrl = await _storageService.subirArchivo(
        archivo: _selectedFile!,
        esVideo: !_isImage,
        onProgreso: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );

      await _videoRepo.publicarPost(
        mediaUrl: downloadUrl,
        mediaType: mediaType,
        caption: _captionController.text,
        usuario: widget.usuario,
        filter: _selectedFilter,
        filterX: _filterNormX,
        filterY: _filterNormY,
        filterScale: _filterScale,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publicado exitosamente en Firebase')),
        );
        Navigator.of(context).pop();
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() => _isPublishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('FirebaseException [${e.code}]: ${e.message ?? 'Sin detalle'}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPublishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir: $e')),
        );
      }
    }
  }

  void _mostrarOpcionesOrigen() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Seleccionar archivo para publicar',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.camera_alt, color: Colors.white),
                ),
                title: const Text('Tomar foto con la cámara'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _seleccionarImagen(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.photo_library, color: Colors.white),
                ),
                title: const Text('Elegir foto de la galería'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _seleccionarImagen(ImageSource.gallery);
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.deepOrange,
                  child: Icon(Icons.videocam, color: Colors.white),
                ),
                title: const Text('Grabar video con la cámara'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _seleccionarVideo(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.purple,
                  child: Icon(Icons.video_library, color: Colors.white),
                ),
                title: const Text('Elegir video de la galería'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _seleccionarVideo(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMedia = _selectedFile != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva publicación'),
        actions: [
          if (hasMedia)
            IconButton(
              icon: const Icon(Icons.replay_outlined),
              tooltip: 'Cambiar archivo',
              onPressed: _isPublishing ? null : _mostrarOpcionesOrigen,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vista previa con overlay interactivo para ubicar en la persona
            Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                height: 340,
                color: Colors.black,
                child: Stack(
                  alignment: Alignment.center,
                  fit: StackFit.expand,
                  children: [
                    if (_isLoadingMedia)
                      const Center(child: CircularProgressIndicator())
                    else if (hasMedia && _isImage)
                      Image.file(
                        _selectedFile!,
                        fit: BoxFit.contain,
                      )
                    else if (hasMedia &&
                        _previewController != null &&
                        _previewController!.value.isInitialized)
                      FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: _previewController!.value.size.width,
                          height: _previewController!.value.size.height,
                          child: VideoPlayer(_previewController!),
                        ),
                      )
                    else
                      InkWell(
                        onTap: _mostrarOpcionesOrigen,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 48,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Toma una foto o video',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Cámara o Galería de tu dispositivo',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Filtro interactivo que se puede arrastrar y escalar sobre la persona
                    if (hasMedia && _selectedFilter != null)
                      MediaFilterOverlay(
                        filterId: _selectedFilter,
                        interactive: true,
                        normalizedX: _filterNormX,
                        normalizedY: _filterNormY,
                        scale: _filterScale,
                        mediaAspectRatio: _isImage ? _imageAspectRatio : null,
                        onTransformChanged: (nx, ny, s) {
                          _filterNormX = nx;
                          _filterNormY = ny;
                          _filterScale = s;
                        },
                      ),

                    // Indicador de análisis facial
                    if (_isDetectingFace)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Detectando rostro...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (hasMedia && _selectedFilter != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Tamaño:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    iconSize: 18,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove),
                    tooltip: 'Más pequeño',
                    onPressed: () {
                      setState(() {
                        _filterScale = (_filterScale - 0.15).clamp(0.4, 3.0);
                      });
                    },
                  ),
                  const SizedBox(width: 4),
                  IconButton.filledTonal(
                    iconSize: 18,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add),
                    tooltip: 'Más grande',
                    onPressed: () {
                      setState(() {
                        _filterScale = (_filterScale + 0.15).clamp(0.4, 3.0);
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.center_focus_strong, size: 16),
                    label: const Text('Alinear rostro', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      if (_selectedFile != null && _isImage) {
                        _detectarYUbicarEnRostro(_selectedFile!);
                      } else {
                        setState(() {
                          _filterNormX = 0.5;
                          _filterNormY = 0.35;
                          _filterScale = 1.0;
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),

            // Botones de acceso rápido
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _isPublishing
                        ? null
                        : () => _seleccionarImagen(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Tomar Foto'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _isPublishing
                        ? null
                        : () => _seleccionarImagen(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galería'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _isPublishing
                        ? null
                        : () => _seleccionarVideo(ImageSource.camera),
                    icon: const Icon(Icons.videocam),
                    label: const Text('Video'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Selector horizontal de filtros
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Elige un filtro:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_selectedFilter != null && hasMedia)
                  Text(
                    '👉 Arrastra el filtro a la cara',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 82,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: PostFilterOption.options.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final option = PostFilterOption.options[i];
                  final isSelected =
                      (_selectedFilter == null && option.type == PostFilterType.none) ||
                          _selectedFilter == option.id;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter =
                            option.type == PostFilterType.none ? null : option.id;
                      });
                      if (_selectedFile != null && _isImage) {
                        _detectarYUbicarEnRostro(_selectedFile!);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 76,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(option.emoji, style: const TextStyle(fontSize: 22)),
                          const SizedBox(height: 4),
                          Text(
                            option.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
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
            const SizedBox(height: 16),

            // Campo de descripción
            TextField(
              controller: _captionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: '¿Qué estás compartiendo hoy?',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      // Botón de publicación fijo y siempre visible en la parte inferior
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isPublishing) ...[
                LinearProgressIndicator(
                  value: _uploadProgress > 0 ? _uploadProgress : null,
                ),
                const SizedBox(height: 8),
                Text(
                  _uploadProgress > 0
                      ? 'Subiendo a Firebase: ${(_uploadProgress * 100).toInt()}%'
                      : 'Preparando archivo...',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
              ],
              FilledButton.icon(
                onPressed: _isPublishing
                    ? null
                    : (hasMedia ? _publicar : _mostrarOpcionesOrigen),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: _isPublishing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(hasMedia ? Icons.cloud_upload : Icons.camera_alt),
                label: Text(
                  _isPublishing
                      ? 'Publicando en Firebase...'
                      : (hasMedia
                          ? 'Publicar en Firebase'
                          : 'Tomar foto o elegir archivo'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
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
