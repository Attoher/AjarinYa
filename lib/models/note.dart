class Note {
  String id;
  final String title;
  final String folder;
  final String content;
  final String date;
  bool isBookmarked;
  final int colorValue;
  final String ownerId;

  Note({
    this.id = '',
    required this.title,
    required this.folder,
    required this.content,
    required this.date,
    this.isBookmarked = false,
    required this.colorValue,
    this.ownerId = '',
  });

  factory Note.fromJson(Map<String, dynamic> json, String documentId) {
    return Note(
      id: documentId,
      title: json['title'] as String? ?? '',
      folder: json['folder'] as String? ?? 'Umum',
      content: json['content'] as String? ?? '',
      date: json['date'] as String? ?? '',
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      colorValue: json['colorValue'] as int? ?? 0xFFE0F2F1, // Teal default color value
      ownerId: json['ownerId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'folder': folder,
      'content': content,
      'date': date,
      'isBookmarked': isBookmarked,
      'colorValue': colorValue,
      'ownerId': ownerId,
    };
  }
}
