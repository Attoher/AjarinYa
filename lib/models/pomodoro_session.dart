import 'package:cloud_firestore/cloud_firestore.dart';

class PomodoroSession {
  String id;
  String ownerId;
  String mode;
  int durationMinutes;
  DateTime completedAt;

  PomodoroSession({
    this.id = '',
    required this.ownerId,
    required this.mode,
    required this.durationMinutes,
    required this.completedAt,
  });

  factory PomodoroSession.fromJson(Map<String, dynamic> json, String documentId) {
    return PomodoroSession(
      id: documentId,
      ownerId: json['ownerId'] as String? ?? '',
      mode: json['mode'] as String? ?? 'Focus',
      durationMinutes: json['durationMinutes'] as int? ?? 25,
      completedAt: (json['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ownerId': ownerId,
      'mode': mode,
      'durationMinutes': durationMinutes,
      'completedAt': Timestamp.fromDate(completedAt),
    };
  }
}
