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

  Future<String?> downloadProgram(String storeProgramId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      // 1. Get linked_program_id and short name
      final storeData = await _supabase
          .from('program_store')
          .select('linked_program_id, name_short')
          .eq('id', storeProgramId)
          .single();

      final String? linkedProgramId = storeData['linked_program_id'];
      final String? shortName = storeData['name_short'];

      if (linkedProgramId == null) {
        throw Exception('Impossible de retrouver le programme source.');
      }

      // 2. Get source program from programs_admin
      final programToCopy = await _supabase
          .from('programs_admin')
          .select('*')
          .eq('id', linkedProgramId)
          .single();

      // 3. Get max position for user programs
      final userPrograms = await _supabase
          .from('programs')
          .select('position')
          .eq('user_id', user.id);

      int nextPosition = 0;
      if (userPrograms != null && (userPrograms as List).isNotEmpty) {
        final positions = (userPrograms as List)
            .map((p) => (p['position'] as int? ?? 0))
            .toList();
        nextPosition = positions.reduce((a, b) => a > b ? a : b) + 1;
      }

      // 4. Create user program
      final insertedProgram = await _supabase.from('programs').insert({
        'name': shortName ?? programToCopy['name'] ?? 'Programme copié',
        'name_short': shortName ?? programToCopy['name'] ?? 'Programme copié',
        'user_id': user.id,
        'created_at': DateTime.now().toIso8601String(),
        'position': nextPosition,
        'is_new': true,
        'source_store_id': storeProgramId,
        'dashboard': true,
        'app': true,
      }).select('id').single();

      final String newProgramId = insertedProgram['id'];

      // 5. Get admin trainings
      final List<dynamic> adminTrainings = await _supabase
          .from('trainings_admin')
          .select('*')
          .eq('program_id', linkedProgramId);

      if (adminTrainings.isEmpty) return newProgramId;

      // 6. Copy trainings
      final Map<String, String> trainingMapping = {};
      for (final training in adminTrainings) {
        final insertedTraining = await _supabase.from('trainings').insert({
          'name': training['name'],
          'user_id': user.id,
          'program_id': newProgramId,
          'position': training['position'],
          'columns_settings': training['columns_settings'],
          'app': true,
          'dashboard': true,
        }).select('id').single();

        trainingMapping[training['id'].toString()] = insertedTraining['id'].toString();
      }

      // 7. Get admin rows
      final adminTrainingIds = trainingMapping.keys.toList();
      final List<dynamic> adminRows = await _supabase
          .from('training_rows_admin')
          .select('*')
          .filter('training_id', 'in', adminTrainingIds);

      // 8. Copy rows
      if (adminRows.isNotEmpty) {
        final rowsToInsert = adminRows.map((row) {
          return {
            'training_id': trainingMapping[row['training_id'].toString()],
            'user_id': user.id,
            'order': row['order'],
            'series': row['series'],
            'repetitions': row['repetitions'],
            'poids': row['poids'],
            'repos': row['repos'],
            'effort': row['effort'],
            'checked': row['checked'] ?? false,
            'created_at': row['created_at'] ?? DateTime.now().toIso8601String(),
            'updated_at': row['updated_at'] ?? DateTime.now().toIso8601String(),
            'exercice': row['exercice'] ?? '',
            'materiel': row['materiel'] ?? '',
            'superset_id': row['superset_id'],
            'link': row['link'],
            'note': row['note'],
            'position': row['position'],
          };
        }).toList();

        await _supabase.from('training_rows').insert(rowsToInsert);
      }

      // 9. Increment downloads
      try {
        await _supabase.rpc('increment_downloads', params: {
          'store_program_id': storeProgramId,
        });
      } catch (e) {
        print('Erreur incrémentation downloads: $e');
      }

      return newProgramId;
    } catch (e) {
      print('Erreur downloadProgram: $e');
      rethrow;
    }
  }

  Future<int> getProgramExerciseCount(String storeProgramId) async {
    try {
      // 1. Get linked_program_id
      final storeData = await _supabase
          .from('program_store')
          .select('linked_program_id')
          .eq('id', storeProgramId)
          .single();

      final String? linkedProgramId = storeData['linked_program_id'];
      if (linkedProgramId == null) return 0;

      // 2. Get training IDs
      final List<dynamic> adminTrainings = await _supabase
          .from('trainings_admin')
          .select('id')
          .eq('program_id', linkedProgramId);

      if (adminTrainings.isEmpty) return 0;

      final trainingIds = adminTrainings.map((t) => t['id'].toString()).toList();

      // 3. Get count of rows
      final count = await _supabase
          .from('training_rows_admin')
          .count(CountOption.exact)
          .filter('training_id', 'in', trainingIds);
      
      return count;
    } catch (e) {
      print('Error getting exercise count: $e');
      return 0;
    }
  }
}
