import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ajarin_ya/models/study_spot.dart';
import 'package:ajarin_ya/models/result_state.dart';

/// Kontrak Repository untuk fitur "Study Spot"
abstract class StudySpotRepository {
  Stream<ResultState<void>> createStudySpot(StudySpot spot);
  Stream<ResultState<List<StudySpot>>> getStudySpots(String groupId);
  Stream<ResultState<void>> updateStudySpot(StudySpot spot);
  Stream<ResultState<void>> deleteStudySpot(String spotId);
}

/// Implementasi StudySpotRepository menggunakan Firebase Cloud Firestore
class StudySpotRepositoryImpl implements StudySpotRepository {
  final FirebaseFirestore? _customDb;

  StudySpotRepositoryImpl({FirebaseFirestore? db}) : _customDb = db;

  FirebaseFirestore? get _db {
    try {
      return _customDb ?? FirebaseFirestore.instance;
    } catch (e) {
      developer.log(
        'Firebase Core belum diinisialisasi.',
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
      final geoPoint = spot.location;
      if (geoPoint == null) {
        const errorMsg = 'Pendaftaran gagal! Koordinat lokasi Maps kosong (GeoPoint is Null).';
        developer.log(errorMsg, name: 'INTEGRITY_DIAGNOSTICS');
        yield ResultStateError(ArgumentError(errorMsg), errorMsg);
        return;
      }

      if (geoPoint.latitude < -90.0 || geoPoint.latitude > 90.0 ||
          geoPoint.longitude < -180.0 || geoPoint.longitude > 180.0) {
        final errorMsg = 'Pendaftaran gagal! Koordinat Maps tidak valid diluar batas bumi (Lat: ${geoPoint.latitude}, Lng: ${geoPoint.longitude}).';
        developer.log(errorMsg, name: 'INTEGRITY_DIAGNOSTICS');
        yield ResultStateError(ArgumentError(errorMsg), errorMsg);
        return;
      }


      if (spot.name.trim().isEmpty || spot.description.trim().isEmpty) {
        const errorMsg = 'Nama tempat atau Deskripsi tidak boleh kosong!';
        developer.log(errorMsg, name: 'INTEGRITY_DIAGNOSTICS');
        yield ResultStateError(ArgumentError(errorMsg), errorMsg);
        return;
      }

      final collection = _spotsCollection;
      if (collection != null) {
        if (spot.spotId.isEmpty) {
          final docRef = await collection.add(spot.toJson());
          spot.spotId = docRef.id;
        } else {
          await collection.doc(spot.spotId).set(spot.toJson());
        }
      } else {
        throw Exception('Koneksi database (Firestore) tidak tersedia.');
      }

      yield const ResultStateSuccess(null);
    } catch (e, stackTrace) {
      developer.log(
        'ERROR di createStudySpot: $e.',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      yield ResultStateError(e, 'Gagal menambahkan lokasi belajar ke server: $e');
    }
  }

  @override
  Stream<ResultState<List<StudySpot>>> getStudySpots(String groupId) {
    final collection = _spotsCollection;
    if (collection == null) {
      return Stream.value(ResultStateError(Exception('DB tidak tersedia'), 'Database tidak tersedia'));
    }
    return collection
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map<ResultState<List<StudySpot>>>((snapshot) {
          try {
            final list = snapshot.docs
                .map((doc) => StudySpot.fromJson(doc.data(), doc.id))
                .toList();
            return ResultStateSuccess(list);
          } catch (e) {
            developer.log('ERROR memproses getStudySpots: $e', name: 'INTEGRITY_DIAGNOSTICS');
            return ResultStateError(e, 'Gagal memproses data study spot: $e');
          }
        });
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


      final collection = _spotsCollection;
      if (collection != null) {
        await collection.doc(spot.spotId).set(spot.toJson(), SetOptions(merge: true));
      } else {
        throw Exception('Koneksi database (Firestore) tidak tersedia.');
      }

      yield const ResultStateSuccess(null);
    } catch (e, stackTrace) {
      developer.log(
        'ERROR di updateStudySpot: $e.',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      yield ResultStateError(e, 'Gagal mengupdate lokasi belajar di server: $e');
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
      } else {
        throw Exception('Koneksi database (Firestore) tidak tersedia.');
      }

      yield const ResultStateSuccess(null);
    } catch (e, stackTrace) {
      developer.log(
        'ERROR di deleteStudySpot: $e.',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      yield ResultStateError(e, 'Gagal menghapus lokasi belajar di server: $e');
    }
  }
}
