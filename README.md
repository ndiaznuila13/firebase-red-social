# TokTik · Red Social en Flutter con Firebase & Filtros

Aplicación móvil tipo red social (estilo TikTok) desarrollada en Flutter, completamente integrada con Firebase y almacenamiento en la nube:

- **Autenticación en tiempo real**: Registro e inicio de sesión seguro con correo y contraseña mediante Firebase Auth.
- **Feed centralizado en la nube**: Sincronización instantánea de publicaciones con Cloud Firestore (`snapshots()`).
- **Subida de Fotos y Videos**: 
  - Captura desde cámara o selección desde galería.
  - Compresión y renderizado optimizado de imágenes.
  - Almacenamiento y streaming de video.
- **Filtros Faciales e Interactivos**:
  - Detección automática de rostros con Google ML Kit Face Detection.
  - Filtros temáticos: Lentes de sol, bigote vintage, cono de cumpleaños, lentes de fiesta, sombrero cómico, corona real y orejas de gato.
  - Posicionamiento manual táctil arrastrando con un dedo y control de escala interactivo.
  - Edición de filtros en publicaciones existentes en el feed.
- **Interacciones sociales**: Sistema de "Me gusta" con contador en tiempo real y animación de corazón con doble tap.

---

## Estructura del Proyecto

```text
lib/
├── firebase_options.dart         # Credenciales de conexión a Firebase (listas para usar)
├── main.dart                     # Inicialización de Firebase y AuthGate
├── models/
│   ├── post_filter.dart          # Definición y opciones de filtros interactivos
│   └── video_post.dart           # Modelo de datos de publicaciones (fotos/videos)
├── screens/
│   ├── feed_screen.dart          # Feed vertical con PageView y tiempo real
│   ├── home_screen.dart          # Navegación principal
│   ├── login_screen.dart         # Login y registro de usuarios
│   ├── profile_screen.dart       # Perfil con métricas y publicaciones propias
│   └── upload_screen.dart        # Selección de medios, cámara, filtros y publicación
├── services/
│   ├── auth_service.dart         # Autenticación con FirebaseAuth
│   ├── face_detector_service.dart# Detección facial con ML Kit
│   ├── storage_service.dart      # Servicio de almacenamiento de fotos y videos
│   └── video_repository.dart     # Consultas y mutaciones en Cloud Firestore
└── widgets/
    ├── media_filter_overlay.dart # Renderizado interactivo de filtros y gestos
    └── video_player_item.dart    # Tarjeta de video/foto, controles y likes
```

---

## Conexión y Configuración

El proyecto ya incluye la configuración de backend lista en `lib/firebase_options.dart` y `lib/services/storage_service.dart`. **No se requiere crear proyectos nuevos de Firebase ni configurar API keys adicionales.** Todos los miembros del equipo que ejecuten la app compartirán el mismo feed y la misma base de datos automáticamente.

---

## Pasos para Ejecutar la App

### 1. Requisitos
- Flutter SDK instalado y configurado en el PATH (`flutter doctor`).
- Un teléfono Android físico conectado por USB con la **Depuración por USB activada** (o un emulador Android abierto en Android Studio).

### 2. Comandos en Terminal

```bash
# 1. Obtener dependencias
flutter pub get

# 2. Verificar que el dispositivo esté detectado
flutter devices

# 3. Compilar y correr en el dispositivo
flutter run
```

*(Si tienes más de un dispositivo conectado, especifica el ID: `flutter run -d <DEVICE_ID>`)*.

### 3. Primer uso
1. En la pantalla inicial, pulsa en **"¿No tienes cuenta? Regístrate"**.
2. Ingresa cualquier correo y contraseña deseada para crear tu usuario.
3. Al entrar al feed verás las publicaciones compartidas del equipo y podrás subir fotos o videos desde el botón central `+`.
