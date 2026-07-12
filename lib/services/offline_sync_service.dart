import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase/supabase.dart';
import '../models/training_row.dart';
import '../repositories/program_repository.dart';

class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  static OfflineSyncService get instance => _instance;

  OfflineSyncService._internal();

  static const String _kPendingSessionsKey = 'pending_training_sessions';
  bool _isSyncing = false;

  /// Add a training session to the local offline queue.
  Future<void> queueSession({
    required String userId,
    required String trainingId,
    required List<TrainingRow> completedRows,
    required int duration,
    required DateTime performedAt,
    required List<String> achievedGoalExerciseIds,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> pendingJsonList = prefs.getStringList(_kPendingSessionsKey) ?? [];

      final Map<String, dynamic> sessionData = {
        'userId': userId,
        'trainingId': trainingId,
        'completedRows': completedRows.map((r) => r.toJson()).toList(),
        'duration': duration,
        'performedAt': performedAt.toIso8601String(),
        'achievedGoalExerciseIds': achievedGoalExerciseIds,
      };

      pendingJsonList.add(jsonEncode(sessionData));
      await prefs.setStringList(_kPendingSessionsKey, pendingJsonList);
      debugPrint('OfflineSyncService: Session queued successfully. Total pending: ${pendingJsonList.length}');
    } catch (e) {
      debugPrint('OfflineSyncService: Error queuing session: $e');
    }
  }

  /// Get the number of pending sessions in the queue.
  Future<int> getPendingSessionCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? pending = prefs.getStringList(_kPendingSessionsKey);
      return pending?.length ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Tries to synchronize all pending training sessions to the Supabase backend.
  Future<void> syncPendingSessions(SupabaseClient supabase) async {
    if (_isSyncing) {
      debugPrint('OfflineSyncService: Sync already in progress, skipping.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final List<String>? pendingJsonList = prefs.getStringList(_kPendingSessionsKey);

    if (pendingJsonList == null || pendingJsonList.isEmpty) {
      return;
    }

    _isSyncing = true;
    debugPrint('OfflineSyncService: Starting sync of ${pendingJsonList.length} sessions.');

    final List<String> remainingSessions = List<String>.from(pendingJsonList);

    try {
      final repo = ProgramRepository(supabase);

      // Iterate from oldest to newest
      for (final sessionStr in pendingJsonList) {
        final Map<String, dynamic> session = jsonDecode(sessionStr);
        final String userId = session['userId'];
        final String trainingId = session['trainingId'];
        final List<dynamic> rowsJson = session['completedRows'];
        final int duration = session['duration'];
        final DateTime performedAt = DateTime.parse(session['performedAt']);
        final List<dynamic> achievedGoalExerciseIds = session['achievedGoalExerciseIds'] ?? [];

        final List<TrainingRow> completedRows = rowsJson
            .map((r) => TrainingRow.fromJson(r as Map<String, dynamic>))
            .toList();

        try {
          // 1. Save session to history
          await repo.saveTrainingSession(
            userId: userId,
            trainingId: trainingId,
            completedRows: completedRows,
            duration: duration,
            performedAt: performedAt,
          );

          // 2. Update templates (last used weights, reps, efforts)
          await Future.wait(completedRows.map((row) => repo.updateTrainingRow(
            row.id,
            repetitions: row.repetitions,
            weights: row.weights,
            efforts: row.efforts,
          )));

          // 3. Mark achieved goals in backend if any
          if (achievedGoalExerciseIds.isNotEmpty) {
            final exerciseSettings = await repo.getDashboardPreferences(userId);
            if (exerciseSettings != null) {
              bool settingsUpdated = false;
              final exercises = exerciseSettings['exercises'];
              if (exercises != null && exercises is Map) {
                for (final rowId in achievedGoalExerciseIds) {
                  final setting = exercises[rowId];
                  if (setting != null && setting['goal'] != null) {
                    setting['goal']['achieved'] = true;
                    settingsUpdated = true;
                  }
                }
              }
              if (settingsUpdated) {
                await repo.updateDashboardPreferences(userId, exerciseSettings);
              }
            }
          }

          // Successfully synced, remove from memory
          remainingSessions.remove(sessionStr);
          debugPrint('OfflineSyncService: Session synced successfully for training: $trainingId');
        } catch (e) {
          // Stop syncing if we hit a network error to preserve order and avoid spamming
          debugPrint('OfflineSyncService: Failed to sync session for training $trainingId: $e');
          break;
        }
      }

      // Update local storage with remaining (unsynced) sessions
      await prefs.setStringList(_kPendingSessionsKey, remainingSessions);
    } catch (e) {
      debugPrint('OfflineSyncService: Error during sync loop: $e');
    } finally {
      _isSyncing = false;
      debugPrint('OfflineSyncService: Sync finished. Remaining sessions in queue: ${(prefs.getStringList(_kPendingSessionsKey) ?? []).length}');
    }
  }
}
