import 'model_helpers.dart';

class CommunityPost {
  const CommunityPost({
    required this.type,
    required this.content,
    required this.author,
    required this.isAnonymous,
    required this.prayers,
    required this.comments,
    required this.reviewed,
  });

  final String type;
  final String content;
  final String author;
  final bool isAnonymous;
  final int prayers;
  final int comments;
  final bool reviewed;

  factory CommunityPost.fromMap(JsonMap map) {
    return CommunityPost(
      type: readString(map, 'post_type', fallback: readString(map, 'category')),
      content: readString(map, 'content'),
      author: readString(
        map,
        'visible_author_name',
        fallback: readBool(map, 'is_anonymous')
            ? 'Anonymous member'
            : readString(map, 'author', fallback: 'FreedomCircle member'),
      ),
      isAnonymous: readBool(map, 'is_anonymous', fallback: true),
      prayers: readInt(map, 'reaction_count'),
      comments: readInt(
        map,
        'comment_count',
        fallback: readInt(map, 'comments'),
      ),
      reviewed: readString(map, 'status', fallback: 'active') == 'active',
    );
  }
}
