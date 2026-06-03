import 'package:ajarin_ya/models/question.dart';
import 'package:ajarin_ya/viewmodels/auth_view_model.dart';
import 'package:ajarin_ya/viewmodels/question_view_model.dart';
import 'package:flutter/material.dart';
import 'package:ajarin_ya/theme/app_theme.dart';
import 'package:provider/provider.dart';

class AnswerQuestionScreen extends StatefulWidget {
  final String? questionId;

  const AnswerQuestionScreen({super.key, this.questionId});

  @override
  State<AnswerQuestionScreen> createState() => _AnswerQuestionScreenState();
}

class _AnswerQuestionScreenState extends State<AnswerQuestionScreen> {
  final _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _postReply(QuestionViewModel vm, String authorName) async {
    final questionId = widget.questionId;
    if (questionId == null) return;

    final text = _replyController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jawaban tidak boleh kosong.')),
      );
      return;
    }

    await vm.addReply(
      questionId,
      Reply(
        author: authorName.isNotEmpty ? authorName : 'Pengguna',
        content: text,
      ),
    );

    _replyController.clear();
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

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Diskusi Jawaban',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
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
                  ...question.replies.map(
                    (reply) => _ReplyCard(
                      reply: reply,
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
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
                  IconButton.filled(
                    onPressed: () =>
                        _postReply(questionViewModel, currentUserDisplayName),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    icon: const Icon(Icons.send),
                    tooltip: 'Kirim jawaban',
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
                    color: AppTheme.primaryColor.withOpacity(0.2),
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
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Text(
                        question.avatar,
                        style: TextStyle(
                          color: AppTheme.primaryDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    question.avatar,
                    style: TextStyle(
                      color: AppTheme.primaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                        '${question.time} • ${question.tag}',
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
                child: Image.network(
                  question.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 80,
                    color: AppTheme.primaryColor.withOpacity(0.05),
                    alignment: Alignment.center,
                    child: const Text('Lampiran gambar tidak bisa dimuat'),
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

class _ReplyCard extends StatelessWidget {
  final Reply reply;
  final VoidCallback onBest;
  final VoidCallback onUpvote;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReplyCard({
    required this.reply,
    required this.onBest,
    required this.onUpvote,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: reply.isBest
            ? BorderSide(color: Colors.green.shade500, width: 1.5)
            : BorderSide.none,
      ),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: reply.isBest ? 3 : 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: reply.isBest
                      ? Colors.green.shade100
                      : Colors.grey.shade200,
                  child: Text(
                    reply.author.isNotEmpty
                        ? reply.author[0].toUpperCase()
                        : 'M',
                    style: TextStyle(
                      color: reply.isBest
                          ? Colors.green.shade900
                          : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reply.author,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'best') onBest();
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'best',
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          reply.isBest ? Icons.star : Icons.star_border,
                        ),
                        title: Text(
                          reply.isBest ? 'Batalkan terbaik' : 'Tandai terbaik',
                        ),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit jawaban'),
                      ),
                    ),
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
            if (reply.isBest) ...[
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
              reply.content,
              style: TextStyle(color: Colors.grey.shade800, height: 1.45),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: onUpvote,
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
                      '${reply.votes} Upvotes',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
