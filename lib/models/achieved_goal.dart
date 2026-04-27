class AchievedGoal {
  final String exerciseName;
  final double target;
  final String type;

  AchievedGoal({
    required this.exerciseName,
    required this.target,
    required this.type,
  });

  String get metricDisplay {
    String metricName = '';
    if (type == 'poids-maximum') metricName = 'Kg Poids maximum';
    if (type == 'poids-moyen') metricName = 'Kg Poids moyen';
    if (type == 'poids-total') metricName = 'Kg Poids total';
    if (type == 'repetition-maximum') metricName = 'Rép. maximum';
    if (type == 'repetition-moyenne') metricName = 'Rép. moyenne';
    if (type == 'repetitions-totales') metricName = 'Rép. totales';
    
    // Format target to remove decimal if it's an integer
    String formattedTarget = target.toStringAsFixed(target.truncateToDouble() == target ? 0 : 1);
    
    if (type.contains('poids')) {
      return '$formattedTarget $metricName';
    } else {
      return '$formattedTarget $metricName';
    }
  }
}
