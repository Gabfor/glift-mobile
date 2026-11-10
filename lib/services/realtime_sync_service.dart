import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'settings_service.dart';

class RealtimeSyncService {
  static final RealtimeSyncService _instance = RealtimeSyncService._internal();
  static RealtimeSyncService get instance => _instance;

  RealtimeSyncService._internal();

  RealtimeChannel? _channel;
  SupabaseClient? _supabase;
  String? _currentUserId;
  Timer? _debounceTimer;

  bool get isSubscribed => _channel != null;

  /// Start listening to real-time changes for the current user.
  void start(SupabaseClient supabase) {
    _supabase = supabase;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      debugPrint('[RealtimeSyncService] No authenticated user, skipping realtime setup.');
      return;
    }

    if (_channel != null && _currentUserId == userId) {
      debugPrint('[RealtimeSyncService] Already subscribed for user $userId.');
      return;
    }

    stop();
    _currentUserId = userId;

    try {
      final channelName = 'user-sync-$userId';
      final channel = supabase.channel(channelName);

      // 1. Programs changes (filtered by user_id)
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'programs',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) {
          debugPrint('[RealtimeSyncService] programs change: ${payload.eventType}');
          _onDataChange();
        },
      );

      // 2. Trainings changes (filtered by user_id)
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'trainings',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) {
          debugPrint('[RealtimeSyncService] trainings change: ${payload.eventType}');
          _onDataChange();
        },
      );

      // 3. Training rows changes (exercises)
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'training_rows',
        callback: (payload) {
          debugPrint('[RealtimeSyncService] training_rows change: ${payload.eventType}');
          _onDataChange();
        },
      );

      // 4. Preferences changes (filtered by user_id in id)
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'preferences',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: userId,
        ),
        callback: (payload) {
          debugPrint('[RealtimeSyncService] preferences change: ${payload.eventType}');
          _onSettingsChange();
        },
      );

      // 5. Profiles changes (subscription plan, premium expiration)
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'profiles',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: userId,
        ),
        callback: (payload) {
          debugPrint('[RealtimeSyncService] profiles change: ${payload.eventType}');
          _onSettingsChange();
        },
      );

      // 6. Training sessions (completed workouts)
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'training_sessions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) {
          debugPrint('[RealtimeSyncService] training_sessions change: ${payload.eventType}');
          _onDataChange();
        },
      );

      // 7. Dashboard preferences
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'dashboard_preferences',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) {
          debugPrint('[RealtimeSyncService] dashboard_preferences change: ${payload.eventType}');
          _onDataChange();
        },
      );

      channel.subscribe((status, [error]) {
        debugPrint('[RealtimeSyncService] Channel status: $status (error: $error)');
      });

      _channel = channel;
      debugPrint('[RealtimeSyncService] Subscribed to real-time sync for user $userId.');
    } catch (e) {
      debugPrint('[RealtimeSyncService] Error starting real-time sync: $e');
    }
  }

  void _onDataChange() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      debugPrint('[RealtimeSyncService] Debounced sync triggered (data update).');
      SettingsService.instance.notifyDataChanged();
    });
  }

  void _onSettingsChange() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      debugPrint('[RealtimeSyncService] Debounced sync triggered (settings update).');
      try {
        await SettingsService.instance.syncFromSupabase();
      } catch (e) {
        debugPrint('[RealtimeSyncService] Error syncing settings: $e');
      }
      SettingsService.instance.notifyDataChanged();
    });
  }

  void ensureSubscribed(SupabaseClient supabase) {
    final userId = supabase.auth.currentUser?.id;
    if (_channel == null || _currentUserId != userId) {
      start(supabase);
    }
  }

  void stop() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    if (_channel != null) {
      try {
        _supabase?.removeChannel(_channel!);
      } catch (_) {}
      _channel = null;
    }
    _currentUserId = null;
  }
}

