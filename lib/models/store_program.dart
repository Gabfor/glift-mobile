class StoreProgram {
  final String id;
  final String title;
  final String level;
  final String sessions;
  final String duration;
  final String description;
  final String image;
  final String imageAlt;
  final String? partnerImage;
  final String? partnerImageAlt;
  final String? partnerLink;
  final String? link;
  final int downloads;
  final DateTime createdAt;
  final String goal;
  final String gender;
  final String? partnerName;
  final String? location;

  StoreProgram({
    required this.id,
    required this.title,
    required this.level,
    required this.sessions,
    required this.duration,
    required this.description,
    required this.image,
    required this.imageAlt,
    this.partnerImage,
    this.partnerImageAlt,
    this.partnerLink,
    this.link,
    required this.downloads,
    required this.createdAt,
    required this.goal,
    required this.gender,
    this.partnerName,
    this.location,
  });

  factory StoreProgram.fromJson(Map<String, dynamic> json) {
    return StoreProgram(
      id: json['id'].toString(),
      title: json['title'] as String,
      level: json['level'] as String? ?? '',
      sessions: json['sessions']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      description: json['description'] as String? ?? '',
      image: json['image'] as String? ?? '',
      imageAlt: json['image_alt'] as String? ?? '',
      partnerImage: json['partner_image'] as String?,
      partnerImageAlt: json['partner_image_alt'] as String?,
      partnerLink: json['partner_link'] as String?,
      link: json['link'] as String?,
      downloads: json['downloads'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      goal: json['goal'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      partnerName: json['partner_name'] as String?,
      location: json['location'] as String?,
    );
  }
}
