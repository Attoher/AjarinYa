import 'package:ajarin_ya/models/question.dart';
import 'package:ajarin_ya/services/supabase_storage_service.dart';
import 'package:ajarin_ya/utils/time_utils.dart';
import 'package:ajarin_ya/viewmodels/auth_view_model.dart';
import 'package:ajarin_ya/viewmodels/question_view_model.dart';
import 'package:ajarin_ya/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:ajarin_ya/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ajarin_ya/widgets/full_screen_image_viewer.dart';

class AnswerQuestionScreen extends StatefulWidget {
  final String? questionId;

  const AnswerQuestionScreen({super.key, this.questionId});

  @override
  State<AnswerQuestionScreen> createState() => _AnswerQuestionScreenState();
}

class _AnswerQuestionScreenState extends State<AnswerQuestionScreen> {
  final _replyController = TextEditingController();
  final _imagePicker = ImagePicker();
  XFile? _selectedReplyImage;
  bool _isSendingReply = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _pickReplyImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Foto Langsung'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final image = await _imagePicker.pickImage(source: source, imageQuality: 80);
    if (image == null || !mounted) return;
    setState(() => _selectedReplyImage = image);
  }

  Future<void> _postReply(QuestionViewModel vm, String authorName, String authorAvatarUrl) async {
    final questionId = widget.questionId;
    if (questionId == null) return;

    final text = _replyController.text.trim();
    if (text.isEmpty && _selectedReplyImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jawaban tidak boleh kosong.')),
      );
      return;
    }

    setState(() => _isSendingReply = true);

    String? imageUrl;
    if (_selectedReplyImage != null) {
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      imageUrl = await SupabaseStorageService.instance
          .uploadReplyImage(tempId, _selectedReplyImage!);
    }

    if (!mounted) return;

    await vm.addReply(
      questionId,
      Reply(
        author: authorName.isNotEmpty ? authorName : 'Pengguna',
        authorAvatarUrl: authorAvatarUrl,
        content: text.isEmpty ? '📷 Lampiran gambar' : text,
        imageUrl: imageUrl,
      ),
    );

    _replyController.clear();
    setState(() {
      _selectedReplyImage = null;
      _isSendingReply = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Jawaban berhasil dipublikasikan.')),
    );
  }

  Future<void> _showEditReplyDialog(
    BuildContext context,
    QuestionViewModel vm,
    Reply reply,
  ) async {
    final controller = TextEditingController(text: reply.content);
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Edit Jawaban'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: InputDecoration(
            labelText: 'Isi jawaban',
            alignLabelWithHint: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              await vm.updateReply(
                widget.questionId!,
                reply.copyWith(content: text),
              );
              if (!context.mounted) return;
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Jawaban berhasil diperbarui.')),
              );
            },
            icon: const Icon(Icons.save),
            label: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Future<void> _confirmDeleteReply(
    BuildContext context,
    QuestionViewModel vm,
    Reply reply,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Tarik Jawaban'),
        content: const Text(
          'Jawaban ini akan dihapus dari diskusi. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await vm.deleteReply(widget.questionId!, reply.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Jawaban berhasil ditarik.')));
  }

  @override
  Widget build(BuildContext context) {
    final questionViewModel = Provider.of<QuestionViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);
    final currentUserDisplayName =
        authViewModel.user?.displayName ?? 'Pengguna';
    final currentUserId = authViewModel.user?.uid ?? '';
    final questionId = widget.questionId;

    if (questionId == null) {
      return _AnswerQuestionPicker(questions: questionViewModel.questions);
    }

    final question = questionViewModel.findQuestion(questionId);

    if (question == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Diskusi Jawaban',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppTheme.primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Text('Pertanyaan tidak ditemukan atau sudah dihapus.'),
        ),
      );
    }

    final isQuestionOwner = question.ownerId.isNotEmpty &&
        question.ownerId == currentUserId;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Diskusi Jawaban',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (isQuestionOwner)
            Tooltip(
              message: question.isSolved ? 'Tandai Belum Terjawab' : 'Tandai Terjawab',
              child: IconButton(
                onPressed: () =>
                    questionViewModel.toggleSolved(questionId),
                icon: Icon(
                  question.isSolved
                      ? Icons.check_circle_rounded
                      : Icons.check_circle_outline_rounded,
                  color: question.isSolved
                      ? Colors.greenAccent.shade400
                      : Colors.white70,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _QuestionDetailCard(question: question),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Jawaban',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text('${question.replies.length}'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (question.replies.isEmpty)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.mark_chat_unread_outlined,
                            size: 46,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Belum ada jawaban. Jadilah yang pertama membantu.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...([...question.replies]..sort((a, b) {
                    if (a.isBest && !b.isBest) return -1;
                    if (!a.isBest && b.isBest) return 1;
                    return b.votes.compareTo(a.votes);
                  })).map(
                    (reply) => _ReplyCard(
                      reply: reply,
                      isQuestionOwner: isQuestionOwner,
                      isReplyAuthor: reply.author == currentUserDisplayName,
                      currentUserId: currentUserId,
                      currentUserDisplayName: currentUserDisplayName,
                      currentUserAvatarUrl: authViewModel.user?.avatarUrl ?? '',
                      questionId: questionId,
                      onBest: () => questionViewModel.toggleBestReply(
                        questionId,
                        reply.id,
                      ),
                      onUpvote: () => questionViewModel.toggleReplyUpvote(
                        questionId,
                        reply,
                      ),
                      onEdit: () => _showEditReplyDialog(
                        context,
                        questionViewModel,
                        reply,
                      ),
                      onDelete: () => _confirmDeleteReply(
                        context,
                        questionViewModel,
                        reply,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedReplyImage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.image_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _selectedReplyImage!.name,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _selectedReplyImage = null),
                            child: const Icon(Icons.close, size: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _isSendingReply ? null : _pickReplyImage,
                        icon: Icon(
                          Icons.image_outlined,
                          color: _selectedReplyImage != null
                              ? AppTheme.primaryColor
                              : Colors.grey.shade600,
                        ),
                        tooltip: 'Lampirkan gambar',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _replyController,
                          enabled: !_isSendingReply,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Tulis solusi, rumus, atau penjelasan...',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _isSendingReply
                          ? const SizedBox(
                              width: 40,
                              height: 40,
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              ),
                            )
                          : IconButton.filled(
                              onPressed: () => _postReply(
                                  questionViewModel,
                                  currentUserDisplayName,
                                  authViewModel.user?.avatarUrl ?? ''),
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                              ),
                              icon: const Icon(Icons.send),
                              tooltip: 'Kirim jawaban',
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerQuestionPicker extends StatelessWidget {
  final List<Question> questions;

  const _AnswerQuestionPicker({required this.questions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Bantu Jawab Soal',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: questions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.question_answer_outlined,
                    size: 56,
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada pertanyaan untuk dijawab.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final question = questions[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    leading: UserAvatar(
                      url: question.authorAvatarUrl,
                      fallback: question.avatar,
                      radius: 20,
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                      fallbackTextColor: AppTheme.primaryDark,
                    ),
                    title: Text(
                      question.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${question.author} • ${question.tag} • ${question.replies.length} jawaban',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppTheme.primaryColor,
                      size: 16,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AnswerQuestionScreen(questionId: question.id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _QuestionDetailCard extends StatelessWidget {
  final Question question;

  const _QuestionDetailCard({required this.question});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                  url: question.authorAvatarUrl,
                  fallback: question.avatar,
                  radius: 20,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  fallbackTextColor: AppTheme.primaryDark,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.author,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${timeAgo(question.createdAtMs)} • ${question.tag}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (question.isSolved)
                  Icon(Icons.verified_rounded, color: Colors.green.shade700),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              question.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              question.content,
              style: TextStyle(color: Colors.grey.shade800, height: 1.45),
            ),
            if ((question.imageUrl ?? '').isNotEmpty) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => FullScreenImageViewer(imageUrl: question.imageUrl!, heroTag: 'qd_${question.id}'),
                    ));
                  },
                  child: Hero(
                    tag: 'qd_${question.id}',
                    child: Image.network(
                      question.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 80,
                        color: AppTheme.primaryColor.withValues(alpha: 0.05),
                        alignment: Alignment.center,
                        child: const Text('Lampiran gambar tidak bisa dimuat'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReplyCard extends StatefulWidget {
  final Reply reply;
  final bool isQuestionOwner;
  final bool isReplyAuthor;
  final String currentUserId;
  final String currentUserDisplayName;
  final String currentUserAvatarUrl;
  final String questionId;
  final VoidCallback onBest;
  final VoidCallback onUpvote;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReplyCard({
    required this.reply,
    required this.isQuestionOwner,
    required this.isReplyAuthor,
    required this.currentUserId,
    required this.currentUserDisplayName,
    required this.currentUserAvatarUrl,
    required this.questionId,
    required this.onBest,
    required this.onUpvote,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_ReplyCard> createState() => _ReplyCardState();
}

class _ReplyCardState extends State<_ReplyCard> {
  bool _showComments = false;
  final _commentController = TextEditingController();
  XFile? _selectedCommentImage;
  bool _isPostingComment = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickCommentImage() async {
    final picker = ImagePicker();
    final image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null || !mounted) return;
    setState(() => _selectedCommentImage = image);
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty && _selectedCommentImage == null) return;
    setState(() => _isPostingComment = true);

    String? imageUrl;
    if (_selectedCommentImage != null) {
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      imageUrl = await SupabaseStorageService.instance
          .uploadCommentImage(tempId, _selectedCommentImage!);
    }

    if (!mounted) return;

    final comment = Comment(
      author: widget.currentUserDisplayName.isNotEmpty
          ? widget.currentUserDisplayName
          : 'Pengguna',
      authorAvatarUrl: widget.currentUserAvatarUrl,
      content: text.isEmpty ? '📷 Lampiran' : text,
      imageUrl: imageUrl,
    );

    await context
        .read<QuestionViewModel>()
        .addComment(widget.questionId, widget.reply.id, comment);

    if (!mounted) return;
    _commentController.clear();
    setState(() {
      _selectedCommentImage = null;
      _isPostingComment = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: widget.reply.isBest
            ? BorderSide(color: Colors.green.shade500, width: 1.5)
            : BorderSide.none,
      ),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: widget.reply.isBest ? 3 : 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                  url: widget.reply.authorAvatarUrl.isNotEmpty
                      ? widget.reply.authorAvatarUrl
                      : null,
                  fallback: widget.reply.author,
                  radius: 15,
                  backgroundColor: widget.reply.isBest
                      ? Colors.green.shade100
                      : Colors.grey.shade200,
                  fallbackTextColor: widget.reply.isBest
                      ? Colors.green.shade900
                      : Colors.black87,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.reply.author,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (widget.isQuestionOwner || widget.isReplyAuthor)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'best') widget.onBest();
                      if (value == 'edit') widget.onEdit();
                      if (value == 'delete') widget.onDelete();
                    },
                    itemBuilder: (context) => [
                      if (widget.isQuestionOwner)
                        PopupMenuItem(
                          value: 'best',
                          child: ListTile(
                            dense: true,
                            leading: Icon(
                              widget.reply.isBest
                                  ? Icons.star
                                  : Icons.star_border,
                            ),
                            title: Text(
                              widget.reply.isBest
                                  ? 'Batalkan terbaik'
                                  : 'Tandai terbaik',
                            ),
                          ),
                        ),
                      if (widget.isReplyAuthor)
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Edit jawaban'),
                          ),
                        ),
                      if (widget.isReplyAuthor)
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.delete_outline, color: Colors.red),
                            title: Text('Tarik jawaban'),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            if (widget.reply.isBest) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Solusi terbaik',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              widget.reply.content,
              style: TextStyle(color: Colors.grey.shade800, height: 1.45),
            ),
            if ((widget.reply.imageUrl ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenImageViewer(
                          imageUrl: widget.reply.imageUrl!,
                          heroTag: 'r_${widget.reply.id}',
                        ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: 'r_${widget.reply.id}',
                    child: Image.network(
                      widget.reply.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 60,
                        color: AppTheme.primaryColor.withValues(alpha: 0.05),
                        alignment: Alignment.center,
                        child: const Text(
                          'Gambar tidak bisa dimuat',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            InkWell(
              onTap: widget.onUpvote,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.thumb_up_alt_outlined,
                      color: Colors.grey.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.reply.votes} Upvotes',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 20, thickness: 0.5, color: Colors.grey.shade200),
            InkWell(
              onTap: () => setState(() => _showComments = !_showComments),
              child: Row(
                children: [
                  Icon(Icons.comment_outlined,
                      size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    widget.reply.comments.isEmpty
                        ? 'Komentar'
                        : '${widget.reply.comments.length} Komentar',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  Icon(
                    _showComments ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
            if (_showComments) ...[
              const SizedBox(height: 8),
              ...widget.reply.comments.map(
                (comment) => _CommentTile(
                  comment: comment,
                  currentUserDisplayName: widget.currentUserDisplayName,
                  onDelete: () => context
                      .read<QuestionViewModel>()
                      .deleteComment(
                          widget.questionId, widget.reply.id, comment.id),
                ),
              ),
              const SizedBox(height: 8),
              if (_selectedCommentImage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.image_outlined,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _selectedCommentImage!.name,
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCommentImage = null),
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  UserAvatar(
                    url: widget.currentUserAvatarUrl.isNotEmpty
                        ? widget.currentUserAvatarUrl
                        : null,
                    fallback: widget.currentUserDisplayName,
                    radius: 12,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: TextField(
                        controller: _commentController,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Tulis komentar...',
                          hintStyle: TextStyle(
                              fontSize: 12, color: Colors.grey.shade400),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 0),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: _isPostingComment ? null : _pickCommentImage,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.image_outlined,
                        size: 18,
                        color: _selectedCommentImage != null
                            ? AppTheme.primaryColor
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _isPostingComment
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : InkWell(
                          onTap: _postComment,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.send_rounded,
                              size: 18,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final String currentUserDisplayName;
  final VoidCallback onDelete;

  const _CommentTile({
    required this.comment,
    required this.currentUserDisplayName,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isAuthor = comment.author == currentUserDisplayName;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            url: comment.authorAvatarUrl.isNotEmpty
                ? comment.authorAvatarUrl
                : null,
            fallback: comment.author,
            radius: 12,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.author,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeAgo(comment.createdAtMs),
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                    const Spacer(),
                    if (isAuthor)
                      GestureDetector(
                        onTap: onDelete,
                        child: Icon(Icons.close,
                            size: 13, color: Colors.grey.shade400),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  comment.content,
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade800),
                ),
                if ((comment.imageUrl ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      comment.imageUrl!,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, e, st) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
