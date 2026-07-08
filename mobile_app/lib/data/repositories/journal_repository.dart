import '../models/journal_entry.dart';
import 'supabase_repository.dart';

class JournalRepository extends SupabaseRepository {
  const JournalRepository({super.supabaseClient});

  Future<List<JournalEntry>> getJournalEntries(String userId) =>
      entries(userId);

  Future<JournalEntry> createJournalEntry(Map<String, dynamic> values) =>
      createEntry(values);

  Future<JournalEntry> updateJournalEntry(
    String entryId,
    Map<String, dynamic> values,
  ) => updateEntry(entryId, values);

  Future<void> deleteJournalEntry(String entryId) => deleteEntry(entryId);

  Future<List<JournalEntry>> entries(String userId) {
    return guard(() async {
      final rows = await client
          .from('journal_entries')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return mapRows(rows, JournalEntry.fromMap);
    });
  }

  Future<JournalEntry> createEntry(Map<String, dynamic> values) {
    return guard(() async {
      final row = await client
          .from('journal_entries')
          .insert(values)
          .select()
          .single();
      return JournalEntry.fromMap(mapRow(row));
    });
  }

  Future<JournalEntry> updateEntry(
    String entryId,
    Map<String, dynamic> values,
  ) {
    return guard(() async {
      final row = await client
          .from('journal_entries')
          .update(values)
          .eq('id', entryId)
          .select()
          .single();
      return JournalEntry.fromMap(mapRow(row));
    });
  }

  Future<void> deleteEntry(String entryId) {
    return guard(() async {
      await client.from('journal_entries').delete().eq('id', entryId);
    });
  }

  Future<List<JournalEntry>> searchJournalEntries({
    required String userId,
    required String query,
  }) {
    return guard(() async {
      final q = query.trim();
      if (q.isEmpty) return entries(userId);
      final rows = await client
          .from('journal_entries')
          .select()
          .eq('user_id', userId)
          .or('title.ilike.%$q%,content.ilike.%$q%')
          .order('created_at', ascending: false);
      return mapRows(rows, JournalEntry.fromMap);
    });
  }
}
