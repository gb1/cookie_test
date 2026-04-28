/// Supabase project credentials. The anon/publishable key is safe to ship
/// in client code — Row Level Security in the database is what actually
/// guards the data.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://evenjheqkwqyowbmluwu.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_MtPSFuNakEx16GWDyozGWw_xHX2emQB',
  );
}
