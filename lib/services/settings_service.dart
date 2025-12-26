import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase/supabase.dart';
import 'package:flutter/foundation.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  static SettingsService get instance => _instance;

  SettingsService._internal();

  late SharedPreferences _prefs;
  SupabaseClient? _supabase;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    weightUnitNotifier.value = getWeightUnit();
  }

  Future<void> initSupabase(SupabaseClient client) async {
    _supabase = client;
    await syncFromSupabase();
  }

  Future<void> syncFromSupabase() async {
    final user = _supabase?.auth.currentUser;
    if (user == null) return;

    try {
      final response = await _supabase!
          .from('preferences')
          .select('weight_unit, show_effort, show_materiel, show_repos, show_link, show_notes')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        if (response['weight_unit'] != null) {
          final unit = response['weight_unit'] as String;
          final localUnit = unit == 'lb' ? 'imperial' : 'metric';
          if (localUnit != getWeightUnit()) {
            await _prefs.setString(_kWeightUnit, localUnit);
            weightUnitNotifier.value = localUnit;
          }
        }
        if (response['show_effort'] != null) {
            final showEffort = response['show_effort'] as bool;
            if (showEffort != getShowEffort()) {
                await _prefs.setBool(_kShowEffort, showEffort);
            }
        }
        if (response['show_materiel'] != null) {
            final showMateriel = response['show_materiel'] as bool;
            if (showMateriel != getMaterialEnabled()) {
                await _prefs.setBool(_kMaterial, showMateriel);
            }
        }
        if (response['show_repos'] != null) {
            final showRepos = response['show_repos'] as bool;
            if (showRepos != getShowRepos()) {
                await _prefs.setBool(_kShowRepos, showRepos);
            }
        }
        if (response['show_link'] != null) {
            final showLink = response['show_link'] as bool;
            if (showLink != getShowLinks()) {
                await _prefs.setBool(_kShowLinks, showLink);
            }
        }
        if (response['show_notes'] != null) {
            final showNotes = response['show_notes'] as bool;
            if (showNotes != getShowNotes()) {
                await _prefs.setBool(_kShowNotes, showNotes);
                // Enforce side effect on sync
                if (!showNotes) {
                   await _prefs.setBool(_kMaterial, false);
                }
            }
        }
      }
    } catch (e) {
      // Create preference row if it doesn't exist? Or just ignore.
      // Usually preferences are created on signup.
      print('Error syncing settings: $e');
    }
  }

  // Keys
  static const String _kDisplayType = 'timer_display_type';
  static const String _kMaterial = 'exercise_material_enabled';
  static const String _kAutoTrigger = 'timer_auto_trigger_enabled';
  static const String _kWeightUnit = 'weight_unit';
  static const String _kSoundEffect = 'timer_sound_effect';
  static const String _kSoundEnabled = 'timer_sound_enabled';
  static const String _kVibrationEnabled = 'timer_vibration_enabled';
  static const String _kShowEffort = 'show_effort';
  static const String _kShowRepos = 'show_repos';

  // Notifiers
  final ValueNotifier<String> weightUnitNotifier = ValueNotifier('metric');

  // Display Type
  Future<void> saveDisplayType(String type) async {
    await _initIfNeeded();
    await _prefs.setString(_kDisplayType, type);
  }

  String getDisplayType() {
    if (!_initialized) return 'Miniature';
    return _prefs.getString(_kDisplayType) ?? 'Miniature';
  }

  // Material
  Future<void> saveMaterialEnabled(bool enabled) async {
    await _initIfNeeded();
    await _prefs.setBool(_kMaterial, enabled);

    final user = _supabase?.auth.currentUser;
    if (user != null) {
      try {
        await _supabase!.from('preferences').upsert({
          'id': user.id,
          'show_materiel': enabled,
        });
      } catch (e) {
        print('Error saving show_materiel to Supabase: $e');
      }
    }
  }

  bool getMaterialEnabled() {
    if (!_initialized) return true;
    return _prefs.getBool(_kMaterial) ?? true;
  }

  // Auto Trigger
  Future<void> saveAutoTriggerEnabled(bool enabled) async {
    await _initIfNeeded();
    await _prefs.setBool(_kAutoTrigger, enabled);
  }

  bool getAutoTriggerEnabled() {
    if (!_initialized) return true;
    return _prefs.getBool(_kAutoTrigger) ?? true;
  }

  // Weight Unit
  Future<void> saveWeightUnit(String unit) async {
    await _initIfNeeded();
    await _prefs.setString(_kWeightUnit, unit);
    weightUnitNotifier.value = unit;

    final user = _supabase?.auth.currentUser;
    if (user != null) {
      final dbUnit = unit == 'imperial' ? 'lb' : 'kg';
      try {
        await _supabase!.from('preferences').upsert({
          'id': user.id,
          'weight_unit': dbUnit,
        });
      } catch (e) {
        print('Error saving weight unit to Supabase: $e');
      }
    }
  }

  String getWeightUnit() {
    if (!_initialized) return 'metric';
    return _prefs.getString(_kWeightUnit) ?? 'metric';
  }

  // Sound Effect
  Future<void> saveSoundEffect(String effect) async {
    await _initIfNeeded();
    await _prefs.setString(_kSoundEffect, effect);
  }

  String getSoundEffect() {
    if (!_initialized) return 'radar';
    return _prefs.getString(_kSoundEffect) ?? 'radar';
  }

  // Sound Enabled
  Future<void> saveSoundEnabled(bool enabled) async {
    await _initIfNeeded();
    await _prefs.setBool(_kSoundEnabled, enabled);
  }

  bool getSoundEnabled() {
    if (!_initialized) return true;
    return _prefs.getBool(_kSoundEnabled) ?? true;
  }

  // Vibration Enabled
  Future<void> saveVibrationEnabled(bool enabled) async {
    await _initIfNeeded();
    await _prefs.setBool(_kVibrationEnabled, enabled);
  }

  bool getVibrationEnabled() {
    if (!_initialized) return true;
    return _prefs.getBool(_kVibrationEnabled) ?? true;
  }

  // Default Rest Time
  static const String _kDefaultRestTime = 'default_rest_time';

  Future<void> saveDefaultRestTime(int seconds) async {
    await _initIfNeeded();
    await _prefs.setInt(_kDefaultRestTime, seconds);
  }

  int getDefaultRestTime() {
    if (!_initialized) return 60; // Default 1 min
    return _prefs.getInt(_kDefaultRestTime) ?? 60;
  }

  // Show Effort
  Future<void> saveShowEffort(bool show) async {
    await _initIfNeeded();
    await _prefs.setBool(_kShowEffort, show);

    final user = _supabase?.auth.currentUser;
    if (user != null) {
      try {
        await _supabase!.from('preferences').upsert({
          'id': user.id,
          'show_effort': show,
        });
      } catch (e) {
        print('Error saving show_effort to Supabase: $e');
      }
    }
  }

  bool getShowEffort() {
    if (!_initialized) return true;
    return _prefs.getBool(_kShowEffort) ?? true;
  }

  // Show Repos
  Future<void> saveShowRepos(bool show) async {
    await _initIfNeeded();
    await _prefs.setBool(_kShowRepos, show);

    final user = _supabase?.auth.currentUser;
    if (user != null) {
      try {
        await _supabase!.from('preferences').upsert({
          'id': user.id,
          'show_repos': show,
        });
      } catch (e) {
        print('Error saving show_repos to Supabase: $e');
      }
    }
  }

  bool getShowRepos() {
    if (!_initialized) return true;
    return _prefs.getBool(_kShowRepos) ?? true;
  }

  // Show Links
  static const String _kShowLinks = 'show_links';

  Future<void> saveShowLinks(bool show) async {
    await _initIfNeeded();
    await _prefs.setBool(_kShowLinks, show);

    final user = _supabase?.auth.currentUser;
    if (user != null) {
      try {
        await _supabase!.from('preferences').upsert({
          'id': user.id,
          'show_link': show, // Column name is show_link (singular)
        });
      } catch (e) {
        print('Error saving show_link to Supabase: $e');
      }
    }
  }

  bool getShowLinks() {
    if (!_initialized) return true;
    return _prefs.getBool(_kShowLinks) ?? true;
  }

  // Show Notes
  static const String _kShowNotes = 'show_notes';

  Future<void> saveShowNotes(bool show) async {
    await _initIfNeeded();
    await _prefs.setBool(_kShowNotes, show);

    // Side effect: If Notes are OFF, Material must be OFF.
    if (!show) {
      await saveMaterialEnabled(false);
    }

    final user = _supabase?.auth.currentUser;
    if (user != null) {
      try {
        await _supabase!.from('preferences').upsert({
          'id': user.id,
          'show_notes': show,
        });
      } catch (e) {
        print('Error saving show_notes to Supabase: $e');
      }
    }
  }

  bool getShowNotes() {
    if (!_initialized) return true;
    return _prefs.getBool(_kShowNotes) ?? true;
  }

  Future<void> _initIfNeeded() async {
    if (!_initialized) {
      await init();
    }
  }
}
