String timeAgo(int createdAtMs) {
  final now = DateTime.now();
  final created = DateTime.fromMillisecondsSinceEpoch(createdAtMs);
  final diff = now.difference(created);
  if (diff.inSeconds < 60) return 'Baru Saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays == 1) return 'Kemarin';
  if (diff.inDays < 30) return '${diff.inDays} hari lalu';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} bulan lalu';
  return '${(diff.inDays / 365).floor()} tahun lalu';
}
