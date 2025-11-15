/// Supabase credentials used to initialize the [Supabase] client.
///
/// Replace the placeholder values with the URL and anonymous key from your
/// Supabase project or inject them with `--dart-define` at build time:
///
/// ```bash
/// flutter run --dart-define=SUPABASE_URL=https://xyzcompany.supabase.co \
///            --dart-define=SUPABASE_ANON_KEY=public-anon-key
/// ```
const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://wzdkuqxjcqrwrouobpxo.supabase.co',
);

const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind6ZGt1cXhqY3Fyd3JvdW9icHhvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDYyODY4MzQsImV4cCI6MjA2MTg2MjgzNH0.kDZU5XO-WICwQuLfmY9UsYp2aYmfikNLam-5_j5RIJw',
);

/// Whether real credentials have been configured.
bool get hasSupabaseCredentials =>
    !supabaseUrl.contains('YOUR-PROJECT-NAME') &&
    !supabaseAnonKey.contains('YOUR-SUPABASE-ANON-KEY');
