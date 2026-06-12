import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ajarin_ya/models/barter_request.dart';
import 'package:ajarin_ya/models/result_state.dart';

/// Kontrak Repository untuk fitur "Request Barter Skill"
abstract class BarterRepository {
  Stream<ResultState<void>> createBarterRequest(BarterRequest request);
  Stream<ResultState<List<BarterRequest>>> getBarterRequests(String currentUserId, String groupId);
  Stream<ResultState<void>> updateBarterRequest(BarterRequest request);
  Stream<ResultState<void>> deleteBarterRequest(String requestId);
  Stream<ResultState<void>> applyBarter(String requestId, String currentUserId, {String? currentUserName});
  Stream<ResultState<List<BarterRequest>>> getMatchedBarters(String currentUserId, String groupId);
}

class BarterRepositoryImpl implements BarterRepository {
  final FirebaseFirestore? _customDb;

  BarterRepositoryImpl({FirebaseFirestore? db}) : _customDb = db;

  FirebaseFirestore? get _db {
    try {
      return _customDb ?? FirebaseFirestore.instance;
    } catch (e) {
      developer.log(
        'Firebase Core belum diinisialisasi. Beralih ke mode simulasi lokal dinamis.',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
      );
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? get _barterCollection {
    final firestore = _db;
    if (firestore == null) return null;
    try {
      return firestore.collection('barter_requests');
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<ResultState<void>> createBarterRequest(BarterRequest request) async* {
    yield const ResultStateLoading();
    try {
      final collection = _barterCollection;
      if (collection != null) {
        if (request.requestId.isEmpty) {
          final docRef = await collection.add(request.toJson());
          request.requestId = docRef.id;
        } else {
          await collection.doc(request.requestId).set(request.toJson());
        }
      } else {
        throw Exception('Koneksi database (Firestore) tidak tersedia.');
      }
      yield const ResultStateSuccess(null);
    } catch (e, stackTrace) {
      developer.log(
        'ERROR di createBarterRequest: $e.',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      yield ResultStateError(e, 'Gagal membuat request barter ke server: $e');
    }
  }

  @override
  Stream<ResultState<List<BarterRequest>>> getBarterRequests(String currentUserId, String groupId) {
    final collection = _barterCollection;
    if (collection == null) {
      return Stream.value(ResultStateError(Exception('DB tidak tersedia'), 'Database tidak tersedia'));
    }
    return collection
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map<ResultState<List<BarterRequest>>>((snapshot) {
          try {
            final list = snapshot.docs
                .map((doc) => BarterRequest.fromJson(doc.data(), doc.id))
                .where((r) => r.status == 'PENDING')
                .toList();
            return ResultStateSuccess(list);
          } catch (e) {
            developer.log('ERROR memproses getBarterRequests: $e', name: 'INTEGRITY_DIAGNOSTICS');
            return ResultStateError(e, 'Gagal memproses data barter: $e');
          }
        });
  }

  @override
  Stream<ResultState<List<BarterRequest>>> getMatchedBarters(String currentUserId, String groupId) {
    final collection = _barterCollection;
    if (collection == null) {
      return Stream.value(ResultStateError(Exception('DB tidak tersedia'), 'Database tidak tersedia'));
    }
    return collection
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map<ResultState<List<BarterRequest>>>((snapshot) {
          try {
            final list = snapshot.docs
                .map((doc) => BarterRequest.fromJson(doc.data(), doc.id))
                .where((r) =>
                    r.status == 'MATCHED' &&
                    (r.userId == currentUserId || r.matchedWith == currentUserId))
                .toList();
            return ResultStateSuccess(list);
          } catch (e) {
            developer.log('ERROR memproses getMatchedBarters: $e', name: 'INTEGRITY_DIAGNOSTICS');
            return ResultStateError(e, 'Gagal memproses data matched barter: $e');
          }
        });
  }

  @override
  Stream<ResultState<void>> updateBarterRequest(BarterRequest request) async* {
    yield const ResultStateLoading();
    try {
      if (request.requestId.isEmpty) {
        throw ArgumentError('requestId tidak boleh kosong untuk melakukan update data.');
      }
      
      final collection = _barterCollection;
      if (collection != null) {
        await collection.doc(request.requestId).set(request.toJson(), SetOptions(merge: true));
      } else {
        throw Exception('Koneksi database (Firestore) tidak tersedia.');
      }

      yield const ResultStateSuccess(null);
    } catch (e, stackTrace) {
      developer.log(
        'ERROR di updateBarterRequest: $e.',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      yield ResultStateError(e, 'Gagal mengupdate request barter di server: $e');
    }
  }

  @override
  Stream<ResultState<void>> deleteBarterRequest(String requestId) async* {
    yield const ResultStateLoading();
    try {
      if (requestId.isEmpty) {
        throw ArgumentError('requestId tidak boleh kosong untuk menghapus data.');
      }
      
      final collection = _barterCollection;
      if (collection != null) {
        await collection.doc(requestId).delete();
      } else {
        throw Exception('Koneksi database (Firestore) tidak tersedia.');
      }

      yield const ResultStateSuccess(null);
    } catch (e, stackTrace) {
      developer.log(
        'ERROR di deleteBarterRequest: $e.',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      yield ResultStateError(e, 'Gagal menghapus request barter di server: $e');
    }
  }

  @override
  Stream<ResultState<void>> applyBarter(String requestId, String currentUserId, {String? currentUserName}) async* {
    yield const ResultStateLoading();
    try {
      final collection = _barterCollection;
      if (collection != null) {
        final docRef = collection.doc(requestId);

        // ATOMIC TRANSACTION: Menjamin tidak terjadi race condition!
        await _db!.runTransaction((transaction) async {
          final snapshot = await transaction.get(docRef);
          
          if (!snapshot.exists) {
            throw FirebaseException(
              plugin: 'cloud_firestore',
              code: 'not-found',
              message: 'Dokumen request barter tidak ditemukan.',
            );
          }

          final data = snapshot.data();
          final status = data?['status'] as String? ?? 'PENDING';
          final userId = data?['userId'] as String? ?? '';

          // Validasi: Tidak boleh barter dengan buatan sendiri
          if (userId == currentUserId) {
            throw FirebaseException(
              plugin: 'cloud_firestore',
              code: 'permission-denied',
              message: 'Anda tidak bisa membarter request buatan Anda sendiri.',
            );
          }

          // Validasi: Status harus PENDING. Jika sudah MATCHED, gagalkan transaksi.
          if (status != 'PENDING') {
            throw FirebaseException(
              plugin: 'cloud_firestore',
              code: 'aborted',
              message: 'Maaf, request barter ini sudah diambil oleh orang lain secara bersamanya!',
            );
          }

          // Melakukan update secara atomic
          transaction.update(docRef, {
            'status': 'MATCHED',
            'matchedWith': currentUserId,
            'matchedWithName': currentUserName,
          });
        });

      } else {
        throw Exception('Koneksi database (Firestore) tidak tersedia.');
      }

      yield const ResultStateSuccess(null);
    } catch (e, stackTrace) {
      developer.log(
        'CRITICAL ABORT di applyBarter pada doc: $requestId oleh user: $currentUserId. Alasan: $e',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      yield ResultStateError(e, e is FirebaseException ? e.message ?? 'Gagal memproses barter.' : e.toString());
    }
  }
}
