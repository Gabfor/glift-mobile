class Training {
  final String id;
  final String name;
  final bool app;
  final bool dashboard;
  final int position;
  final String? programId;

  Training({
    required this.id,
    required this.name,
    required this.app,
    required this.dashboard,
    required this.position,
    this.programId,
  });

  factory Training.fromJson(Map<String, dynamic> json) {
    return Training(
      id: json['id'].toString(),
      name: json['name'] as String,
      app: json['app'] as bool? ?? false,
      dashboard: json['dashboard'] as bool? ?? true,
      position: json['position'] as int? ?? 0,
      programId: json['program_id']?.toString(),
    );
  }
}
