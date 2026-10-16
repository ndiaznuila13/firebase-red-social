import 'package:cloud_firestore/cloud_firestore.dart';

class VideoPost {
  final String id;
  final String videoUrl;
  final String caption;
  final String authorUid;
  final String authorEmail;
  final List<String> likes;
  final DateTime? createdAt;
  final String mediaType;
  final String? filter;
  final double? filterX;
  final double? filterY;
  final double? filterScale;

  VideoPost({
    required this.id,
    required this.videoUrl,
    required this.caption,
    required this.authorUid,
    required this.authorEmail,
    required this.likes,
    this.createdAt,
    this.mediaType = 'video',
    this.filter,
    this.filterX,
    this.filterY,
    this.filterScale,
  });

  bool isLikedBy(String uid) => likes.contains(uid);

  int get likesCount => likes.length;

  bool get isImage =>
      mediaType == 'image' ||
      videoUrl.toLowerCase().contains('.jpg') ||
      videoUrl.toLowerCase().contains('.jpeg') ||
      videoUrl.toLowerCase().contains('.png') ||
      videoUrl.toLowerCase().contains('.webp');

  bool get isVideo => !isImage;

  factory VideoPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final url = (data['mediaUrl'] ?? data['videoUrl']) as String? ?? '';
    final type = data['mediaType'] as String? ??
        (url.contains('.jpg') || url.contains('.png') || url.contains('.jpeg')
            ? 'image'
            : 'video');

    return VideoPost(
      id: doc.id,
      videoUrl: url,
      caption: data['caption'] as String? ?? '',
      authorUid: data['authorUid'] as String? ?? '',
      authorEmail: data['authorEmail'] as String? ?? 'Anónimo',
      likes: List<String>.from(data['likes'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      mediaType: type,
      filter: data['filter'] as String?,
      filterX: (data['filterX'] as num?)?.toDouble(),
      filterY: (data['filterY'] as num?)?.toDouble(),
      filterScale: (data['filterScale'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'videoUrl': videoUrl,
      'mediaUrl': videoUrl,
      'mediaType': mediaType,
      'caption': caption,
      'authorUid': authorUid,
      'authorEmail': authorEmail,
      'likes': likes,
      'filter': filter,
      'filterX': filterX,
      'filterY': filterY,
      'filterScale': filterScale,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
