# TikTok App · Firebase (Auth, Firestore y Storage)

Aplicación móvil tipo TikTok desarrollada en Flutter y conectada a los servicios de Firebase:
- **Firebase Authentication**: Registro e inicio de sesión seguro con correo y contraseña.
- **Firebase Storage**: Almacenamiento y subida en la nube de archivos de video (MP4) con seguimiento de progreso en tiempo real.
- **Cloud Firestore**: Base de datos NoSQL para metadatos de videos, feed cronológico y sistema atómico de "me gusta".
- **Video Player**: Reproducción vertical estilo TikTok con auto-play en scroll, pausa al tocar y gestos de doble tap para dar like.

---

## Estructura del Proyecto

```text
lib/
├── firebase_options.dart         # Credenciales de conexión generadas con FlutterFire
├── main.dart                     # Inicialización de Firebase, tema oscuro y AuthGate
├── models/
│   └── video_post.dart           # Modelo de datos de cada video publicado
├── screens/
│   ├── feed_screen.dart          # Feed vertical con PageView y autoplay
│   ├── home_screen.dart          # Shell principal con barra de navegación estilo TikTok
│   ├── login_screen.dart         # Pantalla de autenticación y validación
│   ├── profile_screen.dart       # Perfil de usuario con métricas y videos propios
│   └── upload_screen.dart        # Selección (cámara/galería), preview y subida
├── services/
│   ├── auth_service.dart         # Wrapper de FirebaseAuth con manejo de errores
│   └── video_repository.dart     # Gestión de Cloud Firestore y Firebase Storage
└── widgets/
    └── video_player_item.dart    # Controlador de video, overlays y acciones laterales
```

---

## Configuración con tu proyecto de Firebase

Para vincular esta app con tu propio proyecto de Firebase en la consola ([console.firebase.google.com](https://console.firebase.google.com)):

### 1. Servicios a habilitar en Firebase Console
1. **Authentication**: En *Build → Authentication → Sign-in method*, habilita **Correo electrónico/Contraseña**.
2. **Cloud Firestore**: En *Build → Firestore Database*, crea la base de datos y copia las reglas de [firestore.rules](file:///firestore.rules).
3. **Firebase Storage**: En *Build → Storage*, activa el bucket de almacenamiento y copia las reglas de [storage.rules](file:///storage.rules).

### 2. Generar o actualizar `lib/firebase_options.dart`
Puedes configurar la app automáticamente ejecutando desde la terminal:

```bash
# 1. Iniciar sesión en Firebase (si no lo has hecho)
npx firebase login

# 2. Configurar FlutterFire para tu proyecto
dart pub global run flutterfire_cli:flutterfire configure
```

Selecciona tu proyecto en la lista interactiva y las plataformas deseadas (`android`, `ios`, `web`). Esto generará automáticamente las claves reales en [lib/firebase_options.dart](file:///lib/firebase_options.dart).

*(Alternativamente, puedes pegar directamente los valores de tu consola en [lib/firebase_options.dart](file:///lib/firebase_options.dart)).*

---

## Ejecución

```bash
# Descargar dependencias
flutter pub get

# Ejecutar en tu dispositivo o emulador
flutter run
```
