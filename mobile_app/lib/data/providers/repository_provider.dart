import '../../core/config/app_env.dart';
import '../repositories/freedom_repository.dart';
import '../supabase/supabase_service.dart';

class RepositoryProvider {
  const RepositoryProvider._();

  static FreedomRepository freedomRepository({bool? useMock}) {
    final shouldUseMock =
        useMock ?? AppEnv.useMockData || !SupabaseService.isInitialized;
    return shouldUseMock
        ? const MockFreedomRepository()
        : const SupabaseFreedomRepository();
  }
}
