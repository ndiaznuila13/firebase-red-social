import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/video_post.dart';

class VideoRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  VideoRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference get _videosRef => _firestore.collection('videos');

  Stream<List<VideoPost>> obtenerFeed() {
    return _videosRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => VideoPost.fromFirestore(doc)).toList();
    });
  }

  Stream<List<VideoPost>> obtenerVideosDeUsuario(String uid) {
    return _videosRef
        .where('authorUid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => VideoPost.fromFirestore(doc))
          .toList();
      list.sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));
      return list;
    });
  }

  Future<void> publicarVideo({
    required XFile videoFile,
    required String caption,
    required User usuario,
    void Function(double progreso)? onProgreso,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = 'videos/${usuario.uid}_$timestamp.mp4';
    final storageRef = _storage.ref().child(storagePath);

    final metadata = SettableMetadata(
      contentType: 'video/mp4',
      customMetadata: {'uploadedBy': usuario.uid},
    );

    UploadTask uploadTask;
    if (kIsWeb) {
      final bytes = await videoFile.readAsBytes();
      uploadTask = storageRef.putData(bytes, metadata);
    } else {
      uploadTask = storageRef.putFile(File(videoFile.path), metadata);
    }

    if (onProgreso != null) {
      uploadTask.snapshotEvents.listen((event) {
        if (event.totalBytes > 0) {
          final progreso = event.bytesTransferred / event.totalBytes;
          onProgreso(progreso);
        }
      });
    }

    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    await _videosRef.add({
      'videoUrl': downloadUrl,
      'storagePath': storagePath,
      'caption': caption.trim(),
      'authorUid': usuario.uid,
      'authorEmail': usuario.email ?? 'usuario',
      'likes': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> alternarLike({
    required String videoId,
    required String uid,
    required bool estaLikeado,
  }) async {
    final docRef = _videosRef.doc(videoId);
    if (estaLikeado) {
      await docRef.update({
        'likes': FieldValue.arrayRemove([uid]),
      });
    } else {
      await docRef.update({
        'likes': FieldValue.arrayUnion([uid]),
      });
    }
  }

  Future<void> eliminarVideo({
    required String videoId,
    String? storagePath,
  }) async {
    await _videosRef.doc(videoId).delete();
    if (storagePath != null && storagePath.isNotEmpty) {
      try {
        await _storage.ref().child(storagePath).delete();
      } catch (_) {}
    }
  }
}
