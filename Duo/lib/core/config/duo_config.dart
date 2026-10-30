class DuoConfig {
  DuoConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://mxzppesgbfkodgefljcx.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_iu5uKXcaeheoeHBEkqJVbg_rgk_gq2O',
  );
}
