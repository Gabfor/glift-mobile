import 'training.dart';

class Program {
  final String id;
  final String name;
  final List<Training> trainings;
  final int position;

  Program({
    required this.id,
    required this.name,
    required this.trainings,
    required this.position,
  });

  factory Program.fromJson(Map<String, dynamic> json) {
    var trainingsList = <Training>[];
    if (json['trainings'] != null) {
      trainingsList = (json['trainings'] as List)
          .map((t) => Training.fromJson(t as Map<String, dynamic>))
          .toList();
      
      // Sort trainings by position
      trainingsList.sort((a, b) => a.position.compareTo(b.position));
    }

    return Program(
      id: json['id'].toString(),
      name: json['name'] as String,
      trainings: trainingsList,
      position: json['position'] as int? ?? 0,
    );
  }
}
