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

    print('Fetching programs for user...');
    final response = await client
        .from('programs')
        .select('id, name, position, trainings(id, name, app, dashboard)')
        .eq('user_id', userId);

    final data = response as List<dynamic>;
    print('Found ${data.length} programs:');
    
    for (var p in data) {
      print('- Program: ${p['name']} (ID: ${p['id']})');
      final trainings = p['trainings'] as List<dynamic>;
      print('  - Trainings: ${trainings.length}');
      for (var t in trainings) {
        print('    - ${t['name']} (App: ${t['app']}, Dashboard: ${t['dashboard']})');
      }
    }

  } catch (e) {
    print('Error: $e');
  }
}
