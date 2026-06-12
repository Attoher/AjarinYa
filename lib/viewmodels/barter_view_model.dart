import 'dart:async';
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

  StreamSubscription<ResultState<List<BarterRequest>>>? _barterSub;
  StreamSubscription<ResultState<List<BarterRequest>>>? _matchedSub;

  // State untuk menyimpan List request barter skill yang aktif
  ResultState<List<BarterRequest>> _barterRequestsState = const ResultStateIdle();
  ResultState<List<BarterRequest>> get barterRequestsState => _barterRequestsState;

  // State untuk menyimpan List request barter skill yang sudah MATCHED (riwayat)
  ResultState<List<BarterRequest>> _matchedRequestsState = const ResultStateIdle();
  ResultState<List<BarterRequest>> get matchedRequestsState => _matchedRequestsState;

  // State untuk memantau status eksekusi aksi CRUD (Create/Update/Delete/Apply Barter)
  ResultState<void> _crudActionState = const ResultStateIdle();
  ResultState<void> get crudActionState => _crudActionState;

  /// Memuat list request barter yang dibuat oleh user lain di dalam grup aktif.
  Future<void> fetchBarterRequests(String currentUserId, String groupId) async {
    _barterSub?.cancel();
    _barterRequestsState = const ResultStateLoading();
    notifyListeners();
    try {
      _barterSub = _repository.getBarterRequests(currentUserId, groupId).listen(
        (result) {
          _barterRequestsState = result;
          notifyListeners();
        },
        onError: (e, s) {
          developer.log('ERROR saat fetchBarterRequests: $e', name: 'INTEGRITY_DIAGNOSTICS', error: e, stackTrace: s);
          _barterRequestsState = ResultStateError(e, 'Terjadi kesalahan sistem.');
          notifyListeners();
        },
      );
      fetchMatchedBarterRequests(currentUserId, groupId);
    } catch (e, stackTrace) {
      developer.log('ERROR saat fetchBarterRequests: $e', name: 'INTEGRITY_DIAGNOSTICS', error: e, stackTrace: stackTrace);
      _barterRequestsState = ResultStateError(e, 'Terjadi kesalahan sistem.');
      notifyListeners();
    }
  }

  /// Memuat list request barter yang sudah matched (riwayat) di grup aktif.
  Future<void> fetchMatchedBarterRequests(String currentUserId, String groupId) async {
    _matchedSub?.cancel();
    _matchedRequestsState = const ResultStateLoading();
    notifyListeners();
    try {
      _matchedSub = _repository.getMatchedBarters(currentUserId, groupId).listen(
        (result) {
          _matchedRequestsState = result;
          notifyListeners();
        },
        onError: (e, s) {
          developer.log('ERROR saat fetchMatchedBarterRequests: $e', name: 'INTEGRITY_DIAGNOSTICS', error: e, stackTrace: s);
          _matchedRequestsState = ResultStateError(e, 'Terjadi kesalahan sistem.');
          notifyListeners();
        },
      );
    } catch (e, stackTrace) {
      developer.log('ERROR saat fetchMatchedBarterRequests: $e', name: 'INTEGRITY_DIAGNOSTICS', error: e, stackTrace: stackTrace);
      _matchedRequestsState = ResultStateError(e, 'Terjadi kesalahan sistem.');
      notifyListeners();
    }
  }

  /// Membuat request barter skill baru.
  Future<void> createBarterRequest(BarterRequest request) async {
    try {
      await for (final result in _repository.createBarterRequest(request)) {
        _crudActionState = result;
        notifyListeners();
        if (result is ResultStateError) break;
      }
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
      await for (final result in _repository.updateBarterRequest(request)) {
        _crudActionState = result;
        notifyListeners();
        if (result is ResultStateError) break;
      }
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
      await for (final result in _repository.deleteBarterRequest(requestId)) {
        _crudActionState = result;
        notifyListeners();
        if (result is ResultStateError) break;
      }
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
  Future<void> applyBarter(String requestId, String currentUserId, {String? currentUserName}) async {
    try {
      await for (final result in _repository.applyBarter(requestId, currentUserId, currentUserName: currentUserName)) {
        _crudActionState = result;
        notifyListeners();
        if (result is ResultStateError) break;
      }
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

  @override
  void dispose() {
    _barterSub?.cancel();
    _matchedSub?.cancel();
    super.dispose();
  }
}
