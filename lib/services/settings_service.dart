import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase/supabase.dart';

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
  }

  void initSupabase(SupabaseClient client) {
    _supabase = client;
    syncFromSupabase();
  }

  Future<void> syncFromSupabase() async {
    final user = _supabase?.auth.currentUser;
    if (user == null) return;

    try {
      final response = await _supabase!
          .from('preferences')
          .select('weight_unit, show_effort')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        if (response['weight_unit'] != null) {
          final unit = response['weight_unit'] as String;
          final localUnit = unit == 'lb' ? 'imperial' : 'metric';
          if (localUnit != getWeightUnit()) {
            await _prefs.setString(_kWeightUnit, localUnit);
          }
        }
        if (response['show_effort'] != null) {
            final showEffort = response['show_effort'] as bool;
            if (showEffort != getShowEffort()) {
                await _prefs.setBool(_kShowEffort, showEffort);
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

  Future<void> _initIfNeeded() async {
    if (!_initialized) {
      await init();
    }
  }
}
