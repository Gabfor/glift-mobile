import 'package:supabase/supabase.dart';
import '../models/store_program.dart';

class StoreRepository {
  final SupabaseClient _supabase;

  StoreRepository(this._supabase);

  Future<List<StoreProgram>> getStorePrograms({
    String sortBy = 'popularity',
    List<String>? filters,
  }) async {
    try {
      dynamic query = _supabase
          .from('program_store')
          .select()
          .eq('status', 'ON');

      // Sorting
      if (sortBy == 'popularity') {
        query = query.order('downloads', ascending: false);
      } else if (sortBy == 'oldest') {
        query = query.order('created_at', ascending: true);
      } else {
        // newest
        query = query.order('created_at', ascending: false);
      }

      // TODO: Implement filters if needed (gender, goal, level, etc.)
      // For now we fetch all active programs

      final response = await query;
      final List<dynamic> data = response as List<dynamic>;
      
      return data.map((json) => StoreProgram.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement du store: $e');
    }
  }
}
