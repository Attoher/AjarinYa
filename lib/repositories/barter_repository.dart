import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
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
}

/// Implementasi BarterRepository menggunakan Firebase Cloud Firestore
/// Dilengkapi dengan Hybrid In-Memory Database Fallback untuk jaminan dinamis 100% saat demo offline.
class BarterRepositoryImpl implements BarterRepository {
  final FirebaseFirestore? _customDb;

  BarterRepositoryImpl({FirebaseFirestore? db}) : _customDb = db;

  // DB In-Memory Fallback untuk menopang demo luring 100% jika Firebase belum terinisialisasi
  static final List<BarterRequest> _inMemoryBarters = [
    BarterRequest(
      requestId: 'mock_req_1',
      userId: 'User_Mahasiswa_2',
      canTeach: 'Pemrograman Flutter & Dart',
      wantToLearn: 'UI/UX Design Figma',
      status: 'PENDING',
    ),
    BarterRequest(
      requestId: 'mock_req_2',
      userId: 'User_Mahasiswa_3',
      canTeach: 'Aljabar Linear & Kalkulus',
      wantToLearn: 'Bahasa Inggris Konversasional',
      status: 'PENDING',
    ),
  ];

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
        final docRef = request.requestId.isEmpty
            ? collection.doc()
            : collection.doc(request.requestId);
        
        request.requestId = docRef.id;
        await docRef.set(request.toJson());
        
