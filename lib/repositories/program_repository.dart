import 'package:supabase/supabase.dart';
import '../models/program.dart';
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
            .select(
              'id, name, position, dashboard, trainings(id, name, position, app, dashboard, program_id)',
            )
            .eq('user_id', userId)
            .order('position', ascending: true);

        return _processProgramsResponse(response, userId);
      } catch (_) {
        // Fallback: fetch without dashboard column on trainings
        final response = await _supabase
            .from('programs')
            .select(
              'id, name, position, dashboard, trainings(id, name, position, app, program_id)',
            )
            .eq('user_id', userId)
            .order('position', ascending: true);

        return _processProgramsResponse(response, userId);
      }
    } catch (e) {
      throw Exception('Erreur lors du chargement des programmes: $e');
    }
  }

  Future<List<Program>> _processProgramsResponse(
    List<dynamic> data,
    String userId,
  ) async {
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
        ),
      ];
    }

    return data
        .map((json) {
          final program = Program.fromJson(json as Map<String, dynamic>);

          // Filter trainings to only show those visible in app
          final visibleTrainings = program.trainings
              .where((t) => t.app)
              .toList();

          // Sort trainings by position
          visibleTrainings.sort(
            (a, b) => (a.position ?? 0).compareTo(b.position ?? 0),
          );

          return Program(
            id: program.id,
            name: program.name,
            trainings: visibleTrainings,
            position: program.position,
            dashboard: program.dashboard,
          );
        })
        .where((p) => p.trainings.isNotEmpty)
        .toList();
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
      throw Exception(
        'Erreur lors du chargement du détail de l\'entraînement: $e',
      );
    }
  }

  Future<void> updateTrainingRow(
    String rowId, {
    List<String>? repetitions,
    List<String>? weights,
    List<String>? efforts,
    String? rest,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (repetitions != null) updates['repetitions'] = repetitions;
      if (weights != null) updates['poids'] = weights;
      if (efforts != null) updates['effort'] = efforts;
      if (rest != null) updates['repos'] = rest;

      if (updates.isEmpty) return;

      await _supabase.from('training_rows').update(updates).eq('id', rowId);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'exercice: $e');
    }
  }

  Future<void> updateRestDuration(String rowId, int restInSeconds) async {
    await updateTrainingRow(rowId, rest: restInSeconds.toString());
  }

  Future<void> saveTrainingSession({
    required String userId,
    required String trainingId,
    required List<TrainingRow> completedRows,
  }) async {
    try {
      // 1. Create session
      final sessionResponse = await _supabase
          .from('training_sessions')
          .insert({
            'user_id': userId,
            'training_id': trainingId,
            'performed_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select()
          .single();

      final sessionId = sessionResponse['id'];

      // 2. Create exercises and sets
      for (final row in completedRows) {
        final exerciseResponse = await _supabase
            .from('training_session_exercises')
            .insert({
              'session_id': sessionId,
              'training_row_id': row.id,
              'exercise_name': row.exercise,
            })
            .select()
            .single();

        final exerciseId = exerciseResponse['id'];

        // 3. Create sets
        final setsData = <Map<String, dynamic>>[];
        for (int i = 0; i < row.series; i++) {
          final repsStr = i < row.repetitions.length ? row.repetitions[i] : '0';
          final weight = i < row.weights.length ? row.weights[i] : '';

          // Parse repetitions safely (handle decimals like "10.0" by rounding)
          final repsDouble =
              double.tryParse(repsStr.replaceAll(',', '.')) ?? 0.0;
          final reps = repsDouble.round();

          // Only insert sets with valid repetitions (assuming check constraint requires > 0)
          if (reps > 0) {
            // Ensure weights array length matches repetitions (check constraint: cardinality(weights) == repetitions)
            final weightToUse = weight.trim().isEmpty ? '0' : weight;
            final weightsList = List<String>.filled(reps, weightToUse);

            setsData.add({
              'session_exercise_id': exerciseId, // Fixed column name
              'set_number': i + 1,
              'repetitions': reps, // Fixed type: int instead of List<String>
              'weights': weightsList, // Match length with repetitions
            });
          }
        }

        if (setsData.isNotEmpty) {
          await _supabase.from('training_session_sets').insert(setsData);
        }
      }
    } on PostgrestException catch (e) {
      final errorDetails = StringBuffer(
        'Erreur lors de la sauvegarde de la séance: ${e.message}',
      );

      if (e.details is String && (e.details as String).isNotEmpty) {
        errorDetails.write(' | Détails: ${e.details}');
      }

      if (e.hint is String && (e.hint as String).isNotEmpty) {
        errorDetails.write(' | Suggestion: ${e.hint}');
      }

      if (e.code != null && e.code!.isNotEmpty) {
        errorDetails.write(' | Code: ${e.code}');
      }

      throw Exception(errorDetails.toString());
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde de la séance: $e');
    }
  }
}
