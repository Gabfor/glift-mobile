class Training {
  final String id;
  final String name;
  final bool app;
  final bool dashboard;
  final int position;
  final bool locked; // New field
  final String? programId;
  final DateTime? lastSessionDate;
  final int? averageDurationMinutes;
  final int? sessionCount;

  Training({
    required this.id,
    required this.name,
    required this.app,
    required this.dashboard,
    required this.position,
    required this.locked,
    this.programId,
    this.lastSessionDate,
    this.averageDurationMinutes,
    this.sessionCount,
  });

  factory Training.fromJson(Map<String, dynamic> json) {
    return Training(
      id: json['id'].toString(),
      name: json['name'] as String,
      app: json['app'] as bool? ?? false,
      dashboard: json['dashboard'] as bool? ?? true,
      position: json['position'] as int? ?? 0,
      locked: json['locked'] as bool? ?? false, // Defaults to false
      programId: json['program_id']?.toString(),
      lastSessionDate: json['lastSessionDate'] != null 
          ? DateTime.tryParse(json['lastSessionDate']) 
          : null,
      averageDurationMinutes: json['averageDurationMinutes'],
      sessionCount: json['sessionCount'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'app': app,
    'dashboard': dashboard,
    'position': position,
    'locked': locked,
    'program_id': programId,
    'lastSessionDate': lastSessionDate?.toIso8601String(),
    'averageDurationMinutes': averageDurationMinutes,
    'sessionCount': sessionCount,
  };

  Training copyWith({
    String? id,
    String? name,
    bool? app,
    bool? dashboard,
    int? position,
    bool? locked,
    String? programId,
    DateTime? lastSessionDate,
    int? averageDurationMinutes,
    int? sessionCount,
  }) {
    return Training(
      id: id ?? this.id,
      name: name ?? this.name,
      app: app ?? this.app,
      dashboard: dashboard ?? this.dashboard,
      position: position ?? this.position,
      locked: locked ?? this.locked,
      programId: programId ?? this.programId,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
      averageDurationMinutes:
          averageDurationMinutes ?? this.averageDurationMinutes,
      sessionCount: sessionCount ?? this.sessionCount,
    );
  }
}
