class ShopOffer {
  final String id;
  final String name;
  final String? startDate;
  final String? endDate;
  final List<String> type;
  final String? code;
  final String image;
  final String imageAlt;
  final String? brandImage;
  final String? brandImageAlt;
  final List<String> shops;
  final String? shopWebsite;
  final String? shopLink;
  final String? shipping;
  final String? modal;
  final String? condition;
  final List<String> genders;
  final String? imageMobile;
  final bool boost;
  final int clickCount;
  final List<String> sports;
  final String? createdAt;

  ShopOffer({
    required this.id,
    required this.name,
    this.startDate,
    this.endDate,
    required this.type,
    this.code,
    required this.image,
    required this.imageAlt,
    this.brandImage,
    this.brandImageAlt,
    required this.shops,
    this.shopWebsite,
    this.shopLink,
    this.shipping,
    this.modal,
    this.condition,
    required this.genders,
    this.imageMobile,
    this.boost = false,
    this.clickCount = 0,
    this.createdAt,
    required this.sports,
  });

  factory ShopOffer.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic value) {
      if (value == null) return <String>[];
      
      if (value is List) {
        return value
            .map((e) => e?.toString().trim() ?? "")
            .where((e) => e.isNotEmpty)
            .cast<String>()
            .toList();
      }
      
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) return <String>[];
        
        // Handle JSON array string
        if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
          try {
            return trimmed
                .replaceAll('[', '')
                .replaceAll(']', '')
                .split(',')
                .map((e) => e.trim().replaceAll('"', '').replaceAll("'", ""))
                .where((e) => e.isNotEmpty)
                .cast<String>()
                .toList();
          } catch (_) {
            return <String>[];
          }
        }
        
        // Handle comma-separated string
        return trimmed
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .cast<String>()
            .toList();
      }
      
      return <String>[];
    }

    return ShopOffer(
      id: json['id']?.toString() ?? "",
      name: json['name'] as String? ?? "Sans nom",
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      type: parseList(json['type']),
      code: json['code'] as String?,
      image: (json['image'] as String? ?? '').trim(),
      imageAlt: (json['image_alt'] as String? ?? '').trim(),
      brandImage: (json['brand_image'] as String?)?.trim(),
      brandImageAlt: (json['brand_image_alt'] as String?)?.trim(),
      shops: parseList(json['shop']),
      shopWebsite: json['shop_website'] as String?,
      shopLink: json['shop_link'] as String?,
      shipping: json['shipping'] as String?,
      modal: json['modal'] as String?,
      condition: json['condition'] as String?,
      genders: parseList(json['gender']),
      imageMobile: (json['image_mobile'] as String?)?.trim(),
      boost: json['boost'] is bool ? json['boost'] as bool : (json['boost']?.toString().toLowerCase() == 'true'),
      clickCount: json['click_count'] as int? ?? 0,
      createdAt: json['created_at'] as String?,
      sports: parseList(json['sport']),
    );
  }

  // Compatibility getters
  String? get shop => shops.isNotEmpty ? shops[0] : null;
  String? get gender => genders.isNotEmpty ? genders[0] : null;
  String? get sport => sports.isNotEmpty ? sports[0] : null;
}
