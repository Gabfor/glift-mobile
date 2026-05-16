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
      Map<String, dynamic> exercisesMap = {};
      
      // Structure: { "selectedExerciseId": "...", "exercises": { "id": { ... } } }
      if (rawSettings.containsKey('exercises') && rawSettings['exercises'] is Map) {
        exercisesMap = Map<String, dynamic>.from(rawSettings['exercises']);
      } else if (rawSettings.containsKey('selectedExerciseId') && rawSettings['exercises'] == null) {
          // If it has selectedExerciseId but NO exercises key, it might be a malformed structured format
          // but usually it's either structured or flat.
          exercisesMap = {};
      } else {
         // Fallback/Legacy structure or direct map
         exercisesMap = Map<String, dynamic>.from(rawSettings);
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

    // Align with web app structured format
    return {
      'exercise_settings': {
        'selectedExerciseId': selectedExerciseId,
        'exercises': settingsMap,
      },
      'selected_program_id': selectedProgramId,
      'selected_training_id': selectedTrainingId,
      'selected_exercise_id': selectedExerciseId,
      'show_stats': showStats,
    };
  }
}

class ExerciseDisplaySetting {
  final String curveType;
  final String sessionCount;
  final String recordCurveType;
  final Map<String, dynamic>? goal;

  ExerciseDisplaySetting({
    required this.curveType,
    required this.sessionCount,
    required this.recordCurveType,
    this.goal,
  });

  factory ExerciseDisplaySetting.defaultValue() {
    return ExerciseDisplaySetting(
      curveType: 'poids-maximum',
      sessionCount: '15',
      recordCurveType: 'poids-maximum',
    );
  }

  factory ExerciseDisplaySetting.fromJson(Map<String, dynamic> json) {
    final curve = json['curveType'] ?? 'poids-maximum';
    return ExerciseDisplaySetting(
      curveType: curve,
      sessionCount: json['sessionCount'] ?? '15',
      recordCurveType: json['recordCurveType'] ?? curve,
      goal: json['goal'],
    );
  }

  ExerciseDisplaySetting copyWith({
    String? curveType,
    String? sessionCount,
    String? recordCurveType,
    Map<String, dynamic>? goal,
  }) {
    return ExerciseDisplaySetting(
      curveType: curveType ?? this.curveType,
      sessionCount: sessionCount ?? this.sessionCount,
      recordCurveType: recordCurveType ?? this.recordCurveType,
      goal: goal ?? this.goal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'curveType': curveType,
      'sessionCount': sessionCount,
      'recordCurveType': recordCurveType,
      'goal': goal,
    };
  }
}
