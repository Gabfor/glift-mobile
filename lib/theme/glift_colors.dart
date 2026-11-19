import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Palette de marque Glift, éditable depuis l'admin web (page « Couleurs »).
///
/// Les ids correspondent à `glift-web/src/constants/colorPalette.ts`.
/// Les valeurs modifiées sont stockées dans la table Supabase `settings`
/// (clés `color_<id>`), mises en cache localement et appliquées au démarrage.
/// Hors ligne ou en cas d'erreur, le cache puis les valeurs par défaut sont utilisés.
class GliftColors {
  const GliftColors._();

  static const String _settingPrefix = 'color_';
  static const String _cacheKey = 'glift_color_overrides_v1';

  static const Map<String, int> _defaults = {
  'brandPrimaryHover': 0xFF6660E4,
  'brandPrimary': 0xFF7069FA,
  'focusRing': 0xFFA1A5FD,
  'violetTint': 0xFFF4F5FE,
  'violetSoft': 0xFFE6E6FF,
  'violetSofter': 0xFFD6D6FF,
  'violetSoftest': 0xFFC2C2FF,
  'navyDeep': 0xFF2E3142,
  'brandStrongHover': 0xFF2E3459,
  'brandStrong': 0xFF3A416F,
  'textBody': 0xFF5D6494,
  'borderSoft': 0xFFD7D4DC,
  'greyMedium': 0xFFC2BFC6,
  'surfaceSubtle': 0xFFECE9F1,
  'surfaceMuted': 0xFFF2F1F6,
  'greyBlue': 0xFFB1BACC,
  'surfacePrimary': 0xFFFBFCFE,
  'surfaceHighlight': 0xFFF6F6FA,
  'surfaceAlt': 0xFFFAFAFF,
  'surfaceLavender': 0xFFF7F7FF,
  'accentSuccess': 0xFF00D591,
  'successSurface': 0xFFDCFAF1,
  'accentDanger': 0xFFEF4F4E,
  'accentDangerHover': 0xFFBA2524,
  'dangerSurface': 0xFFFFF1F1,
  'warning': 0xFFE2BA00,
  'gold': 0xFFF0C863,
  'warningSurface': 0xFFFFF7CB,
  };

  static final Map<String, int> _overrides = {};

  static Color _color(String id) => Color(_overrides[id] ?? _defaults[id]!);

  /// Applique le cache local (rapide, avant tout appel réseau).
  static Future<void> loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_cacheKey) ?? const <String>[];
      _applyEntries(raw.map((e) => e.split('=')).where((p) => p.length == 2).map((p) => MapEntry(p[0], p[1])));
    } catch (e) {
      debugPrint('[GliftColors] cache error: $e');
    }
  }

  /// Récupère les couleurs depuis Supabase (avec timeout) et met le cache à jour.
  static Future<void> refresh(SupabaseClient client, {Duration timeout = const Duration(seconds: 3)}) async {
    try {
      final rows = await client
          .from('settings')
          .select('key, value')
          .like('key', '$_settingPrefix%')
          .timeout(timeout);
      final entries = <MapEntry<String, String>>[];
      for (final row in rows) {
        final key = (row['key'] as String).substring(_settingPrefix.length);
        entries.add(MapEntry(key, row['value'] as String));
      }
      _overrides.clear();
      _applyEntries(entries);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _cacheKey,
        _overrides.entries.map((e) => '${e.key}=${e.value.toRadixString(16)}').toList(),
      );
    } catch (e) {
      debugPrint('[GliftColors] refresh error: $e');
    }
  }

  static void _applyEntries(Iterable<MapEntry<String, String>> entries) {
    for (final entry in entries) {
      if (!_defaults.containsKey(entry.key)) continue;
      final value = entry.value.trim();
      int? parsed;
      if (RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value)) {
        parsed = int.parse('FF${value.substring(1)}', radix: 16);
      } else if (RegExp(r'^[0-9a-f]{8}$').hasMatch(value)) {
        parsed = int.parse(value, radix: 16); // format du cache
      }
      if (parsed != null && parsed != _defaults[entry.key]) {
        _overrides[entry.key] = parsed;
      } else {
        _overrides.remove(entry.key);
      }
    }
  }

  /// Violet principal (hover) (défaut #6660E4)
  static Color get brandPrimaryHover => _color('brandPrimaryHover');
  /// Violet principal (défaut #7069FA)
  static Color get brandPrimary => _color('brandPrimary');
  /// Violet clair (focus) (défaut #A1A5FD)
  static Color get focusRing => _color('focusRing');
  /// Violet très clair (défaut #F4F5FE)
  static Color get violetTint => _color('violetTint');
  /// Violet pâle (défaut #E6E6FF)
  static Color get violetSoft => _color('violetSoft');
  /// Violet pâle 2 (défaut #D6D6FF)
  static Color get violetSofter => _color('violetSofter');
  /// Violet pâle 3 (défaut #C2C2FF)
  static Color get violetSoftest => _color('violetSoftest');
  /// Bleu nuit profond (défaut #2E3142)
  static Color get navyDeep => _color('navyDeep');
  /// Bleu nuit (hover) (défaut #2E3459)
  static Color get brandStrongHover => _color('brandStrongHover');
  /// Bleu nuit (titres) (défaut #3A416F)
  static Color get brandStrong => _color('brandStrong');
  /// Bleu gris (texte) (défaut #5D6494)
  static Color get textBody => _color('textBody');
  /// Bordure (défaut #D7D4DC)
  static Color get borderSoft => _color('borderSoft');
  /// Gris moyen (défaut #C2BFC6)
  static Color get greyMedium => _color('greyMedium');
  /// Gris clair (défaut #ECE9F1)
  static Color get surfaceSubtle => _color('surfaceSubtle');
  /// Gris très clair (défaut #F2F1F6)
  static Color get surfaceMuted => _color('surfaceMuted');
  /// Gris bleuté (défaut #B1BACC)
  static Color get greyBlue => _color('greyBlue');
  /// Fond principal (défaut #FBFCFE)
  static Color get surfacePrimary => _color('surfacePrimary');
  /// Fond surligné (défaut #F6F6FA)
  static Color get surfaceHighlight => _color('surfaceHighlight');
  /// Fond alternatif (défaut #FAFAFF)
  static Color get surfaceAlt => _color('surfaceAlt');
  /// Fond lavande (défaut #F7F7FF)
  static Color get surfaceLavender => _color('surfaceLavender');
  /// Vert (défaut #00D591)
  static Color get accentSuccess => _color('accentSuccess');
  /// Fond vert (défaut #DCFAF1)
  static Color get successSurface => _color('successSurface');
  /// Rouge (défaut #EF4F4E)
  static Color get accentDanger => _color('accentDanger');
  /// Rouge (hover) (défaut #BA2524)
  static Color get accentDangerHover => _color('accentDangerHover');
  /// Fond rouge (défaut #FFF1F1)
  static Color get dangerSurface => _color('dangerSurface');
  /// Jaune (défaut #E2BA00)
  static Color get warning => _color('warning');
  /// Or (défaut #F0C863)
  static Color get gold => _color('gold');
  /// Fond jaune (défaut #FFF7CB)
  static Color get warningSurface => _color('warningSurface');
}
