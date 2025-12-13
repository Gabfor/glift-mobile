class Training {
  final String id;
  final String name;
  final bool app;
  final bool dashboard;
  final int position;
  final String? programId;
  final DateTime? lastSessionDate;
  final int? averageDurationMinutes;

  Training({
    required this.id,
    required this.name,
    required this.app,
    required this.dashboard,
    required this.position,
    this.programId,
    this.lastSessionDate,
    this.averageDurationMinutes,
  });

  factory Training.fromJson(Map<String, dynamic> json) {
    return Training(
      id: json['id'].toString(),
      name: json['name'] as String,
      app: json['app'] as bool? ?? false,
      dashboard: json['dashboard'] as bool? ?? true,
      position: json['position'] as int? ?? 0,
      programId: json['program_id']?.toString(),
      lastSessionDate: json['lastSessionDate'] != null 
          ? DateTime.tryParse(json['lastSessionDate']) 
          : null,
      averageDurationMinutes: json['averageDurationMinutes'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'app': app,
    'dashboard': dashboard,
    'position': position,
    'program_id': programId,
    'lastSessionDate': lastSessionDate?.toIso8601String(),
    'averageDurationMinutes': averageDurationMinutes,
  };
}