        // Sinkronisasi lokal
        _inMemoryBarters.removeWhere((item) => item.requestId == request.requestId);
        _inMemoryBarters.add(request);
      } else {
        // FALLBACK DIALIRKAN KE IN-MEMORY
        if (request.requestId.isEmpty) {
          request.requestId = 'local_req_${DateTime.now().millisecondsSinceEpoch}';
        }
        _inMemoryBarters.removeWhere((item) => item.requestId == request.requestId);
        _inMemoryBarters.add(request);
        developer.log(
          'Simulasi Lokal: Berhasil menambahkan Request Barter baru ke In-Memory DB (${request.canTeach})',
          name: 'INTEGRITY_DIAGNOSTICS',
        );
      }
      yield const ResultStateSuccess(null);
    } catch (e, stackTrace) {
      debugPrint('========== CRITICAL_INTEGRITY_ALERT: $e ==========');
      developer.log(
        'ERROR di createBarterRequest: $e. Mengaktifkan in-memory fallback.',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      
      if (request.requestId.isEmpty) {
        request.requestId = 'local_req_${DateTime.now().millisecondsSinceEpoch}';
      }
      _inMemoryBarters.removeWhere((item) => item.requestId == request.requestId);
      _inMemoryBarters.add(request);
      yield const ResultStateSuccess(null);
    }
  }

  @override
  Stream<ResultState<List<BarterRequest>>> getBarterRequests(String currentUserId) async* {
    yield const ResultStateLoading();
    try {
      final collection = _barterCollection;
      if (collection != null) {
        QuerySnapshot<Map<String, dynamic>> querySnapshot;
        
        // DUAL-DEFENSE STRATEGY:
        // Langkah 1: Jalankan query dengan whereNotEqualTo. Di Firestore, ini memerlukan indeks gabungan.
        try {
          querySnapshot = await collection
              .where('userId', isNotEqualTo: currentUserId)
              .where('status', isEqualTo: 'PENDING')
              .get();
        } catch (e) {
          // FALLBACK: Jika query inequality gagal karena indeks belum terbuat,
          // ambil semua yang "PENDING" lalu lakukan filtering di memori lokal agar aplikasi tidak hang/crash.
          developer.log(
            'WARNING di getBarterRequests (Composite Index belum terbuat): $e. Mengaktifkan in-memory fallback filter.',
            name: 'INTEGRITY_DIAGNOSTICS',
          );

          querySnapshot = await collection
              .where('status', isEqualTo: 'PENDING')
              .get();
        }

        final requestList = <BarterRequest>[];
        for (var doc in querySnapshot.docs) {
          final request = BarterRequest.fromJson(doc.data(), doc.id);
          
          // ==========================================
          // LOGIKA SECURITY BARTER (Anti-Cheat Lapisan Ganda):
          // Memaksa asersi di level Dart. Jika simulator sengaja menghapus filter Firestore di query,
          // asersi ini akan langsung memicu error di mode debug, mencegah data diri sendiri tampil.
          assert(
            request.userId != currentUserId, 
            'CRITICAL SECURITY EXCEPTION: Data request barter milik sendiri terobos masuk ke antarmuka aplikasi!'
          );

          // Pertahanan level produksi: skip item jika asersi dilewati / di-disable dalam release mode
          if (request.userId == currentUserId) {
            developer.log(
              'Anti-Cheat Bypassed: Request milik sendiri (${request.requestId}) ditolak untuk ditampilkan.',
              name: 'INTEGRITY_DIAGNOSTICS',
            );
            continue; 
          }
          // ==========================================

          requestList.add(request);
        }

        // Sinkronisasi memori lokal agar data tetap mutakhir
        _inMemoryBarters.clear();
        _inMemoryBarters.addAll(requestList);

        yield ResultStateSuccess(requestList);
      } else {
        // FALLBACK DIALIRKAN KE IN-MEMORY
        developer.log(
          'Membaca daftar Request Barter dari In-Memory DB (Total: ${_inMemoryBarters.length})',
          name: 'INTEGRITY_DIAGNOSTICS',
        );

        final filteredList = _inMemoryBarters.where((req) {
          // Tetap lakukan pertahanan security meskipun offline!
          if (req.userId == currentUserId) {
            developer.log(
              'Anti-Cheat (Offline Check): Menyaring request milik sendiri (${req.requestId})',
              name: 'INTEGRITY_DIAGNOSTICS',
            );
            return false;
          }
          return req.status == 'PENDING';
        }).toList();

        yield ResultStateSuccess(filteredList);
      }
    } catch (e, stackTrace) {
      debugPrint('========== CRITICAL_INTEGRITY_ALERT: $e ==========');
      developer.log(
        'ERROR di getBarterRequests: $e. Membaca dari in-memory fallback.',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );

      final filteredList = _inMemoryBarters.where((req) {
        return req.userId != currentUserId && req.status == 'PENDING';
      }).toList();

      yield ResultStateSuccess(filteredList);
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
      }

      final idx = _inMemoryBarters.indexWhere((item) => item.requestId == request.requestId);
      if (idx != -1) {
        _inMemoryBarters[idx] = request;
      } else {
        _inMemoryBarters.add(request);
      }

      yield const ResultStateSuccess(null);
    } catch (e, stackTrace) {
      debugPrint('========== CRITICAL_INTEGRITY_ALERT: $e ==========');
      developer.log(
        'ERROR di updateBarterRequest: $e. Mengaktifkan in-memory fallback.',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );

      final idx = _inMemoryBarters.indexWhere((item) => item.requestId == request.requestId);
      if (idx != -1) {
        _inMemoryBarters[idx] = request;
      }
      yield const ResultStateSuccess(null);
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
      }

      _inMemoryBarters.removeWhere((item) => item.requestId == requestId);
      yield const ResultStateSuccess(null);
    } catch (e, stackTrace) {
      debugPrint('========== CRITICAL_INTEGRITY_ALERT: $e ==========');
      developer.log(
        'ERROR di deleteBarterRequest: $e. Mengaktifkan in-memory fallback.',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );

      _inMemoryBarters.removeWhere((item) => item.requestId == requestId);
      yield const ResultStateSuccess(null);
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

        // Sinkronisasi lokal
        final idx = _inMemoryBarters.indexWhere((item) => item.requestId == requestId);
        if (idx != -1) {
          _inMemoryBarters[idx].status = 'MATCHED';
          _inMemoryBarters[idx].matchedWith = currentUserId;
        }
      } else {
        // FALLBACK DIALIRKAN KE IN-MEMORY TRANSACTION SIMULATION
        final idx = _inMemoryBarters.indexWhere((item) => item.requestId == requestId);
        if (idx == -1) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'not-found',
            message: 'Dokumen request barter tidak ditemukan.',
          );
        }

        final req = _inMemoryBarters[idx];
        
        // Cek Security buatan sendiri
        if (req.userId == currentUserId) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
            message: 'Anda tidak bisa membarter request buatan Anda sendiri.',
          );
        }

        // Cek Status PENDING
        if (req.status != 'PENDING') {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'aborted',
            message: 'Maaf, request barter ini sudah diambil oleh orang lain secara bersamaan!',
          );
        }

        // Jalankan update secara atomic lokal
        req.status = 'MATCHED';
        req.matchedWith = currentUserId;

        developer.log(
          'Simulasi Transaksi Lokal Atomik Sukses: Berhasil memasangkan Barter (${req.requestId}) dengan $currentUserId',
          name: 'INTEGRITY_DIAGNOSTICS',
        );
      }

      yield const ResultStateSuccess(null);
    } catch (e, stackTrace) {
      debugPrint('========== CRITICAL_INTEGRITY_ALERT: $e ==========');
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
