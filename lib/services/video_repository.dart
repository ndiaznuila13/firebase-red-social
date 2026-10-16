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

  Future<void> publicarPost({
    required String mediaUrl,
    required String mediaType,
    required String caption,
    required User usuario,
    String? filter,
    double? filterX,
    double? filterY,
    double? filterScale,
  }) async {
    await _videosRef.add({
      'videoUrl': mediaUrl.trim(),
      'mediaUrl': mediaUrl.trim(),
      'mediaType': mediaType,
      'caption': caption.trim(),
      'authorUid': usuario.uid,
      'authorEmail': usuario.email ?? 'usuario',
      'likes': <String>[],
      'filter': filter,
      'filterX': filterX,
      'filterY': filterY,
      'filterScale': filterScale,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> publicarVideo({
    required String videoUrl,
    required String caption,
    required User usuario,
    String? filter,
    double? filterX,
    double? filterY,
    double? filterScale,
  }) async {
    await publicarPost(
      mediaUrl: videoUrl,
      mediaType: 'video',
      caption: caption,
      usuario: usuario,
      filter: filter,
      filterX: filterX,
      filterY: filterY,
      filterScale: filterScale,
    );
  }

  Future<void> actualizarFiltro({
    required String videoId,
    required String? filter,
    double? filterX,
    double? filterY,
    double? filterScale,
  }) async {
    final updateData = <String, dynamic>{
      'filter': filter,
    };
    if (filterX != null) updateData['filterX'] = filterX;
    if (filterY != null) updateData['filterY'] = filterY;
    if (filterScale != null) updateData['filterScale'] = filterScale;

    await _videosRef.doc(videoId).update(updateData);
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
