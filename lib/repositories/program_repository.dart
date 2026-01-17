import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase/supabase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/program.dart';
import '../models/training.dart';
import '../models/training_row.dart';
import '../services/settings_service.dart';

class ProgramRepository {
  final SupabaseClient _supabase;

  ProgramRepository(this._supabase);

  static const String _programsCacheKey = 'cached_programs';

  /// Ensures that all trainings have the correct 'locked' status based on the user's subscription plan.
  /// If inconsistencies are found, it updates the database and the returned objects.
  Future<List<Program>> _ensureLockedConsistency(List<Program> programs) async {
    final userPlan = SettingsService.instance.getSubscriptionPlan(); // 'basic' or 'premium'
    // debugPrint('Enforcing locked consistency for plan: $userPlan');

    final bool isPremium = userPlan == 'premium';
    
    // Find the global first training (First program by position -> First training by position)
    // Programs are already sorted by position in getPrograms
    // Trainings inside programs need to be sorted by position to be sure
    
    String? firstTrainingId;
    
    // Locate the very first training available in the list
    for (final program in programs) {
        // We assume program.trainings are sorted by position locally or we sort them here temporarily to check
        // but `_processProgramsResponse` does not sort them by position explicitly? 
        // usage in `visibleTrainingsWithStats.sort` sorts by DATE. 
        // We need 'position' to determine which is the "first" intended training.
        // Wait, `visibleTrainingsWithStats.sort` sorts by `lastSessionDate`!
        // This messes up the "first training" logic if it relies on display order.
        // BUT the rules say "First training of the first program".
        // Usually "first" implies `position` in the DB.
        // So I should look at `position`.
        
        final sortedByPos = List<Training>.from(program.trainings)..sort((a, b) => a.position.compareTo(b.position));
        
        if (sortedByPos.isNotEmpty) {
            firstTrainingId = sortedByPos.first.id;
            break; // Found the global first training
        }
    }

    final List<Map<String, dynamic>> updates = [];
    bool hasChanges = false;

    for (int i = 0; i < programs.length; i++) {
      final program = programs[i];
      final List<Training> updatedTrainings = [];

      for (final training in program.trainings) {
        bool shouldBeLocked = true;

        if (isPremium) {
          shouldBeLocked = false;
        } else {
          // PROG BASIC
          // Unlocked ONLY if it is the first training of the first program
          if (training.id == firstTrainingId) {
            shouldBeLocked = false;
          } else {
            shouldBeLocked = true;
          }
        }

        if (training.locked != shouldBeLocked) {
        //   debugPrint('Fixing locked status for ${training.name}: was ${training.locked}, becoming $shouldBeLocked');
          updates.add({
            'id': training.id,
            'locked': shouldBeLocked,
          });
          updatedTrainings.add(training.copyWith(locked: shouldBeLocked));
          hasChanges = true;
        } else {
          updatedTrainings.add(training);
        }
      }
      
      if (hasChanges) {
          // Update the program with the modified trainings
           programs[i] = Program(
            id: program.id,
            name: program.name,
            trainings: updatedTrainings,
            position: program.position,
            dashboard: program.dashboard,
            app: program.app,
          );
      }
    }

    if (updates.isNotEmpty) {
      // Bulk update to DB
      // Supabase generic upsert or update. 
      // upsert works if we provide primary key.
      try {
        await _supabase.from('trainings').upsert(updates, onConflict: 'id');
      } catch (e) {
        debugPrint('Error syncing locked status to DB: $e');
      }
    }

    return programs;
  }

  Future<List<Program>> getLocalPrograms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? programsJson = prefs.getString(_programsCacheKey);
      
