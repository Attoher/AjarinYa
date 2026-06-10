import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Model data untuk fitur "Request Barter Skill" (Collection: `barter_requests`).
/// Dilengkapi parsing JSON toleran terhadap null dan pertahanan anti-crash.
class BarterRequest {
  String requestId;
  String? groupId;
  String userId;
  String? userName; // displayName of the requestor
  String canTeach;
  String wantToLearn;
  String status; // "PENDING" atau "MATCHED"
  String? matchedWith;

  BarterRequest({
    this.requestId = '',
    this.groupId,
    this.userId = '',
    this.userName,
    this.canTeach = '',
    this.wantToLearn = '',
    this.status = 'PENDING',
    this.matchedWith,
  });

  /// Mengubah JSON Map dari Firestore menjadi objek BarterRequest secara aman.
  factory BarterRequest.fromJson(Map<String, dynamic>? json, String documentId) {
    if (json == null) {
      debugPrint('========== CRITICAL_INTEGRITY_ALERT: data JSON null untuk BarterRequest ID: $documentId ==========');
      return BarterRequest(requestId: documentId);
    }

    try {
      return BarterRequest(
        requestId: (json['requestId'] as String?)?.isNotEmpty == true ? json['requestId'] as String : documentId,
        groupId: json['groupId'] as String?,
        userId: json['userId'] as String? ?? '',
        userName: json['userName'] as String?,
        canTeach: json['canTeach'] as String? ?? '',
        wantToLearn: json['wantToLearn'] as String? ?? '',
        status: json['status'] as String? ?? 'PENDING',
        matchedWith: json['matchedWith'] as String?,
      );
    } catch (e, stackTrace) {
      debugPrint('========== CRITICAL_INTEGRITY_ALERT: $e ==========');
      developer.log(
        'CRITICAL ERROR pada parsing BarterRequest untuk doc: $documentId. Pesan: $e',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );
      return BarterRequest(requestId: documentId);
    }
  }

  /// Mengubah objek menjadi Map untuk kemudahan penyimpanan di Firestore.
  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'groupId': groupId,
      'userId': userId,
      'userName': userName,
      'canTeach': canTeach,
      'wantToLearn': wantToLearn,
      'status': status,
      'matchedWith': matchedWith,
    };
  }
}
