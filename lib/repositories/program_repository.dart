import 'package:supabase/supabase.dart';
import '../models/program.dart';
import '../models/training.dart';
import '../models/training_row.dart';

class ProgramRepository {
  final SupabaseClient _supabase;

  ProgramRepository(this._supabase);

  Future<List<Program>> getPrograms() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Try fetching with dashboard column
      try {
        final response = await _supabase
            .from('programs')
            .select('id, name, position, dashboard, trainings(id, name, position, app, dashboard, program_id)')
            .eq('user_id', userId)
            .order('position', ascending: true);
        
        return _processProgramsResponse(response, userId);
      } catch (_) {
        // Fallback: fetch without dashboard column on trainings
        final response = await _supabase
            .from('programs')
            .select('id, name, position, dashboard, trainings(id, name, position, app, program_id)')
            .eq('user_id', userId)
            .order('position', ascending: true);
            
        return _processProgramsResponse(response, userId);
      }
    } catch (e) {
      throw Exception('Erreur lors du chargement des programmes: $e');
    }
  }

  Future<List<Program>> _processProgramsResponse(List<dynamic> data, String userId) async {
    if (data.isEmpty) {
      // Create default program if none exists
      final newProgram = await _supabase
          .from('programs')
          .insert({'name': 'Nom du programme', 'user_id': userId})
          .select()
          .single();
          
      return [
        Program(
          id: newProgram['id'],
          name: newProgram['name'],
          trainings: [],
          position: newProgram['position'],
          dashboard: newProgram['dashboard'] ?? true,
        )
      ];
    }

    return data.map((json) {
      final program = Program.fromJson(json as Map<String, dynamic>);
      
      // Filter trainings to only show those visible in app
      final visibleTrainings = program.trainings.where((t) => t.app).toList();
      
      // Sort trainings by position
      visibleTrainings.sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));

      return Program(
        id: program.id,
        name: program.name,
        trainings: visibleTrainings,
        position: program.position,
        dashboard: program.dashboard,
      );
    }).where((p) => p.trainings.isNotEmpty).toList();
  }

  Future<List<TrainingRow>> getTrainingDetails(String trainingId) async {
    try {
      final response = await _supabase
          .from('training_rows') 
          .select()
          .eq('training_id', trainingId)
          .order('order', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => TrainingRow.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement du détail de l\'entraînement: $e');
    }
  }
  Future<void> updateTrainingRow(String rowId, {List<String>? repetitions, List<String>? weights}) async {
    try {
      final updates = <String, dynamic>{};
      if (repetitions != null) updates['repetitions'] = repetitions;
      if (weights != null) updates['poids'] = weights;

      if (updates.isEmpty) return;

      await _supabase
          .from('training_rows')
          .update(updates)
          .eq('id', rowId);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'exercice: $e');
    }
  }

  Future<void> saveTrainingSession({
    required String userId,
    required String trainingId,
    required List<TrainingRow> completedRows,
  }) async {
    try {
      // 1. Create session
      final sessionResponse = await _supabase.from('training_sessions').insert({
        'user_id': userId,
        'training_id': trainingId,
        'performed_at': DateTime.now().toIso8601String(),
      }).select().single();

      final sessionId = sessionResponse['id'];

      // 2. Create exercises and sets
      for (final row in completedRows) {
        final exerciseResponse = await _supabase.from('training_session_exercises').insert({
          'training_session_id': sessionId,
          'training_row_id': row.id,
        }).select().single();

        final exerciseId = exerciseResponse['id'];

        // 3. Create sets
        final setsData = <Map<String, dynamic>>[];
        for (int i = 0; i < row.series; i++) {
          final reps = i < row.repetitions.length ? row.repetitions[i] : '';
          final weight = i < row.weights.length ? row.weights[i] : '';

          setsData.add({
            'training_session_exercise_id': exerciseId,
            'set_number': i + 1,
            'repetitions': [reps],
            'weights': [weight],
          });
        }

        if (setsData.isNotEmpty) {
          await _supabase.from('training_session_sets').insert(setsData);
        }
      }
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde de la séance: $e');
    }
  }
}
