class PomodoroPreset {
  String id;
  String name;
  int focusMinutes;
  int shortBreakMinutes;
  int longBreakMinutes;
  String ownerId;

  PomodoroPreset({
    this.id = '',
    required this.name,
    this.focusMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.ownerId = '',
  });

  factory PomodoroPreset.fromJson(Map<String, dynamic> json, String documentId) {
    return PomodoroPreset(
      id: documentId,
      name: json['name'] as String? ?? '',
      focusMinutes: json['focusMinutes'] as int? ?? 25,
      shortBreakMinutes: json['shortBreakMinutes'] as int? ?? 5,
      longBreakMinutes: json['longBreakMinutes'] as int? ?? 15,
      ownerId: json['ownerId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'focusMinutes': focusMinutes,
      'shortBreakMinutes': shortBreakMinutes,
      'longBreakMinutes': longBreakMinutes,
      'ownerId': ownerId,
    };
  }

  PomodoroPreset copyWith({
    String? id,
    String? name,
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    String? ownerId,
  }) {
    return PomodoroPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      ownerId: ownerId ?? this.ownerId,
    );
  }
}
