import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class DetectedFaceInfo {
  /// Coordenadas normalizadas: 0.0 a 1.0 respecto de la foto original.
  final double centerX;
  final double eyesY;
  final double noseY;
  final double headTopY;
  final double faceWidth;
  final double scale;

  const DetectedFaceInfo({
    required this.centerX,
    required this.eyesY,
    required this.noseY,
    required this.headTopY,
    required this.faceWidth,
    required this.scale,
  });
}

class FaceDetectorService {
  /// Tamaño que Flutter utiliza para renderizar una foto, con la orientación
  /// EXIF aplicada. Se usa para convertir píxeles de ML Kit a valores 0..1.
  static Future<ui.Size> obtenerTamanoImagen(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final size = ui.Size(image.width.toDouble(), image.height.toDouble());
    image.dispose();
    codec.dispose();
    return size;
  }

  static Future<DetectedFaceInfo?> detectarRostro(File imageFile) async {
    FaceDetector? faceDetector;
    try {
      final imageSize = await obtenerTamanoImagen(imageFile);
      if (imageSize.isEmpty) return null;

      final inputImage = InputImage.fromFile(imageFile);
      faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableLandmarks: true,
          performanceMode: FaceDetectorMode.accurate,
        ),
      );
      final faces = await faceDetector.processImage(inputImage);
      if (faces.isEmpty) return null;

      // La cara más grande es la persona principal de la publicación.
      faces.sort((a, b) => (b.boundingBox.width * b.boundingBox.height)
          .compareTo(a.boundingBox.width * a.boundingBox.height));
      final face = faces.first;
      final box = face.boundingBox;
      final leftEye = face.landmarks[FaceLandmarkType.leftEye]?.position;
      final rightEye = face.landmarks[FaceLandmarkType.rightEye]?.position;
      final nose = face.landmarks[FaceLandmarkType.noseBase]?.position;

      final centerX = box.left + (box.width / 2);
      final eyesY = leftEye != null && rightEye != null
          ? (leftEye.y + rightEye.y) / 2
          : box.top + (box.height * 0.32);
      final noseY = nose?.y.toDouble() ?? box.top + (box.height * 0.55);
      final headTopY = box.top - (box.height * 0.25);

      final normalizedFaceWidth =
          (box.width / imageSize.width).clamp(0.08, 0.95).toDouble();
      // La escala ya no depende de los megapíxeles de la cámara.
      final suggestedScale =
          (normalizedFaceWidth * 2.0).clamp(0.45, 2.2).toDouble();

      return DetectedFaceInfo(
        centerX: (centerX / imageSize.width).clamp(0.0, 1.0).toDouble(),
        eyesY: (eyesY / imageSize.height).clamp(0.0, 1.0).toDouble(),
        noseY: (noseY / imageSize.height).clamp(0.0, 1.0).toDouble(),
        headTopY: (headTopY / imageSize.height).clamp(0.0, 1.0).toDouble(),
        faceWidth: normalizedFaceWidth,
        scale: suggestedScale,
      );
    } catch (e) {
      debugPrint('Error en detección facial: $e');
      return null;
    } finally {
      await faceDetector?.close();
    }
  }
}
