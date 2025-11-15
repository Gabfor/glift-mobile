import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';
import 'package:glift_mobile/main.dart';
import 'package:glift_mobile/supabase_credentials.dart';

void main() {
  testWidgets('App loads and shows Supabase connection title', (
    WidgetTester tester,
  ) async {
    final supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);

    await tester.pumpWidget(MyApp(supabase: supabase));

    expect(find.text('Supabase connection'), findsOneWidget);
  });
}
