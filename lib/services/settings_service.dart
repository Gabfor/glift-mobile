import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  static SettingsService get instance => _instance;

  SettingsService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  // Keys
  static const String _kDisplayType = 'timer_display_type';
  static const String _kMaterial = 'exercise_material_enabled';
  static const String _kAutoTrigger = 'timer_auto_trigger_enabled';

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

  Future<void> _initIfNeeded() async {
    if (!_initialized) {
      await init();
    }
  }
}
