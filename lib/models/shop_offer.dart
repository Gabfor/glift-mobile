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
  final String? shop;
  final String? shopWebsite;
  final String? shopLink;
  final String? shipping;
  final String? modal;
  final String? condition;
  final String? gender;
  final String? imageMobile;

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
    this.shop,
    this.shopWebsite,
    this.shopLink,
    this.shipping,
    this.modal,
    this.condition,
    this.gender,
    this.imageMobile,
  });

  factory ShopOffer.fromJson(Map<String, dynamic> json) {
    List<String> parseTypes(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      } else if (value is String) {
        // Try to parse JSON string if it's stored as stringified JSON
        try {
          // Simple check if it looks like a list
          if (value.startsWith('[') && value.endsWith(']')) {
             // In a real app we might use jsonDecode, but here we can just split by comma if simple
             // or just return empty if complex parsing is needed without dart:convert
             // For now let's assume simple comma separated if not json list
             return value.replaceAll('[', '').replaceAll(']', '').split(',').map((e) => e.trim().replaceAll('"', '')).toList();
          }
           return value.split(',').map((e) => e.trim()).toList();
        } catch (_) {
          return [];
        }
      }
      return [];
    }

    return ShopOffer(
      id: json['id'].toString(),
      name: json['name'] as String,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      type: parseTypes(json['type']),
      code: json['code'] as String?,
      image: json['image'] as String? ?? '',
      imageAlt: json['image_alt'] as String? ?? '',
      brandImage: json['brand_image'] as String?,
      brandImageAlt: json['brand_image_alt'] as String?,
      shop: json['shop'] as String?,
      shopWebsite: json['shop_website'] as String?,
      shopLink: json['shop_link'] as String?,
      shipping: json['shipping'] as String?,
      modal: json['modal'] as String?,
      condition: json['condition'] as String?,
      gender: json['gender'] as String?,
      imageMobile: json['image_mobile'] as String?, // New field
    );
  }
}
