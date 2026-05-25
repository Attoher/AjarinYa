import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:ajarin_ya/models/barter_request.dart';
import 'package:ajarin_ya/models/result_state.dart';
import 'package:ajarin_ya/repositories/barter_repository.dart';

/// ViewModel untuk mengelola state UI pada Fitur Barter Skill di Flutter.
/// Menggunakan native ChangeNotifier (sangat aman & crash-proof untuk simulasi).
class BarterViewModel extends ChangeNotifier {
  final BarterRepository _repository;

  BarterViewModel({BarterRepository? repository})
      : _repository = repository ?? BarterRepositoryImpl();

  // State untuk menyimpan List request barter skill yang aktif
  ResultState<List<BarterRequest>> _barterRequestsState = const ResultStateIdle();
  ResultState<List<BarterRequest>> get barterRequestsState => _barterRequestsState;

  // State untuk menyimpan List request barter skill yang sudah MATCHED (riwayat)
  ResultState<List<BarterRequest>> _matchedRequestsState = const ResultStateIdle();
  ResultState<List<BarterRequest>> get matchedRequestsState => _matchedRequestsState;

  // State untuk memantau status eksekusi aksi CRUD (Create/Update/Delete/Apply Barter)
  ResultState<void> _crudActionState = const ResultStateIdle();
  ResultState<void> get crudActionState => _crudActionState;

  /// Memuat list request barter yang dibuat oleh user lain.
  Future<void> fetchBarterRequests(String currentUserId) async {
    try {
      _repository.getBarterRequests(currentUserId).listen((result) {
        _barterRequestsState = result;
        notifyListeners();
      });
      fetchMatchedBarterRequests(currentUserId);
    } catch (e, stackTrace) {
      debugPrint('========== CRITICAL_INTEGRITY_ALERT: $e ==========');
      developer.log(
        'ERROR saat fetchBarterRequests: $e',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      _barterRequestsState = ResultStateError(e, 'Terjadi kesalahan sistem.');
      notifyListeners();
    }
  }

  /// Memuat list request barter yang sudah matched (riwayat).
  Future<void> fetchMatchedBarterRequests(String currentUserId) async {
    try {
      _repository.getMatchedBarters(currentUserId).listen((result) {
        _matchedRequestsState = result;
        notifyListeners();
      });
    } catch (e, stackTrace) {
      debugPrint('========== CRITICAL_INTEGRITY_ALERT: $e ==========');
      developer.log(
        'ERROR saat fetchMatchedBarterRequests: $e',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      _matchedRequestsState = ResultStateError(e, 'Terjadi kesalahan sistem.');
      notifyListeners();
    }
  }

  /// Membuat request barter skill baru.
  Future<void> createBarterRequest(BarterRequest request) async {
    try {
      _repository.createBarterRequest(request).listen((result) {
        _crudActionState = result;
        notifyListeners();
      });
    } catch (e, stackTrace) {
      debugPrint('========== CRITICAL_INTEGRITY_ALERT: $e ==========');
      developer.log(
        'ERROR saat createBarterRequest: $e',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      _crudActionState = ResultStateError(e, 'Gagal membuat request barter.');
      notifyListeners();
    }
  }

  /// Memperbarui request barter skill.
  Future<void> updateBarterRequest(BarterRequest request) async {
    try {
      _repository.updateBarterRequest(request).listen((result) {
        _crudActionState = result;
        notifyListeners();
      });
    } catch (e, stackTrace) {
      debugPrint('========== CRITICAL_INTEGRITY_ALERT: $e ==========');
      developer.log(
        'ERROR saat updateBarterRequest: $e',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      _crudActionState = ResultStateError(e, 'Gagal mengupdate request barter.');
      notifyListeners();
    }
  }

  /// Menghapus request barter skill berdasarkan ID.
  Future<void> deleteBarterRequest(String requestId) async {
    try {
      _repository.deleteBarterRequest(requestId).listen((result) {
        _crudActionState = result;
        notifyListeners();
      });
    } catch (e, stackTrace) {
      debugPrint('========== CRITICAL_INTEGRITY_ALERT: $e ==========');
      developer.log(
        'ERROR saat deleteBarterRequest: $e',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      _crudActionState = ResultStateError(e, 'Gagal menghapus request barter.');
      notifyListeners();
    }
  }

  /// ATOMIC MATCH: Mengajukan barter skill pada request tertentu secara transaksional.
  Future<void> applyBarter(String requestId, String currentUserId) async {
    try {
      _repository.applyBarter(requestId, currentUserId).listen((result) {
        _crudActionState = result;
        notifyListeners();
      });
    } catch (e, stackTrace) {
      debugPrint('========== CRITICAL_INTEGRITY_ALERT: $e ==========');
      developer.log(
        'ERROR saat applyBarter: $e',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      _crudActionState = ResultStateError(e, 'Gagal memproses barter skill.');
      notifyListeners();
    }
  }

  /// Reset status CRUD agar UI tidak mengulang aksi pop-up sukses/gagal saat rebuild.
  void resetCrudActionState() {
    _crudActionState = const ResultStateIdle();
    notifyListeners();
  }
}
