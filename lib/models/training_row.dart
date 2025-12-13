class TrainingRow {
  final String id;
  final String trainingId;
  final String exercise;
  final int series;
  final List<String> repetitions;
  final List<String> weights;
  final List<String> efforts;
  final String rest;
  final String? videoUrl;
  final String? note;
  final String? material;
  final int order;
  final String? supersetId;

  TrainingRow({
    required this.id,
    required this.trainingId,
    required this.exercise,
    required this.series,
    required this.repetitions,
    required this.weights,
    required this.efforts,
    required this.rest,
    this.note,
    this.material,
    this.videoUrl,
    required this.order,
    this.supersetId,
  });

  factory TrainingRow.fromJson(Map<String, dynamic> json) {
    return TrainingRow(
      id: json['id'] as String,
      trainingId: json['training_id'] as String,
      exercise: json['exercice'] as String,
      series: json['series'] as int,
      repetitions: List<String>.from(json['repetitions'] ?? []),
      weights: List<String>.from(json['poids'] ?? []),
      efforts: List<String>.from(json['effort'] ?? []),
      rest: json['repos'] as String,
      note: json['note'] as String?,
      material: json['materiel'] as String?,
      // Some databases use `link` instead of `video_url`. Use whichever is present
      // to ensure the app displays clickable exercise names when a link exists.
      videoUrl: (json['video_url'] ?? json['link']) as String?,
      order: json['order'] as int,
      supersetId: json['superset_id'] as String?,
    );
  }
}
