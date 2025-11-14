import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_credentials.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glift + Supabase',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase connection'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _ConnectionDetailsCard(supabase: supabase),
          const SizedBox(height: 24),
          _CredentialsStatusBanner(),
          const SizedBox(height: 24),
          _UsageExamples(theme: theme),
        ],
      ),
    );
  }
}

class _ConnectionDetailsCard extends StatelessWidget {
  const _ConnectionDetailsCard({required this.supabase});

  final SupabaseClient supabase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Connected project', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SelectableText(
              supabase.supabaseUrl,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text('Anon key in use', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SelectableText(
              supabaseAnonKey,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _CredentialsStatusBanner extends StatelessWidget {
  const _CredentialsStatusBanner();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isConfigured = hasSupabaseCredentials;

    return Container(
      decoration: BoxDecoration(
        color: isConfigured
            ? colorScheme.primaryContainer
            : colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isConfigured ? Icons.check_circle : Icons.error_outline,
            color: isConfigured
                ? colorScheme.onPrimaryContainer
                : colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isConfigured
                  ? 'Your Supabase credentials are configured. You can now query '
                      'your tables, invoke Functions, and listen to real-time '
                      'channels.'
                  : 'Update lib/supabase_credentials.dart or provide '
                      '`--dart-define` values for SUPABASE_URL and '
                      'SUPABASE_ANON_KEY to connect to your own project.',
              style: TextStyle(
                color: isConfigured
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageExamples extends StatelessWidget {
  const _UsageExamples({required this.theme});

  final ThemeData theme;

  static const _codeSample = '''
final supabase = Supabase.instance.client;
final profiles = await supabase.from('profiles').select();
''';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Using the client in widgets', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Access the Supabase client anywhere in the widget tree with '
          '`Supabase.instance.client`. From there you can query PostgREST, '
          'invoke Functions, or listen for Auth changes.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: const SelectableText(_codeSample),
        ),
      ],
    );
  }
}
