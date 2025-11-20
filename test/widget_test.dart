import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';
import 'package:glift_mobile/main.dart';
import 'package:glift_mobile/supabase_credentials.dart';
import 'package:glift_mobile/auth/auth_repository.dart';

void main() {
  testWidgets('App transitions from splash to onboarding', (
    WidgetTester tester,
  ) async {
    final supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);
    final authRepository = SupabaseAuthRepository(supabase);

    await tester.pumpWidget(
      GliftApp(
        supabase: supabase,
        authRepository: authRepository,
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));

    expect(find.byType(OnboardingFlow), findsOneWidget);
  });
}
