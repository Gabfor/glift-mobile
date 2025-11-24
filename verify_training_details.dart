import 'package:supabase/supabase.dart';
import 'lib/supabase_credentials.dart';

Future<void> main() async {
  print('Connecting to Supabase...');
  final client = SupabaseClient(supabaseUrl, supabaseAnonKey);

  try {
    print('Logging in as fort.gaby@gmail.com...');
    final authResponse = await client.auth.signInWithPassword(
      email: 'fort.gaby@gmail.com',
      password: '29381678Glift!',
    );

    final userId = authResponse.user?.id;
    if (userId == null) {
      print('Login failed: No user ID returned.');
      return;
    }
    print('Login successful! User ID: $userId');

    // First, find the "Pectoraux" training ID
    print('Finding "Pectoraux" training ID...');
    final trainingResponse = await client
        .from('trainings')
        .select('id, name')
        .eq('user_id', userId)
        .eq('name', 'Pectoraux')
        .single();
    
    final trainingId = trainingResponse['id'] as String;
    print('Found training "Pectoraux" with ID: $trainingId');

    // Now fetch details from training_rows_admin
    print('Fetching details from training_rows_admin...');
    final detailsResponse = await client
        .from('training_rows_admin')
        .select()
        .eq('training_id', trainingId);

    final data = detailsResponse as List<dynamic>;
    print('Found ${data.length} rows for this training.');
    
    if (data.isNotEmpty) {
      print('First row data:');
      print(data.first);
    } else {
      print('Checking training_rows table directly...');
       final rawRowsResponse = await client
        .from('training_rows')
        .select()
        .eq('training_id', trainingId);
       final rawData = rawRowsResponse as List<dynamic>;
       print('Found ${rawData.length} rows in raw table.');
       if (rawData.isNotEmpty) {
         print('First raw row data:');
         print(rawData.first);
       }
    }

  } catch (e) {
    print('Error: $e');
  }
}
