class Reply {
  final String author;
  final String content;
  int votes;
  bool isBest;

  Reply({
    required this.author,
    required this.content,
    this.votes = 0,
    this.isBest = false,
  });

  factory Reply.fromJson(Map<String, dynamic> json) {
    return Reply(
      author: json['author'] as String? ?? 'Mahasiswa ITS',
      content: json['content'] as String? ?? '',
      votes: json['votes'] as int? ?? 0,
      isBest: json['isBest'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'author': author,
      'content': content,
      'votes': votes,
      'isBest': isBest,
    };
  }
}

class Question {
  String id;
  final String author;
  final String avatar;
  final String title;
  final String content;
  final String tag;
  int votes;
  int answersCount;
  final String time;
  bool isUpvoted;
  bool isSolved;
  final List<Reply> replies;

  Question({
    this.id = '',
    required this.author,
    required this.avatar,
    required this.title,
    required this.content,
    required this.tag,
    this.votes = 0,
    this.answersCount = 0,
    required this.time,
    this.isUpvoted = false,
    this.isSolved = false,
    required this.replies,
  });

  factory Question.fromJson(Map<String, dynamic> json, String documentId) {
    final rawReplies = json['replies'] as List<dynamic>? ?? [];
    final parsedReplies = rawReplies.map((r) => Reply.fromJson(Map<String, dynamic>.from(r))).toList();

    return Question(
      id: documentId,
      author: json['author'] as String? ?? 'Mahasiswa ITS',
      avatar: json['avatar'] as String? ?? 'M',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      tag: json['tag'] as String? ?? 'Umum',
      votes: json['votes'] as int? ?? 0,
      answersCount: json['answersCount'] as int? ?? 0,
      time: json['time'] as String? ?? 'Baru Saja',
      isUpvoted: json['isUpvoted'] as bool? ?? false,
      isSolved: json['isSolved'] as bool? ?? false,
      replies: parsedReplies,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'author': author,
      'avatar': avatar,
      'title': title,
      'content': content,
      'tag': tag,
      'votes': votes,
      'answersCount': answersCount,
      'time': time,
      'isUpvoted': isUpvoted,
      'isSolved': isSolved,
      'replies': replies.map((r) => r.toJson()).toList(),
    };
  }
}
