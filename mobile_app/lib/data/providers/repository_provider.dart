import '../repositories/freedom_repository.dart';
import '../supabase/supabase_service.dart';

class RepositoryProvider {
  const RepositoryProvider._();

  static FreedomRepository freedomRepository({bool? useMock}) {
    final shouldUseMock = useMock ?? !SupabaseService.isInitialized;
    return shouldUseMock
        ? const MockFreedomRepository()
        : const SupabaseFreedomRepository();
  }
}
