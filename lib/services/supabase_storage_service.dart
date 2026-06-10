import 'dart:developer' as developer;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ajarin_ya/config/supabase_config.dart';

/// Service terpusat untuk upload & hapus file ke Supabase Storage.
/// DB tetap Firebase Firestore; Supabase hanya dipakai sebagai CDN gambar.
class SupabaseStorageService {
  static SupabaseStorageService? _instance;
  SupabaseStorageService._();
  static SupabaseStorageService get instance =>
      _instance ??= SupabaseStorageService._();

  SupabaseClient get _client => Supabase.instance.client;

  // ─────────────────────────────────────────────────────────────────────────
  // Upload helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Upload foto profil. Mengembalikan public URL atau null jika gagal.
  Future<String?> uploadAvatar(String userId, XFile file) =>
      _upload(SupabaseConfig.bucketAvatars, 'user_$userId', file);

  /// Upload gambar soal. Mengembalikan public URL atau null jika gagal.
  Future<String?> uploadQuestionImage(String questionId, XFile file) =>
      _upload(SupabaseConfig.bucketQuestions, 'q_$questionId', file);

  /// Upload gambar jawaban. Mengembalikan public URL atau null jika gagal.
  Future<String?> uploadReplyImage(String replyId, XFile file) =>
      _upload(SupabaseConfig.bucketReplies, 'r_$replyId', file);

  /// Upload gambar catatan. Mengembalikan public URL atau null jika gagal.
  Future<String?> uploadNoteImage(String noteId, XFile file) =>
      _upload(SupabaseConfig.bucketNotes, 'n_$noteId', file);

  /// Upload foto study spot. Mengembalikan public URL atau null jika gagal.
  Future<String?> uploadSpotImage(String spotId, XFile file) =>
      _upload(SupabaseConfig.bucketSpots, 'spot_$spotId', file);

  /// Upload gambar chat barter. Mengembalikan public URL atau null jika gagal.
  Future<String?> uploadChatImage(String chatId, XFile file) =>
      _upload(SupabaseConfig.bucketChats, 'chat_$chatId', file);

  // ─────────────────────────────────────────────────────────────────────────
  // Core upload
  // ─────────────────────────────────────────────────────────────────────────

  /// Upload file, returns public URL on success or throws [StorageException]
  /// so callers can surface the reason to the user.
  Future<String> uploadOrThrow(
      String bucket, String filePrefix, XFile file) async {
    final bytes = await file.readAsBytes();
    final ext = _extension(file.name);
    final path = '${filePrefix}_${DateTime.now().millisecondsSinceEpoch}$ext';

    await _client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: file.mimeType ?? 'image/jpeg',
          ),
        );

    return _client.storage.from(bucket).getPublicUrl(path);
  }

  Future<String?> _upload(
      String bucket, String filePrefix, XFile file) async {
    try {
      return await uploadOrThrow(bucket, filePrefix, file);
    } catch (e, st) {
      developer.log(
        'SupabaseStorage upload error | bucket=$bucket prefix=$filePrefix | $e',
        name: 'SupabaseStorage',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Delete helper (opsional — untuk update avatar / replace gambar lama)
  // ─────────────────────────────────────────────────────────────────────────

  /// Hapus file dari Supabase Storage.
  /// [publicUrl] adalah URL publik lengkap yang dikembalikan saat upload.
  Future<void> deleteByUrl(String bucket, String publicUrl) async {
    try {
      // Ekstrak path setelah "/object/public/<bucket>/"
      final marker = '/object/public/$bucket/';
      final idx = publicUrl.indexOf(marker);
      if (idx == -1) return;
      final path = publicUrl.substring(idx + marker.length);
      await _client.storage.from(bucket).remove([path]);
    } catch (e) {
      developer.log(
        'SupabaseStorage delete error | $e',
        name: 'SupabaseStorage',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Util
  // ─────────────────────────────────────────────────────────────────────────

  String _extension(String filename) {
    final dot = filename.lastIndexOf('.');
    return dot != -1 ? filename.substring(dot).toLowerCase() : '.jpg';
  }
}
