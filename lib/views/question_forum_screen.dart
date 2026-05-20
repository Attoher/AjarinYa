import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ajarin_ya/models/question.dart';
import 'package:ajarin_ya/models/result_state.dart';
import 'package:ajarin_ya/viewmodels/auth_view_model.dart';
import 'package:ajarin_ya/viewmodels/question_view_model.dart';
import 'package:ajarin_ya/views/answer_question_screen.dart';

class QuestionForumScreen extends StatefulWidget {
  const QuestionForumScreen({super.key});

  @override
  State<QuestionForumScreen> createState() => _QuestionForumScreenState();
}

class _QuestionForumScreenState extends State<QuestionForumScreen> {
  final _questionTitleController = TextEditingController();
  final _questionContentController = TextEditingController();
  String _selectedTag = '📚 Fisika';
  final List<String> _tags = ['📚 Fisika', '💻 Flutter', '🔬 Kimia', '📐 Matematika'];
  String _searchQuery = '';

  @override
  void dispose() {
    _questionTitleController.dispose();
    _questionContentController.dispose();
    super.dispose();
  }

  void _showAskQuestionDialog(BuildContext context, QuestionViewModel questionViewModel, String currentUserDisplayName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Icon(Icons.question_answer_outlined, color: Colors.orange.shade800),
                  const SizedBox(width: 8),
                  const Text('Tanyakan Soal Belajar', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Kategori Tag Dropdown
                    Row(
                      children: [
                        const Text('Topik:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedTag,
                              items: _tags
                                  .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12))))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() {
                                    _selectedTag = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _questionTitleController,
                      decoration: InputDecoration(
                        labelText: 'Judul Pertanyaan / Soal',
                        hintText: 'Tulis garis besar kesulitan Anda...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _questionContentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Deskripsi Masalah secara Detail',
                        hintText: 'Tulis detail soal, variabel yang diketahui, dan apa yang ingin ditanyakan...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = _questionTitleController.text.trim();
                    final content = _questionContentController.text.trim();
                    if (title.isNotEmpty && content.isNotEmpty) {
                      final newQuestion = Question(
                        author: currentUserDisplayName.isNotEmpty ? currentUserDisplayName : 'Mahasiswa ITS',
                        avatar: currentUserDisplayName.isNotEmpty ? currentUserDisplayName[0].toUpperCase() : 'M',
                        title: title,
                        content: content,
                        tag: _selectedTag,
                        votes: 0,
                        answersCount: 0,
                        time: 'Baru Saja',
                        isUpvoted: false,
                        isSolved: false,
                        replies: [],
                      );
                      
                      await questionViewModel.createQuestion(newQuestion);
                      
                      _questionTitleController.clear();
                      _questionContentController.clear();
                      if (context.mounted) {
                        Navigator.pop(dialogCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pertanyaan Anda berhasil diterbitkan di forum!')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Tanyakan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final questionViewModel = Provider.of<QuestionViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);
    final currentUserDisplayName = authViewModel.user?.displayName ?? 'Mahasiswa ITS';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Forum Diskusi Soal', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.orange.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => questionViewModel.loadQuestions(),
          )
        ],
      ),
      body: Column(
        children: [
          // Banner Modul Anggota 3
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.orange.shade50,
            child: Row(
              children: [
                Icon(Icons.forum_outlined, color: Colors.orange.shade900),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Modul 3 Aktif (CRUD Firestore): Forum tanya jawab dinamis oleh Anggota 3 (SDG 4).',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade900, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari topik diskusi atau pertanyaan...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ),

          // Questions List
          Expanded(
            child: Consumer<QuestionViewModel>(
              builder: (context, vm, child) {
                final state = vm.state;
                if (state is ResultStateLoading) {
                  return const Center(child: CircularProgressIndicator(color: Colors.orange));
                } else if (state is ResultStateError) {
                  return Center(
                    child: Text('Gagal memuat pertanyaan: ${(state as ResultStateError).message}'),
                  );
                }

                final questions = vm.questions;
                final filteredQuestions = questions.where((q) {
                  return q.title.toLowerCase().contains(_searchQuery) ||
                      q.content.toLowerCase().contains(_searchQuery) ||
                      q.tag.toLowerCase().contains(_searchQuery) ||
                      q.author.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredQuestions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.question_mark_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada pertanyaan yang cocok.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredQuestions.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (ctx, idx) {
                    final q = filteredQuestions[idx];
                    return GestureDetector(
                      onTap: () {
                        // Navigate to Answer Question screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AnswerQuestionScreen(
                              questionId: q.id,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.orange.shade100,
                                    radius: 16,
                                    child: Text(q.avatar, style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(q.author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        Text('${q.time} • ${q.tag}', style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                  if (q.isSolved)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.green.shade700, size: 12),
                                          const SizedBox(width: 4),
                                          Text('Terjawab', style: TextStyle(color: Colors.green.shade700, fontSize: 9, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Hapus Pertanyaan'),
                                          content: const Text('Apakah Anda yakin ingin menghapus pertanyaan ini?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, true),
                                              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                            )
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        await vm.deleteQuestion(q.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Pertanyaan berhasil dihapus.')),
                                          );
                                        }
                                      }
                                    },
                                  )
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                q.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, height: 1.3),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                q.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 12, height: 1.4),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Upvotes button
                                  Row(
                                    children: [
                                      IconButton(
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                        icon: Icon(
                                          Icons.thumb_up_alt,
                                          color: q.isUpvoted ? Colors.orange.shade800 : Colors.grey.shade400,
                                          size: 16,
                                        ),
                                        onPressed: () {
                                          vm.toggleUpvote(q);
                                        },
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${q.votes} Upvotes',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  // Answers count & CTA
                                  Row(
                                    children: [
                                      Icon(Icons.comment_outlined, color: Colors.grey.shade400, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${q.answersCount} Solusi',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(Icons.arrow_forward_ios_rounded, color: Colors.orange.shade800, size: 12),
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
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAskQuestionDialog(context, questionViewModel, currentUserDisplayName),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment),
        label: const Text('Tanya Soal'),
      ),
    );
  }
}