      if (programsJson != null) {
        final List<dynamic> decoded = jsonDecode(programsJson);
        return decoded.map((json) => Program.fromJson(json)).toList();
      }
    } catch (e) {
      // Ignore cache errors
    }
    return [];
  }

  Future<void> saveLocalPrograms(List<Program> programs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(programs.map((p) => p.toJson()).toList());
      await prefs.setString(_programsCacheKey, encoded);
    } catch (e) {
      // Ignore cache errors
    }
  }

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
      'id, name, position, dashboard, app, trainings(id, name, position, app, dashboard, locked, program_id)',
            )
            .eq('user_id', userId)
            .order('position', ascending: true);

        // Fetch sessions for stats
        final sessionsResponse = await _supabase
            .from('training_sessions')
            .select('training_id, performed_at, duration')
            .eq('user_id', userId);

        final sessions = (sessionsResponse as List<dynamic>).cast<Map<String, dynamic>>();
        final localPrograms = await getLocalPrograms();

        var programs = await _processProgramsResponse(response, userId, sessions, localPrograms);
        programs = await _ensureLockedConsistency(programs);
        await saveLocalPrograms(programs);
        return programs;
      } catch (_) {
        // Fallback: fetch without dashboard column on trainings
        final response = await _supabase
            .from('programs')
            .select(
      'id, name, position, dashboard, trainings(id, name, position, app, locked, program_id)',
            )
            .eq('user_id', userId)
            .order('position', ascending: true);



        // Fetch sessions even in fallback
        final sessionsResponse = await _supabase
            .from('training_sessions')
            .select('training_id, performed_at, duration')
            .eq('user_id', userId);

        final sessions = (sessionsResponse as List<dynamic>).cast<Map<String, dynamic>>();
        final localPrograms = await getLocalPrograms();

        var programs = await _processProgramsResponse(response, userId, sessions, localPrograms);
        programs = await _ensureLockedConsistency(programs);
        await saveLocalPrograms(programs);
        return programs;
      }
    } catch (e) {
      throw Exception('Erreur lors du chargement des programmes: $e');
    }
  }

  Future<List<Program>> _processProgramsResponse(
    List<dynamic> data,
    String userId,
    List<Map<String, dynamic>> sessions,
    List<Program> localPrograms,
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
          app: newProgram['app'] ?? true,
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

          // Calculate stats for each visible training
          final visibleTrainingsWithStats = visibleTrainings.map((t) {
            final trainingSessions = sessions.where((s) => s['training_id'].toString() == t.id).toList();
            
            DateTime? lastDate;
            int? avgDuration;

            if (trainingSessions.isNotEmpty) {
              // Calculate last session date
              trainingSessions.sort((a, b) {
                final dateA = DateTime.tryParse(a['performed_at'] as String) ?? DateTime(0);
                final dateB = DateTime.tryParse(b['performed_at'] as String) ?? DateTime(0);
                return dateB.compareTo(dateA); // Descending
              });
              lastDate = DateTime.tryParse(trainingSessions.first['performed_at'] as String);

              // Calculate average duration
              final durations = trainingSessions
                  .map((s) => s['duration'] as int?)
                  .where((d) => d != null)
                  .toList();
              
              if (durations.isNotEmpty) {
                final totalcheck = durations.fold<int>(0, (sum, d) => sum + d!);
                avgDuration = (totalcheck / durations.length).round();
              }
            }

            return Training(
              id: t.id,
              name: t.name,
              app: t.app,
              dashboard: t.dashboard,
              position: t.position,
              programId: t.programId,
              lastSessionDate: lastDate,
              averageDurationMinutes: avgDuration,
              sessionCount: trainingSessions.length,
              locked: t.locked,
            );
          }).toList();

          // MERGING STRATEGY:
          // Check against local cache. If local cache has a NEWER date for a training, keep it.
          // This prevents the UI from jumping back if the remote sync is slightly stale.
          if (localPrograms.isNotEmpty) {
            // Find the corresponding local program
            final localProgram = localPrograms.firstWhere(
              (lp) => lp.id == program.id,
              orElse: () => Program(
                  id: '-1',
                  name: '',
                  trainings: [],
                  position: 0,
                  dashboard: false,
                  app: false),
            );

            if (localProgram.id != '-1') {
              for (var i = 0; i < visibleTrainingsWithStats.length; i++) {
                 final remoteTraining = visibleTrainingsWithStats[i];
                 final localTraining = localProgram.trainings.firstWhere(
                   (lt) => lt.id == remoteTraining.id,
                   orElse: () => remoteTraining, // fallback to remote if not found
                 );

                 // If local training is the same ID (it should be) and has a date
                 if (localTraining.id == remoteTraining.id && localTraining.lastSessionDate != null) {
                   final remoteDate = remoteTraining.lastSessionDate;
                   final localDate = localTraining.lastSessionDate!;

                   // Stabilized Merge: prefer Local if it's newer OR relatively close (within 1 min) to remote.
                   // This covers cases where local is "just now" and remote is "just now" (but maybe slightly skewed or lagged).
                   // It assumes local is the source of truth for immediate actions.
                   final isLocalNewerOrClose = remoteDate == null || 
                       localDate.isAfter(remoteDate.subtract(const Duration(minutes: 1)));

                   if (isLocalNewerOrClose) {
                      // Use local stats
                      // debugPrint('Using local stats for ${remoteTraining.name} because local date ($localDate) is newer/close to remote ($remoteDate)');
                      visibleTrainingsWithStats[i] = remoteTraining.copyWith(
                        lastSessionDate: localDate,
                        averageDurationMinutes: localTraining.averageDurationMinutes,
                        sessionCount: localTraining.sessionCount,
                      );
                   }
                 }
              }
            }
          }

           // Sort trainings: least recently done FIRST
          visibleTrainingsWithStats.sort((a, b) {
            final dateA = a.lastSessionDate;
            final dateB = b.lastSessionDate;

            if (dateA == null && dateB == null) {
              return a.position.compareTo(b.position); // Default to manual order
            }
            if (dateA == null) return -1; // Never done comes first
            if (dateB == null) return 1;

            return dateA.compareTo(dateB); // Oldest date (smaller timestamp) comes first
          });

          return Program(
            id: program.id,
            name: program.name,
            trainings: visibleTrainingsWithStats,
            position: program.position,
            dashboard: program.dashboard,
            app: program.app,
          );
        })
        .where((p) => p.trainings.isNotEmpty && p.app)
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
    String? note,
    String? material,
  }) async {
    List<num?>? _prepareNumericValues(List<String>? values) {
      if (values == null) return null;

      return values
          .map((value) {
            final normalized = value.trim();
            if (normalized.isEmpty || normalized == '-') return null;

            final parsed = num.tryParse(normalized.replaceAll(',', '.'));
            return parsed;
          })
          .toList();
    }

    List<String>? _prepareEfforts(List<String>? values) {
      if (values == null) return null;

      return values
          .map((value) {
            final normalized = value.trim();
            return normalized.isEmpty ? 'parfait' : normalized;
          })
          .toList();
    }

    try {
      final updates = <String, dynamic>{};
      final preparedRepetitions = _prepareNumericValues(repetitions);
      final preparedWeights = _prepareNumericValues(weights);
      final preparedEfforts = _prepareEfforts(efforts);

      if (preparedRepetitions != null) updates['repetitions'] = preparedRepetitions;
      if (preparedWeights != null) updates['poids'] = preparedWeights;
      if (preparedEfforts != null) updates['effort'] = preparedEfforts;
      if (rest != null) updates['repos'] = rest;
      if (note != null) updates['note'] = note;
      if (material != null) updates['materiel'] = material;

      if (updates.isEmpty) return;

      await _supabase.from('training_rows').update(updates).eq('id', rowId);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'exercice: $e');
    }
  }

  Future<void> updateRestDuration(String rowId, int restInSeconds) async {
    await updateTrainingRow(rowId, rest: restInSeconds.toString());
  }

  Future<void> _updateLocalTrainingStats(String trainingId, int duration, DateTime performedAt) async {
    try {
      final programs = await getLocalPrograms();
      bool changed = false;

      for (var i = 0; i < programs.length; i++) {
        final program = programs[i];
        final trainingIndex = program.trainings.indexWhere((t) => t.id == trainingId);

        if (trainingIndex != -1) {
          final training = program.trainings[trainingIndex];
          
          final newAverage = training.averageDurationMinutes != null 
              ? ((training.averageDurationMinutes! + duration) / 2).round() 
              : duration;

          final updatedTraining = training.copyWith(
            lastSessionDate: performedAt,
            averageDurationMinutes: newAverage,
            sessionCount: (training.sessionCount ?? 0) + 1,
          );

          program.trainings[trainingIndex] = updatedTraining;

          // Re-sort trainings: least recently done FIRST
          program.trainings.sort((a, b) {
            final dateA = a.lastSessionDate;
            final dateB = b.lastSessionDate;

            if (dateA == null && dateB == null) {
              return a.position.compareTo(b.position);
            }
            if (dateA == null) return -1;
            if (dateB == null) return 1;

            return dateA.compareTo(dateB);
          });

          changed = true;
          break; // Found and updated, no need to continue
        }
      }

      if (changed) {
        await saveLocalPrograms(programs);
      }
    } catch (e) {
      // Ignore errors in local cache update, it's just an optimization
      debugPrint('Error updating local stats: $e');
    }
  }

  Future<void> saveTrainingSession({
    required String userId,
    required String trainingId,
    required List<TrainingRow> completedRows,
    required int duration,
  }) async {
    try {
      final performedAt = DateTime.now().toUtc();
      
      // 1. Create session
      final sessionResponse = await _supabase
          .from('training_sessions')
          .insert({
            'user_id': userId,
            'training_id': trainingId,
            'performed_at': performedAt.toIso8601String(),
            'duration': duration,
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
            var weightToUse = weight.trim();
            if (weightToUse.isEmpty || weightToUse == '-') {
              weightToUse = '0';
            }
            // Also replace commas with dots just in case it's being passed as string but checked as numeric downstream
            weightToUse = weightToUse.replaceAll(',', '.');
            
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

      // 4. Update local cache immediately to prevent UI jump
      await _updateLocalTrainingStats(trainingId, duration, performedAt);

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
  Future<Map<String, dynamic>> getPreviousSessionStats({
    required String userId,
    required String trainingId,
  }) async {
    try {
      // 1. Get all previous sessions for average duration
      final sessionsResponse = await _supabase
          .from('training_sessions')
          .select('duration, performed_at, id')
          .eq('user_id', userId)
          .eq('training_id', trainingId)
          .order('performed_at', ascending: false); // Newest first

      final sessions = (sessionsResponse as List<dynamic>).cast<Map<String, dynamic>>();

      if (sessions.isEmpty) {
        return {
          'averageDuration': null,
          'lastVolume': null,
          'lastReps': null,
        };
      }

      // Calculate average duration
      final durations = sessions
          .map((s) => s['duration'] as int?)
          .where((d) => d != null)
          .toList();
      
      int? avgDuration;
      if (durations.isNotEmpty) {
        final total = durations.fold<int>(0, (sum, d) => sum + d!);
        avgDuration = (total / durations.length).round();
      }

      // 2. Get details of the most recent session (sessions[0]) to calculate Volume and Reps
      final lastSessionId = sessions[0]['id'];
      
      // Fetch sets for the last session
      // We need to join: training_sessions -> training_session_exercises -> training_session_sets
      // Supabase join syntax:
      final setsResponse = await _supabase
          .from('training_session_exercises')
          .select('id, training_session_sets(repetitions, weights)')
          .eq('session_id', lastSessionId);

      final exercises = (setsResponse as List<dynamic>);
      
      double lastVolume = 0.0;
      int lastReps = 0;

      for (final exercise in exercises) {
        final sets = (exercise['training_session_sets'] as List<dynamic>);
        for (final set in sets) {
          final reps = set['repetitions'] as int? ?? 0;
           // Weights are stored as List<dynamic> (jsonb) or just handle as List
           // In saveTrainingSession we store as List<String>.
           // In DB it might be jsonb.
           // Let's check how we handle it. In saveTrainingSession: 'weights': weightsList
           // where weightsList is List<String>.
           
           final weightsData = set['weights'];
           double weightVal = 0.0;
           
           if (weightsData is List) {
             if (weightsData.isNotEmpty) {
               // Usually for a standard set, we have as many weights as reps? 
               // Or if it's one weight for the whole set?
               // The DB schema for 'weights' column in 'training_session_sets' seems to be an array.
               // We sum volume = reps * weight. 
               // But wait, if we have 10 reps and [10, 10, 10...] weights?
               // Or usually it's [20] for the whole set?
               // Let's assume uniform weight for the set or sum them up?
               // Standard volume = reps * weight.
               // If weights is [20, 20, 20...], then it's 20 * reps? NO.
               // GLIFT logic: weight is usually constant per set.
               // Let's look at `_finishTraining` in `ActiveTrainingPage` to see how volume is calculated CURRENTLY.
               
               // In ActiveTrainingPage:
               // final weight = double.tryParse(weightsList.length > i ? weightsList[i] : '0') ?? 0.0;
               // totalVolume += (reps * weight);
               // Wait, the loop `for (int i = 0; i < repsList.length; i++)` iterates over SETS (series).
               // `repsList` is List of strings for the ROW (exercise). e.g. ["10", "10", "10"] for 3 sets.
               // So `reps` is reps for ONE set.
               // `weight` is weight for ONE set.
               // So specific set volume = reps * weight.
               
               // Back to `getPreviousSessionStats`:
               // `exercise` is one Exercise in the session.
               // `sets` is the list of sets performed for that exercise.
               // `set` is one SET.
               // `set['weights']` is what we stored. In `saveTrainingSession`:
               // `final weightsList = List<String>.filled(reps, weightToUse);`
               // So we store a list of weights, one per rep!
               // So `set['weights']` is `["20.0", "20.0", ...]` (length = reps).
               // So we can take the first element as the weight for the set?
               // Yes, provided all are same. Or we can sum them? No volume is sets * reps * weight.
               // If we store `["20", "20"]` for 2 reps. 
               // Volume = 2 * 20 = 40.
               // Or sum of elements? 20+20=40. Yes.
               // So we can just sum the numeric values in the weights list.
               
               for (final w in weightsData) {
                 final wStr = w.toString();
                 final wDouble = double.tryParse(wStr) ?? 0.0;
                 weightVal += wDouble;
               }
             }
           }
           
           lastVolume += weightVal;
           lastReps += reps;
        }
      }

      return {
        'averageDuration': avgDuration,
        'lastVolume': lastVolume,
        'lastReps': lastReps,
      };

    } catch (e) {
      debugPrint('Error getting previous session stats: $e');
      return {
          'averageDuration': null,
          'lastVolume': null,
          'lastReps': null,
      };
    }
  }

  Future<int> getTotalSessionCount(String userId) async {
    try {
      final response = await _supabase
          .from('training_sessions')
          .count()
          .eq('user_id', userId);
      
      return response;
    } catch (e) {
      debugPrint('Error getting session count: $e');
      return 0;
    }
  }
}
