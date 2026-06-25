import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ajarin_ya/models/pomodoro_preset.dart';
import 'package:ajarin_ya/models/pomodoro_session.dart';
import 'package:ajarin_ya/models/result_state.dart';

abstract class PomodoroRepository {
  // Presets
  Stream<ResultState<List<PomodoroPreset>>> getPresets(String ownerId);
  Stream<ResultState<void>> createPreset(PomodoroPreset preset);
  Stream<ResultState<void>> updatePreset(PomodoroPreset preset);
  Stream<ResultState<void>> deletePreset(String presetId);

  // Sessions
  Stream<ResultState<List<PomodoroSession>>> getSessions(String ownerId);
  Stream<ResultState<void>> saveSession(PomodoroSession session);
  Stream<ResultState<void>> deleteSession(String sessionId);
}

class PomodoroRepositoryImpl implements PomodoroRepository {
  final FirebaseFirestore? _customDb;

  PomodoroRepositoryImpl({FirebaseFirestore? db}) : _customDb = db;

  FirebaseFirestore? get _db {
    try {
      return _customDb ?? FirebaseFirestore.instance;
    } catch (e) {
      developer.log('Firebase Core belum diinisialisasi.', name: 'POMODORO_DB', error: e);
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? get _col {
    final firestore = _db;
    if (firestore == null) return null;
    return firestore.collection('pomodoro_presets');
  }

  @override
  Stream<ResultState<List<PomodoroPreset>>> getPresets(String ownerId) async* {
    yield const ResultStateLoading();
    try {
      final col = _col;
      if (col == null) throw Exception('Firestore tidak tersedia');
      final snap = await col.where('ownerId', isEqualTo: ownerId).get();
      final presets = snap.docs
          .map((d) => PomodoroPreset.fromJson(d.data(), d.id))
          .toList();
      yield ResultStateSuccess(presets);
    } catch (e) {
      developer.log('ERROR getPresets: $e', name: 'POMODORO_DB');
      yield ResultStateError(e, 'Gagal mengambil preset: $e');
    }
  }

  @override
  Stream<ResultState<void>> createPreset(PomodoroPreset preset) async* {
    yield const ResultStateLoading();
    try {
      final col = _col;
      if (col == null) throw Exception('Firestore tidak tersedia');
      if (preset.id.isEmpty) {
        final ref = await col.add(preset.toJson());
        preset.id = ref.id;
      } else {
        await col.doc(preset.id).set(preset.toJson());
      }
      yield const ResultStateSuccess(null);
    } catch (e) {
      developer.log('ERROR createPreset: $e', name: 'POMODORO_DB');
      yield ResultStateError(e, 'Gagal membuat preset: $e');
    }
  }

  @override
  Stream<ResultState<void>> updatePreset(PomodoroPreset preset) async* {
    yield const ResultStateLoading();
    try {
      if (preset.id.isEmpty) throw ArgumentError('preset.id tidak boleh kosong');
      final col = _col;
      if (col == null) throw Exception('Firestore tidak tersedia');
      await col.doc(preset.id).set(preset.toJson());
      yield const ResultStateSuccess(null);
    } catch (e) {
      developer.log('ERROR updatePreset: $e', name: 'POMODORO_DB');
      yield ResultStateError(e, 'Gagal memperbarui preset: $e');
    }
  }

  @override
  Stream<ResultState<void>> deletePreset(String presetId) async* {
    yield const ResultStateLoading();
    try {
      if (presetId.isEmpty) throw ArgumentError('presetId tidak boleh kosong');
      final col = _col;
      if (col == null) throw Exception('Firestore tidak tersedia');
      await col.doc(presetId).delete();
      yield const ResultStateSuccess(null);
    } catch (e) {
      developer.log('ERROR deletePreset: $e', name: 'POMODORO_DB');
      yield ResultStateError(e, 'Gagal menghapus preset: $e');
    }
  }

  CollectionReference<Map<String, dynamic>>? get _sessionsCol {
    final firestore = _db;
    if (firestore == null) return null;
    return firestore.collection('pomodoro_sessions');
  }

  @override
  Stream<ResultState<List<PomodoroSession>>> getSessions(String ownerId) async* {
    yield const ResultStateLoading();
    try {
      final col = _sessionsCol;
      if (col == null) throw Exception('Firestore tidak tersedia');
      final snap = await col
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('completedAt', descending: true)
          .limit(50)
          .get();
      final sessions = snap.docs
          .map((d) => PomodoroSession.fromJson(d.data(), d.id))
          .toList();
      yield ResultStateSuccess(sessions);
    } catch (e) {
      developer.log('ERROR getSessions: $e', name: 'POMODORO_DB');
      yield ResultStateError(e, 'Gagal mengambil riwayat sesi: $e');
    }
  }

  @override
  Stream<ResultState<void>> saveSession(PomodoroSession session) async* {
    yield const ResultStateLoading();
    try {
      final col = _sessionsCol;
      if (col == null) throw Exception('Firestore tidak tersedia');
      final ref = await col.add(session.toJson());
      session.id = ref.id;
      yield const ResultStateSuccess(null);
    } catch (e) {
      developer.log('ERROR saveSession: $e', name: 'POMODORO_DB');
      yield ResultStateError(e, 'Gagal menyimpan sesi: $e');
    }
  }

  @override
  Stream<ResultState<void>> deleteSession(String sessionId) async* {
    yield const ResultStateLoading();
    try {
      if (sessionId.isEmpty) throw ArgumentError('sessionId tidak boleh kosong');
      final col = _sessionsCol;
      if (col == null) throw Exception('Firestore tidak tersedia');
      await col.doc(sessionId).delete();
      yield const ResultStateSuccess(null);
    } catch (e) {
      developer.log('ERROR deleteSession: $e', name: 'POMODORO_DB');
      yield ResultStateError(e, 'Gagal menghapus sesi: $e');
    }
  }
}
