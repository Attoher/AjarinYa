import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:ajarin_ya/models/study_spot.dart';
import 'package:ajarin_ya/models/result_state.dart';
import 'package:ajarin_ya/repositories/study_spot_repository.dart';

/// ViewModel untuk mengelola state UI pada Fitur Study Spot (Maps & Lokasi) di Flutter.
/// Didesain toleran terhadap koneksi internet mati (Offline) dan koordinat null.
class StudySpotViewModel extends ChangeNotifier {
  final StudySpotRepository _repository;

  StudySpotViewModel({StudySpotRepository? repository})
      : _repository = repository ?? StudySpotRepositoryImpl();

  // State untuk menampung List lokasi belajar (Study Spot) yang terdaftar
  ResultState<List<StudySpot>> _studySpotsState = const ResultStateIdle();
  ResultState<List<StudySpot>> get studySpotsState => _studySpotsState;

  // State untuk memantau status eksekusi aksi CRUD lokasi (Create/Update/Delete)
  ResultState<void> _crudActionState = const ResultStateIdle();
  ResultState<void> get crudActionState => _crudActionState;

  /// Memuat seluruh daftar Study Spot dari database (lokal cache jika offline).
  Future<void> fetchStudySpots(String groupId) async {
    try {
      _repository.getStudySpots(groupId).listen((result) {
        _studySpotsState = result;
        notifyListeners();
      });
    } catch (e, stackTrace) {
      debugPrint('========== CRITICAL_INTEGRITY_ALERT: $e ==========');
      developer.log(
        'ERROR saat fetchStudySpots: $e',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      _studySpotsState = ResultStateError(e, 'Gagal mengambil daftar lokasi belajar.');
      notifyListeners();
    }
  }

  /// Menambahkan Study Spot baru. Melakukan validasi dasar di layer VM.
  Future<void> createStudySpot(StudySpot spot) async {
    try {
      if (spot.name.trim().isEmpty) {
        _crudActionState = ResultStateError(
          ArgumentError('Nama lokasi belajar kosong'),
          'Nama lokasi belajar tidak boleh kosong!',
        );
        notifyListeners();
        return;
      }

      await for (final result in _repository.createStudySpot(spot)) {
        _crudActionState = result;
        notifyListeners();
        if (result is ResultStateError) break;
      }
    } catch (e, stackTrace) {
      debugPrint('========== CRITICAL_INTEGRITY_ALERT: $e ==========');
      developer.log(
        'ERROR saat createStudySpot: $e',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      _crudActionState = ResultStateError(e, 'Gagal membuat Study Spot.');
      notifyListeners();
    }
  }

  /// Memperbarui detail Study Spot.
  Future<void> updateStudySpot(StudySpot spot) async {
    try {
      if (spot.spotId.isEmpty) {
        _crudActionState = ResultStateError(
          ArgumentError('ID lokasi belajar kosong'),
          'ID tempat belajar tidak terdeteksi!',
        );
        notifyListeners();
        return;
      }

      await for (final result in _repository.updateStudySpot(spot)) {
        _crudActionState = result;
        notifyListeners();
        if (result is ResultStateError) break;
      }
    } catch (e, stackTrace) {
      debugPrint('========== CRITICAL_INTEGRITY_ALERT: $e ==========');
      developer.log(
        'ERROR saat updateStudySpot: $e',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      _crudActionState = ResultStateError(e, 'Gagal memperbarui Study Spot.');
      notifyListeners();
    }
  }

  /// Menghapus lokasi Study Spot dari Firestore.
  Future<void> deleteStudySpot(String spotId) async {
    try {
      await for (final result in _repository.deleteStudySpot(spotId)) {
        _crudActionState = result;
        notifyListeners();
        if (result is ResultStateError) break;
      }
    } catch (e, stackTrace) {
      debugPrint('========== CRITICAL_INTEGRITY_ALERT: $e ==========');
      developer.log(
        'ERROR saat deleteStudySpot: $e',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      _crudActionState = ResultStateError(e, 'Gagal menghapus Study Spot.');
      notifyListeners();
    }
  }

  /// Reset status CRUD agar UI tidak mengulang pop-up sukses/gagal.
  void resetCrudActionState() {
    _crudActionState = const ResultStateIdle();
    notifyListeners();
  }
}
