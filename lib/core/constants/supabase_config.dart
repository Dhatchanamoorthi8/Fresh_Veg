class SupabaseConfig {
  /// Supabase Project URL, configurable via `--dart-define=SUPABASE_URL=...`
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://gmiysmfyxqkpdsyvvjbx.supabase.co',
  );

  /// Supabase Publishable / Anon Key, configurable via `--dart-define=SUPABASE_ANON_KEY=...`
  /// NOTE: Only publishable client keys are used here. Never include service_role secrets.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_93clz0SE6QTs7yOygrnCYw_HZykANR5',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
