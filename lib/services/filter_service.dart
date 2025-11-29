class FilterService {
  static final FilterService _instance = FilterService._internal();

  factory FilterService() {
    return _instance;
  }

  FilterService._internal();

  // Shop state
  Map<String, Set<String>> shopFilters = {};
  String shopSort = 'newest';

  // Store state
  Map<String, Set<String>> storeFilters = {};
  String storeSort = 'newest';

  void reset() {
    shopFilters = {};
    shopSort = 'newest';
    storeFilters = {};
    storeSort = 'newest';
  }
}
