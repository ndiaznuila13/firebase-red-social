import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/video_post.dart';

class VideoRepository {
  final FirebaseFirestore _firestore;

  VideoRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

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
    required String videoUrl,
    required String caption,
    required User usuario,
  }) async {
    await _videosRef.add({
      'videoUrl': videoUrl.trim(),
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

  Future<void> eliminarVideo({required String videoId}) async {
    await _videosRef.doc(videoId).delete();
  }
}
