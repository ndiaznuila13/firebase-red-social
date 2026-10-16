import 'dart:convert';
import 'dart:io';

class StorageService {
  Future<String> subirArchivo({
    required File archivo,
    required bool esVideo,
    void Function(double progreso)? onProgreso,
  }) async {
    final extension = archivo.path.split('.').last.toLowerCase();
    final mimeType = _obtenerMimeType(extension, esVideo);

    if (onProgreso != null) onProgreso(0.3);

    if (!esVideo) {
      final bytes = await archivo.readAsBytes();
      if (onProgreso != null) onProgreso(0.8);

      final base64String = base64Encode(bytes);
      final dataUri = 'data:$mimeType;base64,$base64String';

      if (onProgreso != null) onProgreso(1.0);
      return dataUri;
    } else {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${archivo.path.split(Platform.pathSeparator).last}';
      final uri = Uri.parse(
        'https://zyasdqiavlhairxcfcbo.supabase.co/storage/v1/object/videos/$fileName',
      );

      final client = HttpClient();
      try {
        final request = await client.postUrl(uri);
        const anonKey =
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp5YXNkcWlhdmxoYWlyeGNmY2JvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAxMjA4NDIsImV4cCI6MjEwNTY5Njg0Mn0.PqAE7U0gObNkjLgqFr-0BukXBGSqd_M6ZYWW8mm46yg';

        request.headers.set('Authorization', 'Bearer $anonKey');
        request.headers.set('apikey', anonKey);
        request.headers.set('Content-Type', mimeType);

        final bytes = await archivo.readAsBytes();
        if (onProgreso != null) onProgreso(0.6);
        request.add(bytes);

        final response = await request.close();
        if (response.statusCode >= 200 && response.statusCode < 300) {
          if (onProgreso != null) onProgreso(1.0);
          return 'https://zyasdqiavlhairxcfcbo.supabase.co/storage/v1/object/public/videos/$fileName';
        } else {
          final errorBody = await response.transform(utf8.decoder).join();
          throw Exception('Error al almacenar video (${response.statusCode}): $errorBody');
        }
      } finally {
        client.close();
      }
    }
  }

  String _obtenerMimeType(String extension, bool esVideo) {
    if (esVideo) {
      switch (extension) {
        case 'mp4':
          return 'video/mp4';
        case 'mov':
          return 'video/quicktime';
        default:
          return 'video/mp4';
      }
    } else {
      switch (extension) {
        case 'png':
          return 'image/png';
        case 'webp':
          return 'image/webp';
        case 'gif':
          return 'image/gif';
        case 'jpg':
        case 'jpeg':
        default:
          return 'image/jpeg';
      }
    }
  }
}
