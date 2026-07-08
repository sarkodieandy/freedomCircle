import '../models/accountability_group.dart';
import '../models/community_post.dart';
import '../models/helper_profile.dart';
import '../models/prayer_request.dart';
import 'supabase_repository.dart';

class SearchRepository extends SupabaseRepository {
  const SearchRepository({super.supabaseClient});

  Future<List<AccountabilityGroup>> searchGroups(String query) {
    return guard(() async {
      final q = query.trim();
      if (q.isEmpty) return const <AccountabilityGroup>[];
      final rows = await client
          .from('public_group_cards')
          .select()
          .or('name.ilike.%$q%,description.ilike.%$q%')
          .limit(20);
      return mapRows(rows, AccountabilityGroup.fromMap);
    });
  }

  Future<List<CommunityPost>> searchPosts(String query) {
    return guard(() async {
      final q = query.trim();
      if (q.isEmpty) return const <CommunityPost>[];
      final rows = await client
          .from('community_feed_posts')
          .select()
          .ilike('content', '%$q%')
          .limit(20);
      return mapRows(rows, CommunityPost.fromMap);
    });
  }

  Future<List<HelperProfile>> searchHelpers(String query) {
    return guard(() async {
      final q = query.trim();
      if (q.isEmpty) return const <HelperProfile>[];
      final rows = await client
          .from('helper_public_profiles')
          .select()
          .or('name.ilike.%$q%,organization.ilike.%$q%')
          .limit(20);
      return mapRows(rows, HelperProfile.fromMap);
    });
  }

  Future<List<PrayerRequest>> searchPrayerRequests(String query) {
    return guard(() async {
      final q = query.trim();
      if (q.isEmpty) return const <PrayerRequest>[];
      final rows = await client
          .from('prayer_requests')
          .select()
          .or('title.ilike.%$q%,content.ilike.%$q%')
          .limit(20);
      return mapRows(rows, PrayerRequest.fromMap);
    });
  }

  Future<Map<String, dynamic>> globalSearch(String query) async {
    final groups = await searchGroups(query);
    final posts = await searchPosts(query);
    final helpers = await searchHelpers(query);
    final prayers = await searchPrayerRequests(query);
    return {
      'groups': groups,
      'posts': posts,
      'helpers': helpers,
      'prayers': prayers,
    };
  }
}
