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

      final response = await _supabase
          .from('programs')
          .select('id, name, position, trainings(id, name, position, app, dashboard)')
          .eq('user_id', userId)
          .order('position', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      
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
        );
      }).where((p) => p.trainings.isNotEmpty).toList();
      
    } catch (e) {
      throw Exception('Erreur lors du chargement des programmes: $e');
    }
  }

  Future<List<TrainingRow>> getTrainingDetails(String trainingId) async {
    try {
      final response = await _supabase
          .from('training_rows_admin') 
          .select()
          .eq('training_id', trainingId)
          .order('order', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => TrainingRow.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement du détail de l\'entraînement: $e');
    }
  }
}
