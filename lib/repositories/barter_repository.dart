import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ajarin_ya/models/barter_request.dart';
import 'package:ajarin_ya/models/result_state.dart';

/// Kontrak Repository untuk fitur "Request Barter Skill"
abstract class BarterRepository {
  Stream<ResultState<void>> createBarterRequest(BarterRequest request);
  Stream<ResultState<List<BarterRequest>>> getBarterRequests(String currentUserId);
  Stream<ResultState<void>> updateBarterRequest(BarterRequest request);
  Stream<ResultState<void>> deleteBarterRequest(String requestId);
  Stream<ResultState<void>> applyBarter(String requestId, String currentUserId);
  Stream<ResultState<List<BarterRequest>>> getMatchedBarters(String currentUserId);
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
      yield ResultStateError(e as Exception, 'Gagal membuat request barter ke server: $e');
    }
  }

  @override
  Stream<ResultState<List<BarterRequest>>> getBarterRequests(String currentUserId) async* {
    yield const ResultStateLoading();
    try {
      final collection = _barterCollection;
      if (collection != null) {
        QuerySnapshot<Map<String, dynamic>> querySnapshot;
        
        querySnapshot = await collection
            .where('status', isEqualTo: 'PENDING')
            .get();

        final requestList = <BarterRequest>[];
        for (var doc in querySnapshot.docs) {
          final request = BarterRequest.fromJson(doc.data(), doc.id);
          requestList.add(request);
        }

        yield ResultStateSuccess(requestList);
      } else {
        throw Exception('Koneksi database (Firestore) tidak tersedia.');
      }
    } catch (e, stackTrace) {
      developer.log(
        'ERROR di getBarterRequests: $e.',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      yield ResultStateError(e as Exception, 'Gagal memuat daftar request barter dari server: $e');
    }
  }

  @override
  Stream<ResultState<List<BarterRequest>>> getMatchedBarters(String currentUserId) async* {
    yield const ResultStateLoading();
    try {
      final collection = _barterCollection;
      if (collection != null) {
        final querySnapshot = await collection
            .where('status', isEqualTo: 'MATCHED')
            .get();

        final requestList = <BarterRequest>[];
        for (var doc in querySnapshot.docs) {
          final request = BarterRequest.fromJson(doc.data(), doc.id);
          // Filter lokal untuk menghindari kebutuhan Composite Index
          if (request.userId == currentUserId || request.matchedWith == currentUserId) {
            requestList.add(request);
          }
        }

        yield ResultStateSuccess(requestList);
      } else {
        throw Exception('Koneksi database (Firestore) tidak tersedia.');
      }
    } catch (e, stackTrace) {
      developer.log(
        'ERROR di getMatchedBarters: $e.',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      yield ResultStateError(e as Exception, 'Gagal memuat riwayat match barter: $e');
    }
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
        await collection.doc(request.requestId).set(request.toJson());
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
      yield ResultStateError(e as Exception, 'Gagal mengupdate request barter di server: $e');
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
      yield ResultStateError(e as Exception, 'Gagal menghapus request barter di server: $e');
    }
  }

  @override
  Stream<ResultState<void>> applyBarter(String requestId, String currentUserId) async* {
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
      yield ResultStateError(e as Exception, e is FirebaseException ? e.message ?? 'Gagal memproses barter.' : e.toString());
    }
  }
}
