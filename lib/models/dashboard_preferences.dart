class DashboardPreferences {
  final Map<String, ExerciseDisplaySetting> exerciseSettings;
  final String? selectedProgramId;
  final String? selectedTrainingId;
  final String? selectedExerciseId;
  final bool showStats;

  DashboardPreferences({
    this.exerciseSettings = const {},
    this.selectedProgramId,
    this.selectedTrainingId,
    this.selectedExerciseId,
    this.showStats = false,
  });

  factory DashboardPreferences.fromJson(Map<String, dynamic> json) {
    final rawSettings = json['exercise_settings'];
    final Map<String, ExerciseDisplaySetting> parsedSettings = {};

    if (rawSettings != null && rawSettings is Map) {
      // In Supabase, the structure is { "selectedExerciseId": "...", "exercises": { "id": { ... } } }
      // OR direct map depending on migration history, but web app handles both.
      // Based on web reading: 
      // if (rawValue.selectedExerciseId) { ... return parseSettingsRecord(rawValue.exercises) }
      // else { ... parseSettingsRecord(rawValue) }
      
      Map<String, dynamic> exercisesMap = {};
      if (rawSettings.containsKey('exercises') && rawSettings['exercises'] is Map) {
        exercisesMap = Map<String, dynamic>.from(rawSettings['exercises']);
      } else {
         // Fallback/Legacy structure or direct map
         // Verify if it has 'selectedExerciseId' key to discriminate
         if (!rawSettings.containsKey('selectedExerciseId')) {
            exercisesMap = Map<String, dynamic>.from(rawSettings);
         }
      }

      exercisesMap.forEach((key, value) {
        if (value is Map) {
          parsedSettings[key] = ExerciseDisplaySetting.fromJson(Map<String, dynamic>.from(value));
        }
      });
    }

    return DashboardPreferences(
      exerciseSettings: parsedSettings,
      selectedProgramId: json['selected_program_id'],
      selectedTrainingId: json['selected_training_id'],
      selectedExerciseId: json['selected_exercise_id'],
      showStats: json['show_stats'] ?? false,
    );
  }
  
  ExerciseDisplaySetting getSettingsFor(String exerciseId) {
    return exerciseSettings[exerciseId] ?? ExerciseDisplaySetting.defaultValue();
  }

  DashboardPreferences copyWith({
    Map<String, ExerciseDisplaySetting>? exerciseSettings,
    String? selectedProgramId,
    String? selectedTrainingId,
    String? selectedExerciseId,
    bool? showStats,
  }) {
    return DashboardPreferences(
      exerciseSettings: exerciseSettings ?? this.exerciseSettings,
      selectedProgramId: selectedProgramId ?? this.selectedProgramId,
      selectedTrainingId: selectedTrainingId ?? this.selectedTrainingId,
      selectedExerciseId: selectedExerciseId ?? this.selectedExerciseId,
      showStats: showStats ?? this.showStats,
    );
  }

  Map<String, dynamic> toJson() {
    final settingsMap = <String, dynamic>{};
    exerciseSettings.forEach((key, value) {
      settingsMap[key] = value.toJson();
    });

    return {
      'exercise_settings': settingsMap,
      'selected_program_id': selectedProgramId,
      'selected_training_id': selectedTrainingId,
      'selected_exercise_id': selectedExerciseId,
      'show_stats': showStats,
    };
  }
}

class ExerciseDisplaySetting {
  final String curveType;

  ExerciseDisplaySetting({
    required this.curveType,
  });

  factory ExerciseDisplaySetting.defaultValue() {
    return ExerciseDisplaySetting(curveType: 'poids-maximum');
  }

  factory ExerciseDisplaySetting.fromJson(Map<String, dynamic> json) {
    return ExerciseDisplaySetting(
      curveType: json['curveType'] ?? 'poids-maximum',
    );
  }

  ExerciseDisplaySetting copyWith({
    String? curveType,
  }) {
    return ExerciseDisplaySetting(
      curveType: curveType ?? this.curveType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'curveType': curveType,
    };
  }
}
