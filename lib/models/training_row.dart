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
  final bool locked;
  final bool isHidden;

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
    required this.locked,
    this.isHidden = false,
  });

  factory TrainingRow.fromJson(Map<String, dynamic> json) {
    List<String> toDisplayStrings(String fieldName) {
      final raw = json[fieldName] as List<dynamic>? ?? [];
      return raw
          .map((value) {
            if (value == null) return '-';
            final stringValue = value.toString();
            return stringValue.isEmpty ? '-' : stringValue;
          })
          .toList();
    }

    return TrainingRow(
      id: json['id'] as String,
      trainingId: json['training_id'] as String,
      exercise: json['exercice'] as String? ?? '',
      series: json['series'] as int,
      repetitions: toDisplayStrings('repetitions'),
      weights: toDisplayStrings('poids'),
      efforts: toDisplayStrings('effort'),
      rest: json['repos'] as String,
      note: json['note'] as String?,
      material: json['materiel'] as String?,
      // Some databases use `link` instead of `video_url`. Use whichever is present
      // to ensure the app displays clickable exercise names when a link exists.
      videoUrl: (json['video_url'] ?? json['link']) as String?,
      order: json['order'] as int,
      supersetId: json['superset_id'] as String?,
      locked: json['locked'] as bool? ?? false,
      isHidden: json['is_hidden'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'training_id': trainingId,
      'exercice': exercise,
      'series': series,
      'repetitions': repetitions,
      'poids': weights,
      'effort': efforts,
      'repos': rest,
      'video_url': videoUrl,
      'order': order,
      'superset_id': supersetId,
      'locked': locked,
      'note': note,
      'materiel': material,
      'is_hidden': isHidden,
    };
  }

  TrainingRow copyWith({
    String? id,
    String? trainingId,
    String? exercise,
    int? series,
    List<String>? repetitions,
    List<String>? weights,
    List<String>? efforts,
    String? rest,
    String? note,
    String? material,
    String? videoUrl,
    int? order,
    String? supersetId,
    bool? locked,
    bool? isHidden,
  }) {
    return TrainingRow(
      id: id ?? this.id,
      trainingId: trainingId ?? this.trainingId,
      exercise: exercise ?? this.exercise,
      series: series ?? this.series,
      repetitions: repetitions ?? this.repetitions,
      weights: weights ?? this.weights,
      efforts: efforts ?? this.efforts,
      rest: rest ?? this.rest,
      note: note ?? this.note,
      material: material ?? this.material,
      videoUrl: videoUrl ?? this.videoUrl,
      order: order ?? this.order,
      supersetId: supersetId ?? this.supersetId,
      locked: locked ?? this.locked,
      isHidden: isHidden ?? this.isHidden,
    );
  }
}
