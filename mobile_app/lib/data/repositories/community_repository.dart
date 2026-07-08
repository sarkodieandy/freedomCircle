import '../models/community_post.dart';
import '../models/post_comment.dart';
import 'supabase_repository.dart';

class CommunityRepository extends SupabaseRepository {
  const CommunityRepository({super.supabaseClient});

  Future<List<CommunityPost>> posts() {
    return guard(() async {
      final rows = await client
          .from('community_feed_posts')
          .select()
          .order('created_at', ascending: false);
      return mapRows(rows, CommunityPost.fromMap);
    });
  }

  Future<CommunityPost> createPost(Map<String, dynamic> values) {
    return guard(() async {
      final row = await client
          .from('community_posts')
          .insert(values)
          .select()
          .single();
      return CommunityPost.fromMap(mapRow(row));
    });
  }

  Future<List<PostComment>> comments(String postId) {
    return guard(() async {
      final rows = await client
          .from('post_comments')
          .select()
          .eq('post_id', postId)
          .order('created_at');
      return mapRows(rows, PostComment.fromMap);
    });
  }

  Future<PostComment> addComment(Map<String, dynamic> values) {
    return guard(() async {
      final row = await client
          .from('post_comments')
          .insert(values)
          .select()
          .single();
      return PostComment.fromMap(mapRow(row));
    });
  }

  Future<void> react({
    required String postId,
    required String userId,
    required String reaction,
  }) {
    return guard(
      () => client.from('post_reactions').upsert({
        'post_id': postId,
        'user_id': userId,
        'reaction': reaction,
      }),
    );
  }
}
