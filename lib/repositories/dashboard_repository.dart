import 'package:flutter/foundation.dart';
import 'package:supabase/supabase.dart';
import '../models/program.dart';
import '../models/training_row.dart';
import '../models/dashboard_preferences.dart';

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

  Future<List<Map<String, dynamic>>> getDashboardTrainings(String programId, [String? userId]) async {
    try {
      final response = await _supabase
          .from('trainings')
          .select('id, name, dashboard, position, program_id')
          .eq('program_id', programId)
          .or('dashboard.eq.true,dashboard.is.null')
          .order('position', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      final List<Map<String, dynamic>> trainings = data
          .where((t) => t['dashboard'] != false)
          .map((json) => {
                'id': json['id'],
                'name': json['name'],
                'position': json['position'],
                'program_id': json['program_id'],
              })
          .toList();

      final effectiveUserId = userId ?? _supabase.auth.currentUser?.id;
      if (effectiveUserId != null && trainings.isNotEmpty) {
        try {
          final trainingIds = trainings.map((t) => t['id'] as String).toList();
          final sessionsResponse = await _supabase
              .from('training_sessions')
              .select('training_id, performed_at')
              .eq('user_id', effectiveUserId)
              .inFilter('training_id', trainingIds)
              .order('performed_at', ascending: false);

          final sessionsList = sessionsResponse as List<dynamic>;
          final Map<String, DateTime> latestByTraining = {};
          for (final session in sessionsList) {
            final tId = session['training_id'] as String?;
            final perfAtStr = session['performed_at'] as String?;
            if (tId != null && perfAtStr != null && !latestByTraining.containsKey(tId)) {
              final parsed = DateTime.tryParse(perfAtStr);
              if (parsed != null) {
                latestByTraining[tId] = parsed;
              }
            }
          }

          for (final t in trainings) {
            t['last_performed_at'] = latestByTraining[t['id'] as String];
          }

          trainings.sort((a, b) {
            final DateTime? aDate = a['last_performed_at'] as DateTime?;
            final DateTime? bDate = b['last_performed_at'] as DateTime?;

            if (aDate != null && bDate != null) {
              final cmp = bDate.compareTo(aDate);
              if (cmp != 0) return cmp;
            } else if (aDate != null) {
              return -1; // a is more recent than null
            } else if (bDate != null) {
              return 1; // b is more recent than null
            }

            final int aPos = a['position'] as int? ?? 0;
            final int bPos = b['position'] as int? ?? 0;
            return aPos.compareTo(bPos);
          });
        } catch (sessionErr) {
          // If fetching session recency fails, preserve original order by position
          // so the dashboard remains functional.
        }
      }

      return trainings;
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

  Future<List<Map<String, dynamic>>> getExerciseHistory(String trainingRowId, String userId, {int? limit}) async {
    try {
      final effectiveLimit = limit ?? 7;
      final response = await _supabase
          .from('training_sessions')
          .select('''
            id,
            performed_at,
            user_id,
            exercises:training_session_exercises!inner (
              id,
              training_row_id,
              sets:training_session_sets (
                repetitions,
                weights
              )
            )
          ''')
          .eq('user_id', userId)
          .eq('exercises.training_row_id', trainingRowId)
          .order('performed_at', ascending: false)
          .limit(effectiveLimit);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((sessionJson) {
         final exercises = (sessionJson['exercises'] as List?) ?? [];
         if (exercises.isEmpty) return null;
         final exerciseJson = exercises.first;
         return {
            'id': exerciseJson['id'],
            'training_row_id': exerciseJson['training_row_id'],
            'session': {
               'performed_at': sessionJson['performed_at'],
               'user_id': sessionJson['user_id']
            },
            'sets': exerciseJson['sets']
         };
      }).where((e) => e != null).cast<Map<String, dynamic>>().toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement de l\'historique: $e');
    }
  }


  Future<DashboardPreferences> getDashboardPreferences(String userId) async {
    try {
      final response = await _supabase
          .from('dashboard_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return DashboardPreferences();
      }

      return DashboardPreferences.fromJson(response);
    } catch (e) {
      // Return defaults on error to not block the UI
      debugPrint('Error fetching preferences: $e');
      return DashboardPreferences();
    }
  }

  Future<void> updateDashboardPreferences(String userId, DashboardPreferences prefs) async {
    try {
      await _supabase
          .from('dashboard_preferences')
          .upsert({
            'user_id': userId,
            ...prefs.toJson(),
            'updated_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      debugPrint('Error updating preferences: $e');
      throw Exception('Erreur lors de la sauvegarde des préférences: $e');
    }
  }
}
