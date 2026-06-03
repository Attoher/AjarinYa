import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Model data untuk fitur "Study Spot" (Collection: `study_spots`).
/// Menangani `GeoPoint` secara dinamis dan aman terhadap masukan kosong (null)
/// atau tipe data yang tidak sesuai selama demo simulasi.
class StudySpot {
  String spotId;
  String? groupId;
  String name;
  String description;
  GeoPoint? location;
  String createdBy;

  StudySpot({
    this.spotId = '',
    this.groupId,
    this.name = '',
    this.description = '',
    this.location = const GeoPoint(0.0, 0.0),
    this.createdBy = '',
  });

  /// Mengecek apakah spot memiliki data koordinat yang valid dan tidak di koordinat default (0.0, 0.0)
  bool hasValidLocation() => location != null && (location!.latitude != 0.0 || location!.longitude != 0.0);

  /// Mengambil nilai latitude secara aman. Mengembalikan 0.0 jika null.
  double getSafeLatitude() {
    return location?.latitude ?? 0.0;
  }

  /// Mengambil nilai longitude secara aman. Mengembalikan 0.0 jika null.
  double getSafeLongitude() {
    return location?.longitude ?? 0.0;
  }

  /// Mengubah JSON Map dari Firestore menjadi objek StudySpot secara aman.
  factory StudySpot.fromJson(Map<String, dynamic>? json, String documentId) {
    if (json == null) {
      debugPrint('========== CRITICAL_INTEGRITY_ALERT: data JSON null untuk StudySpot ID: $documentId ==========');
      return StudySpot(spotId: documentId);
    }

    // PROTEKSI NULL SAFETY JINGGA: Cegah error type casting jika tipenya diubah secara eksternal
    GeoPoint? safeLocationParser(dynamic rawLocation) {
      if (rawLocation is GeoPoint) {
        return rawLocation;
      }
      // Jika data dikosongkan, diubah nilainya menjadi null, atau tipenya rusak secara tidak sengaja
      developer.log(
        'Warning: Tipe data location rusak atau null (diterima: ${rawLocation.runtimeType}). Mengaktifkan fallback GeoPoint(0.0, 0.0).',
        name: 'INTEGRITY_DIAGNOSTICS',
      );
      return const GeoPoint(0.0, 0.0); // Fallback ke koordinat 0.0, 0.0
    }

    try {
      return StudySpot(
        spotId: json['spotId'] as String? ?? documentId,
        groupId: json['groupId'] as String?,
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        location: safeLocationParser(json['location']),
        createdBy: json['createdBy'] as String? ?? '',
      );
    } catch (e, stackTrace) {
      debugPrint('========== CRITICAL_INTEGRITY_ALERT: $e ==========');
      developer.log(
        'CRITICAL ERROR pada parsing StudySpot untuk doc: $documentId. Pesan: $e',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      return StudySpot(spotId: documentId, location: const GeoPoint(0.0, 0.0));
    }
  }

  /// Mengubah objek menjadi Map untuk Firestore.
  Map<String, dynamic> toJson() {
    return {
      'spotId': spotId,
      'groupId': groupId,
      'name': name,
      'description': description,
      'location': location,
      'createdBy': createdBy,
    };
  }
}
