import '../models/community_post.dart';
import '../models/post_comment.dart';
import 'supabase_repository.dart';

class CommunityRepository extends SupabaseRepository {
  const CommunityRepository({super.supabaseClient});

  Future<List<CommunityPost>> getCommunityFeed() => posts();

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

  Future<CommunityPost> updatePost(String postId, Map<String, dynamic> values) {
    return guard(() async {
      final row = await client
          .from('community_posts')
          .update(values)
          .eq('id', postId)
          .select()
          .single();
      return CommunityPost.fromMap(mapRow(row));
    });
  }

  Future<void> deletePost(String postId) {
    return guard(() async {
      await client.from('community_posts').delete().eq('id', postId);
    });
  }

  Future<List<PostComment>> getPostComments(String postId) => comments(postId);

  Future<void> deleteComment(String commentId) {
    return guard(() async {
      await client.from('post_comments').delete().eq('id', commentId);
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

  Future<void> reactToPost({
    required String postId,
    required String userId,
    required String reaction,
  }) => react(postId: postId, userId: userId, reaction: reaction);

  Future<void> removeReaction({
    required String postId,
    required String userId,
  }) {
    return guard(() async {
      await client
          .from('post_reactions')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
    });
  }

  Future<void> reportPost(Map<String, dynamic> values) {
    return guard(() async {
      await client.from('reports').insert(values);
    });
  }

  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
    String reason = 'community_safety',
  }) {
    return guard(() async {
      await client.from('user_blocks').upsert({
        'blocker_id': blockerId,
        'blocked_id': blockedId,
        'reason': reason,
      }, onConflict: 'blocker_id,blocked_id');
    });
  }
}
