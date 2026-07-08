import 'model_helpers.dart';

class PostComment {
  const PostComment({
    required this.id,
    required this.postId,
    required this.comment,
    required this.createdAt,
    this.isAnonymous = false,
  });

  final String id;
  final String postId;
  final String comment;
  final DateTime createdAt;
  final bool isAnonymous;

  factory PostComment.fromMap(JsonMap map) {
    return PostComment(
      id: readString(map, 'id'),
      postId: readString(map, 'post_id'),
      comment: readString(map, 'comment'),
      createdAt: readDateTime(map, 'created_at', fallback: DateTime.now()),
      isAnonymous: readBool(map, 'is_anonymous'),
    );
  }
}
