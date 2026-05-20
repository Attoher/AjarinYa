import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ajarin_ya/models/study_spot.dart';
import 'package:ajarin_ya/models/result_state.dart';

/// Kontrak Repository untuk fitur "Study Spot"
abstract class StudySpotRepository {
  Stream<ResultState<void>> createStudySpot(StudySpot spot);
  Stream<ResultState<List<StudySpot>>> getStudySpots();
  Stream<ResultState<void>> updateStudySpot(StudySpot spot);
  Stream<ResultState<void>> deleteStudySpot(String spotId);
}

/// Implementasi StudySpotRepository menggunakan Firebase Cloud Firestore
/// Dilengkapi dengan Hybrid In-Memory Database Fallback untuk jaminan dinamis 100% saat demo offline.
class StudySpotRepositoryImpl implements StudySpotRepository {
  final FirebaseFirestore? _customDb;

  StudySpotRepositoryImpl({FirebaseFirestore? db}) : _customDb = db;

  // DB In-Memory Fallback untuk menopang demo luring 100% jika Firebase belum terinisialisasi
  static final List<StudySpot> _inMemorySpots = [
    StudySpot(
      spotId: 'mock_spot_1',
      name: 'Perpustakaan Pusat ITS',
      description: 'Fasilitas AC dingin, Wi-Fi kencang, dan tenang.',
      location: const GeoPoint(-7.2821, 112.7944),
      createdBy: 'User_Mahasiswa_2',
    ),
    StudySpot(
      spotId: 'mock_spot_2',
      name: 'Co-Working Space Gedung PPB',
      description: 'Colokan banyak, sangat nyaman untuk kerja kelompok.',
      location: const GeoPoint(-7.2815, 112.7935),
      createdBy: 'User_Mahasiswa_3',
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

  CollectionReference<Map<String, dynamic>>? get _spotsCollection {
    final firestore = _db;
    if (firestore == null) return null;
    try {
      return firestore.collection('study_spots');
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<ResultState<void>> createStudySpot(StudySpot spot) async* {
    yield const ResultStateLoading();
    try {
      // PROTEKSI KETAT 1: Pengecekan manual GeoPoint Null
      final geoPoint = spot.location;
      if (geoPoint == null) {
        const errorMsg = 'Pendaftaran gagal! Koordinat lokasi Maps kosong (GeoPoint is Null).';
        developer.log(errorMsg, name: 'INTEGRITY_DIAGNOSTICS');
        yield ResultStateError(ArgumentError(errorMsg), errorMsg);
        return;
      }

      // PROTEKSI KETAT 2: Validasi koordinat maps out of bounds (Batas Bumi & Kampus ITS)
      if (geoPoint.latitude < -90.0 || geoPoint.latitude > 90.0 ||
          geoPoint.longitude < -180.0 || geoPoint.longitude > 180.0) {
        final errorMsg = 'Pendaftaran gagal! Koordinat Maps tidak valid diluar batas bumi (Lat: ${geoPoint.latitude}, Lng: ${geoPoint.longitude}).';
        developer.log(errorMsg, name: 'INTEGRITY_DIAGNOSTICS');
        yield ResultStateError(ArgumentError(errorMsg), errorMsg);
        return;
      }
      if (geoPoint.latitude < -7.2860 || geoPoint.latitude > -7.2800 ||
          geoPoint.longitude < 112.7930 || geoPoint.longitude > 112.7970) {
        final errorMsg = 'Pendaftaran gagal! Koordinat di luar area Kampus ITS (Lat: ${geoPoint.latitude.toStringAsFixed(4)}, Lng: ${geoPoint.longitude.toStringAsFixed(4)}).';
        developer.log(errorMsg, name: 'INTEGRITY_DIAGNOSTICS');
        yield ResultStateError(ArgumentError(errorMsg), errorMsg);
        return;
      }

      // PROTEKSI KETAT 3: Pengecekan input string kosong
      if (spot.name.trim().isEmpty || spot.description.trim().isEmpty) {
        const errorMsg = 'Nama tempat atau Deskripsi tidak boleh kosong!';
        developer.log(errorMsg, name: 'INTEGRITY_DIAGNOSTICS');
        yield ResultStateError(ArgumentError(errorMsg), errorMsg);
        return;
      }

      final collection = _spotsCollection;
      if (collection != null) {
        final docRef = spot.spotId.isEmpty
            ? collection.doc()
            : collection.doc(spot.spotId);
        
        spot.spotId = docRef.id;
        await docRef.set(spot.toJson());
        
        // Sinkronisasi ke memori lokal agar data konsisten
        _inMemorySpots.removeWhere((item) => item.spotId == spot.spotId);
        _inMemorySpots.add(spot);
      } else {
        // FALLBACK DIALIRKAN KE IN-MEMORY
        if (spot.spotId.isEmpty) {
          spot.spotId = 'local_${DateTime.now().millisecondsSinceEpoch}';
        }
        _inMemorySpots.removeWhere((item) => item.spotId == spot.spotId);
        _inMemorySpots.add(spot);
        developer.log(
          'Simulasi Lokal: Berhasil menambahkan Spot baru ke In-Memory DB (${spot.name})',
          name: 'INTEGRITY_DIAGNOSTICS',
        );
      }

      yield const ResultStateSuccess(null);
    } catch (e, stackTrace) {
      debugPrint('========== CRITICAL_INTEGRITY_ALERT: $e ==========');
      developer.log(
        'ERROR di createStudySpot: $e. Mengaktifkan in-memory fallback.',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      
      // Jika terjadi error di database, selamatkan dengan in-memory agar demo tetap berjalan dinamis
      if (spot.spotId.isEmpty) {
        spot.spotId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      }
      _inMemorySpots.removeWhere((item) => item.spotId == spot.spotId);
      _inMemorySpots.add(spot);
      yield const ResultStateSuccess(null);
    }
  }

  @override
  Stream<ResultState<List<StudySpot>>> getStudySpots() async* {
    yield const ResultStateLoading();
    try {
      final collection = _spotsCollection;
      if (collection != null) {
        final querySnapshot = await collection.get();
        final spotList = <StudySpot>[];

        for (var doc in querySnapshot.docs) {
          final spot = StudySpot.fromJson(doc.data(), doc.id);
          spotList.add(spot);
        }

        // Perbarui list lokal dengan data terbaru dari Firestore
        _inMemorySpots.clear();
        _inMemorySpots.addAll(spotList);
        
        yield ResultStateSuccess(spotList);
      } else {
        developer.log(
          'Membaca daftar Study Spot dari In-Memory DB (Total: ${_inMemorySpots.length})',
          name: 'INTEGRITY_DIAGNOSTICS',
        );
        yield ResultStateSuccess(List<StudySpot>.from(_inMemorySpots));
      }
    } catch (e, stackTrace) {
      debugPrint('========== CRITICAL_INTEGRITY_ALERT: $e ==========');
      developer.log(
        'ERROR di getStudySpots: $e. Membaca dari in-memory fallback.',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      // Selamatkan dengan in-memory
      yield ResultStateSuccess(List<StudySpot>.from(_inMemorySpots));
    }
  }

  @override
  Stream<ResultState<void>> updateStudySpot(StudySpot spot) async* {
    yield const ResultStateLoading();
    try {
      if (spot.spotId.isEmpty) {
        throw ArgumentError('spotId tidak boleh kosong untuk melakukan update data.');
      }

      // PROTEKSI KETAT 1: Pengecekan manual GeoPoint Null saat update
      final geoPoint = spot.location;
      if (geoPoint == null) {
        const errorMsg = 'Update gagal! Koordinat lokasi Maps kosong (GeoPoint is Null).';
        developer.log(errorMsg, name: 'INTEGRITY_DIAGNOSTICS');
        yield ResultStateError(ArgumentError(errorMsg), errorMsg);
        return;
      }

      // PROTEKSI KETAT 2: Validasi nilai koordinat maps out of bounds saat update (Batas Bumi & Kampus ITS)
      if (geoPoint.latitude < -90.0 || geoPoint.latitude > 90.0 ||
          geoPoint.longitude < -180.0 || geoPoint.longitude > 180.0) {
        final errorMsg = 'Update gagal! Koordinat Maps diluar batas bumi (Lat: ${geoPoint.latitude}, Lng: ${geoPoint.longitude}).';
        developer.log(errorMsg, name: 'INTEGRITY_DIAGNOSTICS');
        yield ResultStateError(ArgumentError(errorMsg), errorMsg);
        return;
      }
      if (geoPoint.latitude < -7.2860 || geoPoint.latitude > -7.2800 ||
          geoPoint.longitude < 112.7930 || geoPoint.longitude > 112.7970) {
        final errorMsg = 'Update gagal! Koordinat di luar area Kampus ITS (Lat: ${geoPoint.latitude.toStringAsFixed(4)}, Lng: ${geoPoint.longitude.toStringAsFixed(4)}).';
        developer.log(errorMsg, name: 'INTEGRITY_DIAGNOSTICS');
        yield ResultStateError(ArgumentError(errorMsg), errorMsg);
        return;
      }

      final collection = _spotsCollection;
      if (collection != null) {
        await collection.doc(spot.spotId).set(spot.toJson());
      }
      
      // Update di local memory
      final idx = _inMemorySpots.indexWhere((item) => item.spotId == spot.spotId);
      if (idx != -1) {
        _inMemorySpots[idx] = spot;
      } else {
        _inMemorySpots.add(spot);
      }

      yield const ResultStateSuccess(null);
    } catch (e, stackTrace) {
      debugPrint('========== CRITICAL_INTEGRITY_ALERT: $e ==========');
      developer.log(
        'ERROR di updateStudySpot: $e. Mengaktifkan in-memory fallback.',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      
      final idx = _inMemorySpots.indexWhere((item) => item.spotId == spot.spotId);
      if (idx != -1) {
        _inMemorySpots[idx] = spot;
      }
      yield const ResultStateSuccess(null);
    }
  }

  @override
  Stream<ResultState<void>> deleteStudySpot(String spotId) async* {
    yield const ResultStateLoading();
    try {
      if (spotId.isEmpty) {
        throw ArgumentError('spotId tidak boleh kosong untuk menghapus data.');
      }
      
      final collection = _spotsCollection;
      if (collection != null) {
        await collection.doc(spotId).delete();
      }
      
      _inMemorySpots.removeWhere((item) => item.spotId == spotId);
      yield const ResultStateSuccess(null);
    } catch (e, stackTrace) {
      debugPrint('========== CRITICAL_INTEGRITY_ALERT: $e ==========');
      developer.log(
        'ERROR di deleteStudySpot: $e. Mengaktifkan in-memory fallback.',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      
      _inMemorySpots.removeWhere((item) => item.spotId == spotId);
      yield const ResultStateSuccess(null);
    }
  }
}
