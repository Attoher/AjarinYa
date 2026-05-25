import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ajarin_ya/models/question.dart';
import 'package:ajarin_ya/viewmodels/auth_view_model.dart';
import 'package:ajarin_ya/viewmodels/question_view_model.dart';

class AnswerQuestionScreen extends StatefulWidget {
  final String? questionId;

  const AnswerQuestionScreen({
    super.key,
    this.questionId,
  });

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

  void _postReply(QuestionViewModel vm, String authorName) async {
    final text = _replyController.text.trim();
    if (text.isNotEmpty && widget.questionId != null) {
      final reply = Reply(
        author: authorName.isNotEmpty ? authorName : 'Mahasiswa ITS',
        content: text,
        votes: 0,
        isBest: false,
      );
      
      await vm.addReply(widget.questionId!, reply);
      
      setState(() {
        _replyController.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solusi Anda berhasil dipublikasikan!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionViewModel = Provider.of<QuestionViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);
    final currentUserDisplayName = authViewModel.user?.displayName ?? 'Mahasiswa ITS';

    final questions = questionViewModel.questions;

    // Mode 1: Browse list of questions to answer (when questionId is null)
    if (widget.questionId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('Bantu Jawab Soal', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.orange.shade800,
          elevation: 0,
          centerTitle: true,
        ),
        body: questions.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.question_answer_outlined, size: 64, color: Colors.orange.shade200),
                    const SizedBox(height: 16),
                    const Text(
                      'Tidak ada pertanyaan saat ini',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black54),
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.orange.shade50,
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_rounded, color: Colors.orange.shade800, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Pilih pertanyaan dari rekan mahasiswa ITS di bawah ini untuk membantu memberikan solusi cerdas!',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFE65100)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: questions.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final q = questions[index];
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 2,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AnswerQuestionScreen(questionId: q.id),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          q.tag,
                                          style: TextStyle(color: Colors.orange.shade900, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      if (q.isSolved)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.check, color: Colors.green.shade700, size: 12),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Terpecahkan',
                                                style: TextStyle(color: Colors.green.shade700, fontSize: 9, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    q.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    q.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: Colors.orange.shade100,
                                            radius: 12,
                                            child: Text(
                                              q.avatar,
                                              style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 9),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            q.author,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.comment_outlined, size: 14, color: Colors.grey.shade500),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${q.replies.length} Jawaban',
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.orange.shade800),
                                        ],
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      );
    }

    // Mode 2: Detailed discussion (when questionId is provided)
    final questionIdx = questions.indexWhere((q) => q.id == widget.questionId);
    
    if (questionIdx == -1) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Diskusi & Jawaban Solusi', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.orange.shade800,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Text('Pertanyaan tidak ditemukan atau telah dihapus.'),
        ),
      );
    }

    final question = questions[questionIdx];
    final replies = question.replies;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Diskusi & Jawaban Solusi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.orange.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CARD PERTANYAAN UTAMA (DETIL)
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    color: Colors.white,
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.orange.shade100,
                                radius: 20,
                                child: Text(question.avatar, style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      question.author,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Diposting ${question.time} • ${question.tag}',
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            question.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            question.content,
                            style: TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.5),
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Daftar Jawaban (${replies.length})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                              ),
                              if (question.isSolved)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.check, color: Colors.green.shade700, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Terpecahkan',
                                        style: TextStyle(color: Colors.green.shade700, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // LIST SOLUSI / DISKUSI
                  replies.isEmpty
                      ? Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.mark_chat_read_outlined, size: 48, color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Belum ada solusi di forum ini.\nJadilah orang pertama yang membantu rekan Anda!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: replies.length,
                          itemBuilder: (ctx, idx) {
                            final reply = replies[idx];
                            final isBest = reply.isBest;

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: isBest
                                    ? BorderSide(color: Colors.green.shade400, width: 1.5)
                                    : BorderSide.none,
                              ),
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: isBest ? 3 : 1,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: isBest ? Colors.green.shade100 : Colors.grey.shade200,
                                              radius: 14,
                                              child: Text(
                                                reply.author.isNotEmpty ? reply.author[0] : 'M',
                                                style: TextStyle(
                                                  color: isBest ? Colors.green.shade900 : Colors.black87,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              reply.author,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            questionViewModel.toggleBestReply(widget.questionId!, idx);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isBest ? Colors.green.shade50 : Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isBest ? Colors.green.shade300 : Colors.grey.shade300,
                                                width: 0.5,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  isBest ? Icons.star : Icons.star_border,
                                                  color: isBest ? Colors.green.shade700 : Colors.grey.shade600,
                                                  size: 12,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  isBest ? 'Solusi Terbaik' : 'Tandai Solusi Terbaik',
                                                  style: TextStyle(
                                                    color: isBest ? Colors.green.shade700 : Colors.grey.shade700,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      reply.content,
                                      style: TextStyle(color: Colors.grey.shade800, fontSize: 12, height: 1.4),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            IconButton(
                                              constraints: const BoxConstraints(),
                                              padding: EdgeInsets.zero,
                                              icon: Icon(Icons.thumb_up_alt_outlined, color: Colors.grey.shade500, size: 14),
                                              onPressed: () {
                                                setState(() {
                                                  reply.votes++;
                                                });
                                                questionViewModel.updateQuestion(question);
                                              },
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${reply.votes} Upvotes',
                                              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                                            ),
                                          ],
                                        ),
                                        // Rating Stars Mock
                                        const Row(
                                          children: [
                                            Icon(Icons.star, color: Colors.amber, size: 12),
                                            Icon(Icons.star, color: Colors.amber, size: 12),
                                            Icon(Icons.star, color: Colors.amber, size: 12),
                                            Icon(Icons.star, color: Colors.amber, size: 12),
                                            Icon(Icons.star, color: Colors.amber, size: 12),
                                          ],
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
          
          // RESPONSE EDITOR COLUMN (KOLOM MENULIS SOLUSI)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    decoration: InputDecoration(
                      hintText: 'Tulis solusi atau jawaban membantu...',
                      hintStyle: const TextStyle(fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _postReply(questionViewModel, currentUserDisplayName),
                  child: CircleAvatar(
                    backgroundColor: Colors.orange.shade800,
                    radius: 20,
                    child: const Icon(Icons.send, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
