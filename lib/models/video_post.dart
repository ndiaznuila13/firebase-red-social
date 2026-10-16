import 'package:cloud_firestore/cloud_firestore.dart';

class VideoPost {
  final String id;
  final String videoUrl;
  final String caption;
  final String authorUid;
  final String authorEmail;
  final List<String> likes;
  final DateTime? createdAt;

  VideoPost({
    required this.id,
    required this.videoUrl,
    required this.caption,
    required this.authorUid,
    required this.authorEmail,
    required this.likes,
    this.createdAt,
  });

  bool isLikedBy(String uid) => likes.contains(uid);

  int get likesCount => likes.length;

  factory VideoPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return VideoPost(
      id: doc.id,
      videoUrl: data['videoUrl'] as String? ?? '',
      caption: data['caption'] as String? ?? '',
      authorUid: data['authorUid'] as String? ?? '',
      authorEmail: data['authorEmail'] as String? ?? 'Anónimo',
      likes: List<String>.from(data['likes'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'videoUrl': videoUrl,
      'caption': caption,
      'authorUid': authorUid,
      'authorEmail': authorEmail,
      'likes': likes,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
