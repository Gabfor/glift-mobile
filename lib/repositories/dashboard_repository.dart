import 'package:supabase/supabase.dart';
import '../models/program.dart';
import '../models/training_row.dart';

class DashboardRepository {
  final SupabaseClient _supabase;

  DashboardRepository(this._supabase);

  Future<List<Program>> getDashboardPrograms(String userId) async {
    try {
      final response = await _supabase
          .from('programs')
          .select('id, name, position, dashboard, app, trainings(id)')
          .eq('user_id', userId)
          .or('dashboard.eq.true,dashboard.is.null')
          .order('position', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) {
        // Filter out programs explicitly hidden from dashboard
        if (json['dashboard'] == false) return null;
        
        // Check if program has trainings
        final trainings = (json['trainings'] as List?) ?? [];
        if (trainings.isEmpty) return null;

        return Program(
          id: json['id'],
          name: json['name'],
          trainings: [], // We don't need full trainings here, just the program info
          position: json['position'],
          dashboard: json['dashboard'] ?? true,
          app: json['app'] ?? true,
        );
      }).whereType<Program>().toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des programmes: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getDashboardTrainings(String programId) async {
    try {
      final response = await _supabase
          .from('trainings')
          .select('id, name, dashboard, position, program_id')
          .eq('program_id', programId)
          .or('dashboard.eq.true,dashboard.is.null')
          .order('position', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      return data.where((t) => t['dashboard'] != false).map((json) => {
        'id': json['id'],
        'name': json['name'],
        'position': json['position'],
        'program_id': json['program_id'],
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des entraînements: $e');
    }
  }

  Future<List<TrainingRow>> getDashboardExercises(String trainingId) async {
    try {
      final response = await _supabase
          .from('training_rows')
          .select()
          .eq('training_id', trainingId)
          .order('order', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => TrainingRow.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des exercices: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getExerciseHistory(String trainingRowId, String userId, {int limit = 10}) async {
    try {
      final response = await _supabase
          .from('training_session_exercises')
          .select('''
            id,
            training_row_id,
            session:training_sessions!inner (
              performed_at,
              user_id
            ),
            sets:training_session_sets (
              repetitions,
              weights
            )
          ''')
          .eq('training_row_id', trainingRowId)
          .eq('training_sessions.user_id', userId)
          .order('performed_at', referencedTable: 'training_sessions', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Erreur lors du chargement de l\'historique: $e');
    }
  }
}
