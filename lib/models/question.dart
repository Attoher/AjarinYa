class Reply {
  String id;
  String author;
  String content;
  int votes;
  bool isBest;
  int createdAtMs;
  int updatedAtMs;

  Reply({
    this.id = '',
    required this.author,
    required this.content,
    this.votes = 0,
    this.isBest = false,
    int? createdAtMs,
    int? updatedAtMs,
  }) : createdAtMs = createdAtMs ?? DateTime.now().millisecondsSinceEpoch,
       updatedAtMs = updatedAtMs ?? DateTime.now().millisecondsSinceEpoch;

  factory Reply.fromJson(Map<String, dynamic> json) {
    return Reply(
      id: json['id'] as String? ?? '',
      author: json['author'] as String? ?? 'Pengguna',
      content: json['content'] as String? ?? '',
      votes: json['votes'] as int? ?? 0,
      isBest: json['isBest'] as bool? ?? false,
      createdAtMs: json['createdAtMs'] as int?,
      updatedAtMs: json['updatedAtMs'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author,
      'content': content,
      'votes': votes,
      'isBest': isBest,
      'createdAtMs': createdAtMs,
      'updatedAtMs': updatedAtMs,
    };
  }

  Reply copyWith({
    String? id,
    String? author,
    String? content,
    int? votes,
    bool? isBest,
    int? createdAtMs,
    int? updatedAtMs,
  }) {
    return Reply(
      id: id ?? this.id,
      author: author ?? this.author,
      content: content ?? this.content,
      votes: votes ?? this.votes,
      isBest: isBest ?? this.isBest,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }
}

class Question {
  String id;
  String author;
  String avatar;
  String title;
  String content;
  String tag;
  String? imageUrl;
  int votes;
  int answersCount;
  String time;
  bool isUpvoted;
  bool isSolved;
  int createdAtMs;
  int updatedAtMs;
  List<Reply> replies;
  String ownerId;

  Question({
    this.id = '',
    required this.author,
    required this.avatar,
    required this.title,
    required this.content,
    required this.tag,
    this.imageUrl,
    this.votes = 0,
    this.answersCount = 0,
    required this.time,
    this.isUpvoted = false,
    this.isSolved = false,
    int? createdAtMs,
    int? updatedAtMs,
    required this.replies,
    this.ownerId = '',
  }) : createdAtMs = createdAtMs ?? DateTime.now().millisecondsSinceEpoch,
       updatedAtMs = updatedAtMs ?? DateTime.now().millisecondsSinceEpoch;

  factory Question.fromJson(Map<String, dynamic> json, String documentId) {
    final rawReplies = json['replies'] as List<dynamic>? ?? [];
    final parsedReplies = rawReplies.asMap().entries.map((entry) {
      final reply = Reply.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
      );
      if (reply.id.isEmpty) {
        reply.id = '${documentId}_answer_${entry.key}_${reply.createdAtMs}';
      }
      return reply;
    }).toList()..sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));

    return Question(
      id: documentId,
      author: json['author'] as String? ?? 'Pengguna',
      avatar: json['avatar'] as String? ?? 'M',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      tag: json['tag'] as String? ?? 'Umum',
      imageUrl: json['imageUrl'] as String?,
      votes: json['votes'] as int? ?? 0,
      answersCount: json['answersCount'] as int? ?? parsedReplies.length,
      time: json['time'] as String? ?? 'Baru Saja',
      isUpvoted: json['isUpvoted'] as bool? ?? false,
      isSolved: json['isSolved'] as bool? ?? parsedReplies.any((r) => r.isBest),
      createdAtMs: json['createdAtMs'] as int?,
      updatedAtMs: json['updatedAtMs'] as int?,
      replies: parsedReplies,
      ownerId: json['ownerId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'author': author,
      'avatar': avatar,
      'title': title,
      'content': content,
      'tag': tag,
      'imageUrl': imageUrl,
      'votes': votes,
      'answersCount': replies.length,
      'time': time,
      'isUpvoted': isUpvoted,
      'isSolved': replies.any((r) => r.isBest),
      'createdAtMs': createdAtMs,
      'updatedAtMs': updatedAtMs,
      'replies': replies.map((r) => r.toJson()).toList(),
      'ownerId': ownerId,
    };
  }

  Question copyWith({
    String? id,
    String? author,
    String? avatar,
    String? title,
    String? content,
    String? tag,
    String? imageUrl,
    int? votes,
    int? answersCount,
    String? time,
    bool? isUpvoted,
    bool? isSolved,
    int? createdAtMs,
    int? updatedAtMs,
    List<Reply>? replies,
    String? ownerId,
  }) {
    return Question(
      id: id ?? this.id,
      author: author ?? this.author,
      avatar: avatar ?? this.avatar,
      title: title ?? this.title,
      content: content ?? this.content,
      tag: tag ?? this.tag,
      imageUrl: imageUrl ?? this.imageUrl,
      votes: votes ?? this.votes,
      answersCount: answersCount ?? this.answersCount,
      time: time ?? this.time,
      isUpvoted: isUpvoted ?? this.isUpvoted,
      isSolved: isSolved ?? this.isSolved,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      replies: replies ?? List<Reply>.from(this.replies),
      ownerId: ownerId ?? this.ownerId,
    );
  }
}
