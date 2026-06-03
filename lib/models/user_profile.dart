class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String avatarUrl;
  final List<String> groupIds;
  final Map<String, String> groupNames; // mapping of groupId -> groupName
  final String? activeGroupId;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.avatarUrl,
    this.groupIds = const [],
    this.groupNames = const {},
    this.activeGroupId,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    List<String> parsedGroupIds = [];
    if (json['groupIds'] != null) {
      parsedGroupIds = List<String>.from(json['groupIds']);
    } else if (json['groupId'] != null) {
      // Legacy support
      parsedGroupIds = [json['groupId'] as String];
    }

    Map<String, String> parsedGroupNames = {};
    if (json['groupNames'] != null) {
      parsedGroupNames = Map<String, String>.from(json['groupNames']);
    } else {
      // Fallback names for legacy groups
      for (var id in parsedGroupIds) {
        parsedGroupNames[id] = 'Grup $id';
      }
    }

    return UserProfile(
      uid: json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Atha',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      groupIds: parsedGroupIds,
      groupNames: parsedGroupNames,
      activeGroupId: json['activeGroupId'] as String? ?? (parsedGroupIds.isNotEmpty ? parsedGroupIds.first : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'groupIds': groupIds,
      'groupNames': groupNames,
      'activeGroupId': activeGroupId,
    };
  }
}
