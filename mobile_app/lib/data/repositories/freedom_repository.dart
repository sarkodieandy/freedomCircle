import '../mock/mock_data.dart';
import '../models/accountability_group.dart';
import '../models/community_post.dart';
import '../models/helper_profile.dart';
import 'community_repository.dart';
import 'group_repository.dart';
import 'helper_repository.dart';

abstract class FreedomRepository {
  Future<List<AccountabilityGroup>> groups();
  Future<List<CommunityPost>> communityPosts();
  Future<List<HelperProfile>> helpers();
}

class MockFreedomRepository implements FreedomRepository {
  const MockFreedomRepository();

  @override
  Future<List<AccountabilityGroup>> groups() async => MockDataService.groups;

  @override
  Future<List<CommunityPost>> communityPosts() async => MockDataService.posts;

  @override
  Future<List<HelperProfile>> helpers() async => MockDataService.helpers;
}

class SupabaseFreedomRepository implements FreedomRepository {
  const SupabaseFreedomRepository({
    this.groupRepository = const GroupRepository(),
    this.communityRepository = const CommunityRepository(),
    this.helperRepository = const HelperRepository(),
  });

  final GroupRepository groupRepository;
  final CommunityRepository communityRepository;
  final HelperRepository helperRepository;

  @override
  Future<List<AccountabilityGroup>> groups() => groupRepository.groups();

  @override
  Future<List<CommunityPost>> communityPosts() => communityRepository.posts();

  @override
  Future<List<HelperProfile>> helpers() => helperRepository.helpers();
}
