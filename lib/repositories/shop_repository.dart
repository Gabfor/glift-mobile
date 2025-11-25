import 'package:supabase/supabase.dart';
import '../models/shop_offer.dart';

class ShopRepository {
  final SupabaseClient _supabase;

  ShopRepository(this._supabase);

  Future<List<ShopOffer>> getShopOffers({
    String sortBy = 'newest',
    List<String>? filters,
  }) async {
    try {
      dynamic query = _supabase
          .from('offer_shop')
          .select()
          .eq('status', 'ON');

      // Sorting
      if (sortBy == 'popularity') {
        query = query.order('downloads', ascending: false); // Assuming downloads exists or similar metric
      } else if (sortBy == 'oldest') {
        query = query.order('created_at', ascending: true);
      } else if (sortBy == 'expiration') {
        // For expiration, we might need to sort in memory or use a specific column if available
        // Here we just fetch and will sort in memory if needed, or assume end_date sorting
        query = query.order('end_date', ascending: true);
      } else {
        // newest
        query = query.order('created_at', ascending: false);
      }

      // TODO: Implement filters if needed
      
      final response = await query;
      final List<dynamic> data = response as List<dynamic>;
      
      return data.map((json) => ShopOffer.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement du shop: $e');
    }
  }
}
