/// Isi dengan credential Supabase kamu.
/// Ambil dari: Supabase Dashboard → Project Settings → API
class SupabaseConfig {
  /// Project URL — contoh: https://abcdefghijkl.supabase.co
  static const String projectUrl = 'https://ptsrtgujhdobqlabggob.supabase.co';

  /// Publishable (anon) key — string JWT panjang dari bagian "Project API keys"
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB0c3J0Z3VqaGRvYnFsYWJnZ29iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEwNzEwNjAsImV4cCI6MjA5NjY0NzA2MH0.seqBk4Jat0raSPe05gS03pnKv_3YiZzQizCg-E1Kdv4';

  // --- Nama bucket Storage (case-sensitive, sesuai nama di Supabase Dashboard) ---
  static const String bucketAvatars   = 'Avatars';
  static const String bucketQuestions = 'Questions';
  static const String bucketReplies   = 'Replies';
  static const String bucketNotes     = 'Notes';
  static const String bucketSpots     = 'Spots';
  static const String bucketChats     = 'Chats';
}
