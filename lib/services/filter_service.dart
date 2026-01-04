class FilterService {
  static final FilterService _instance = FilterService._internal();

  factory FilterService() {
    return _instance;
  }

  FilterService._internal();

  // Shop state
  Map<String, Set<String>> shopFilters = {};
  String shopSort = 'relevance';

  // Store state
  Map<String, Set<String>> storeFilters = {};
  String storeSort = 'relevance';

  void reset() {
    shopFilters = {};
    shopSort = 'relevance';
    storeFilters = {};
    storeSort = 'relevance';
  }
}
