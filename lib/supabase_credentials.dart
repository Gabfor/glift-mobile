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
  defaultValue: 'https://YOUR-PROJECT-NAME.supabase.co',
);

const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'YOUR-SUPABASE-ANON-KEY',
);

/// Whether real credentials have been configured.
bool get hasSupabaseCredentials =>
    !supabaseUrl.contains('YOUR-PROJECT-NAME') &&
    !supabaseAnonKey.contains('YOUR-SUPABASE-ANON-KEY');
