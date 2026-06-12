import 'package:ajarin_ya/models/question.dart';
import 'package:ajarin_ya/models/result_state.dart';
import 'package:ajarin_ya/utils/time_utils.dart';
import 'package:ajarin_ya/viewmodels/auth_view_model.dart';
import 'package:ajarin_ya/viewmodels/question_view_model.dart';
import 'package:ajarin_ya/views/answer_question_screen.dart';
import 'package:ajarin_ya/services/supabase_storage_service.dart';
import 'package:ajarin_ya/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:ajarin_ya/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ajarin_ya/widgets/full_screen_image_viewer.dart';

class QuestionForumScreen extends StatefulWidget {
  const QuestionForumScreen({super.key});

  @override
  State<QuestionForumScreen> createState() => _QuestionForumScreenState();
}

class _QuestionForumScreenState extends State<QuestionForumScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final ImagePicker _imagePicker = ImagePicker();
  static bool get _useFullPageQuestionForm => true;
  String? _lastGroupId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final activeGroupId = context.read<AuthViewModel>().user?.activeGroupId;
    if (activeGroupId != _lastGroupId) {
      _lastGroupId = activeGroupId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<QuestionViewModel>().loadQuestions(activeGroupId);
      });
    }
  }

  static const List<String> _tags = [
    'Fisika',
    'Flutter',
    'Kimia',
    'Matematika',
    'Bahasa Inggris',
    'Umum',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showQuestionForm({
    required BuildContext context,
    required QuestionViewModel vm,
    required String currentUserDisplayName,
    Question? existingQuestion,
  }) async {
    if (_useFullPageQuestionForm) {
      await _showQuestionFormPage(
        context: context,
        vm: vm,
        currentUserDisplayName: currentUserDisplayName,
        existingQuestion: existingQuestion,
      );
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final titleController = TextEditingController(
      text: existingQuestion?.title ?? '',
    );
    final contentController = TextEditingController(
      text: existingQuestion?.content ?? '',
    );
    final imageUrlController = TextEditingController(
      text: existingQuestion?.imageUrl ?? '',
    );
    var selectedTag = existingQuestion?.tag ?? _tags.first;
    XFile? selectedImage;
    var isUploadingImage = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogBuildContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Row(
                children: [
                  Icon(
                    existingQuestion == null
                        ? Icons.add_comment_outlined
                        : Icons.edit_note,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      existingQuestion == null ? 'Posting Soal' : 'Edit Soal',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedTag,
                      decoration: InputDecoration(
                        labelText: 'Topik',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _tags
                          .map(
                            (tag) =>
                                DropdownMenuItem(value: tag, child: Text(tag)),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedTag = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Judul pertanyaan',
                        hintText: 'Contoh: Cara debug Provider di Flutter',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: contentController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Detail soal',
                        hintText:
                            'Tulis konteks, error, rumus, atau bagian yang belum paham.',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: imageUrlController,
                      decoration: InputDecoration(
                        labelText: 'URL gambar soal (opsional)',
                        hintText: 'URL gambar dari Supabase (opsional)',
                        prefixIcon: const Icon(Icons.image_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isUploadingImage
                                ? null
                                : () async {
                                    final image = await _imagePicker.pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 78,
                                    );
                                    if (image == null) return;
                                    setDialogState(() => selectedImage = image);
                                  },
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Galeri'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isUploadingImage
                                ? null
                                : () async {
                                    final image = await _imagePicker.pickImage(
                                      source: ImageSource.camera,
                                      imageQuality: 78,
                                      preferredCameraDevice: CameraDevice.front,
                                    );
                                    if (image == null) return;
                                    setDialogState(() => selectedImage = image);
                                  },
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('Kamera'),
                          ),
                        ),
                      ],
                    ),
                    if (selectedImage != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.attach_file,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              selectedImage!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Batal'),
                ),
                ElevatedButton.icon(
                  onPressed: isUploadingImage
                      ? null
                      : () async {
                          final title = titleController.text.trim();
                          final content = contentController.text.trim();
                          if (title.isEmpty || content.isEmpty) {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Judul dan detail soal wajib diisi.',
                                ),
                              ),
                            );
                            return;
                          }

                          var imageUrl = imageUrlController.text.trim();
                          if (selectedImage != null) {
                            setDialogState(() => isUploadingImage = true);
                            final uploadedUrl = await _uploadQuestionImage(
                              selectedImage!,
                            );
                            if (dialogBuildContext.mounted) {
                              setDialogState(() => isUploadingImage = false);
                            }
                            if (uploadedUrl != null) imageUrl = uploadedUrl;
                          }

                          final now = DateTime.now().millisecondsSinceEpoch;
                          final question =
                              existingQuestion?.copyWith(
                                title: title,
                                content: content,
                                tag: selectedTag,
                                imageUrl: imageUrl.isEmpty ? null : imageUrl,
                                updatedAtMs: now,
                              ) ??
                              Question(
                                author: currentUserDisplayName.isNotEmpty
                                    ? currentUserDisplayName
                                    : 'Pengguna',
                                avatar: currentUserDisplayName.isNotEmpty
                                    ? currentUserDisplayName[0].toUpperCase()
                                    : 'M',
                                title: title,
                                content: content,
                                tag: selectedTag,
                                imageUrl: imageUrl.isEmpty ? null : imageUrl,
                                time: 'Baru Saja',
                                createdAtMs: now,
                                updatedAtMs: now,
                                replies: [],
                              );

                          if (!dialogBuildContext.mounted) return;
                          Navigator.pop(dialogCtx);
                          if (existingQuestion == null) {
                            await vm.createQuestion(question);
                          } else {
                            await vm.updateQuestion(question);
                          }

                          if (!context.mounted) return;
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                existingQuestion == null
                                    ? 'Pertanyaan berhasil diposting.'
                                    : 'Pertanyaan berhasil diperbarui.',
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  icon: Icon(
                    existingQuestion == null ? Icons.send : Icons.save,
                  ),
                  label: Text(
                    isUploadingImage
                        ? 'Upload...'
                        : existingQuestion == null
                        ? 'Posting'
                        : 'Simpan',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    contentController.dispose();
    imageUrlController.dispose();
  }

  Future<String?> _uploadQuestionImage(XFile image) async {
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final url = await SupabaseStorageService.instance
        .uploadQuestionImage(tempId, image);
    if (url == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Upload gambar gagal. Pertanyaan tetap diposting tanpa foto.',
          ),
        ),
      );
    }
    return url;
  }

  Future<void> _showQuestionFormPage({
    required BuildContext context,
    required QuestionViewModel vm,
    required String currentUserDisplayName,
    Question? existingQuestion,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final result = await Navigator.of(context).push<_QuestionFormResult>(
      MaterialPageRoute(
        builder: (_) => _QuestionFormPage(
          tags: _tags,
          currentUserDisplayName: currentUserDisplayName,
          existingQuestion: existingQuestion,
        ),
      ),
    );

    if (!context.mounted || result == null) return;

    final authVm = context.read<AuthViewModel>();
    final groupId = authVm.user?.activeGroupId;
    final currentUid = authVm.user?.uid ?? '';

    var question = (groupId != null && groupId.isNotEmpty)
        ? result.question.copyWith(groupId: groupId)
        : result.question;

    if (existingQuestion == null) {
      question = question.copyWith(
        ownerId: question.ownerId.isEmpty ? currentUid : question.ownerId,
        authorAvatarUrl: authVm.user?.avatarUrl ?? '',
      );
    }

    if (existingQuestion == null) {
      await vm.createQuestion(question);
    } else {
      await vm.updateQuestion(question);
    }

    if (!context.mounted) return;
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(
          result.skippedLocalImage
              ? 'Pertanyaan tersimpan. Foto lokal belum tersimpan karena upload Storage gagal atau belum aktif.'
              : existingQuestion == null
              ? 'Pertanyaan berhasil diposting.'
              : 'Pertanyaan berhasil diperbarui.',
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    QuestionViewModel vm,
    Question question,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pertanyaan'),
        content: const Text(
          'Pertanyaan dan semua jawabannya akan dihapus. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await vm.deleteQuestion(question.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pertanyaan berhasil dihapus.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questionViewModel = context.read<QuestionViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final currentUserDisplayName = authVm.user?.displayName ?? 'Pengguna';
    final currentUserId = authVm.user?.uid ?? '';
    final activeGroupId = authVm.user?.activeGroupId;

    if (activeGroupId == null || activeGroupId.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Forum Diskusi Soal',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: AppTheme.primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group_off, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('Silakan pilih atau gabung grup terlebih dahulu',
                  style: TextStyle(fontSize: 16)),
              const Text('untuk melihat forum diskusi.',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Forum Diskusi Soal',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => questionViewModel.loadQuestions(activeGroupId),
          ),
        ],
      ),
      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari judul, topik, isi, atau penulis...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          Expanded(
            child: Consumer<QuestionViewModel>(
              builder: (context, vm, child) {
                final state = vm.state;
                if (state is ResultStateLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  );
                }
                if (state is ResultStateError<List<Question>>) {
                  return Center(
                    child: Text('Gagal memuat forum: ${state.message}'),
                  );
                }

                final questions = vm.questions.where((q) {
                  final haystack =
                      '${q.title} ${q.content} ${q.tag} ${q.author}'
                          .toLowerCase();
                  return haystack.contains(_searchQuery);
                }).toList();

                if (questions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.question_answer_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Belum ada pertanyaan yang cocok.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
                  itemCount: questions.length,
                  itemBuilder: (ctx, idx) {
                    final question = questions[idx];
                    return _QuestionCard(
                      question: question,
                      currentUserId: currentUserId,
                      currentUserDisplayName: currentUserDisplayName,
                      onOpen: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AnswerQuestionScreen(questionId: question.id),
                          ),
                        );
                      },
                      onEdit: () => _showQuestionForm(
                        context: context,
                        vm: vm,
                        currentUserDisplayName: currentUserDisplayName,
                        existingQuestion: question,
                      ),
                      onDelete: () => _confirmDelete(context, vm, question),
                      onUpvote: () => vm.toggleUpvote(question),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton.extended(
          heroTag: 'question_fab',
          onPressed: () => _showQuestionForm(
            context: context,
            vm: questionViewModel,
            currentUserDisplayName: currentUserDisplayName,
          ),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_comment),
          label: const Text('Tanya Soal'),
        ),
      ),
    );
  }
}

class _QuestionFormResult {
  final Question question;
  final bool skippedLocalImage;

  const _QuestionFormResult({
    required this.question,
    required this.skippedLocalImage,
  });
}

class _QuestionFormPage extends StatefulWidget {
  final List<String> tags;
  final String currentUserDisplayName;
  final Question? existingQuestion;

  const _QuestionFormPage({
    required this.tags,
    required this.currentUserDisplayName,
    this.existingQuestion,
  });

  @override
  State<_QuestionFormPage> createState() => _QuestionFormPageState();
}

class _QuestionFormPageState extends State<_QuestionFormPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _imagePicker = ImagePicker();

  late String _selectedTag;
  XFile? _selectedImage;
  bool _isSubmitting = false;

  bool get _isEditing => widget.existingQuestion != null;

  @override
  void initState() {
    super.initState();
    final question = widget.existingQuestion;
    _selectedTag = question?.tag ?? widget.tags.first;
    _titleController.text = question?.title ?? '';
    _contentController.text = question?.content ?? '';
    if (question?.imageUrl != null) _selectedImage = null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 78,
      preferredCameraDevice: CameraDevice.front,
    );
    if (image == null || !mounted) return;
    setState(() => _selectedImage = image);
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    var imageUrl = widget.existingQuestion?.imageUrl ?? '';

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan detail soal wajib diisi.')),
      );
      return;
    }

    var skippedLocalImage = false;
    if (_selectedImage != null) {
      setState(() => _isSubmitting = true);
      final uploadedUrl = await _uploadSelectedImage(_selectedImage!);
      if (!mounted) return;
      if (uploadedUrl != null) {
        imageUrl = uploadedUrl;
      } else {
        skippedLocalImage = true;
      }
      setState(() => _isSubmitting = false);
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final question =
        widget.existingQuestion?.copyWith(
          title: title,
          content: content,
          tag: _selectedTag,
          imageUrl: imageUrl.isEmpty ? null : imageUrl,
          updatedAtMs: now,
        ) ??
        Question(
          author: widget.currentUserDisplayName.isNotEmpty
              ? widget.currentUserDisplayName
              : 'Pengguna',
          avatar: widget.currentUserDisplayName.isNotEmpty
              ? widget.currentUserDisplayName[0].toUpperCase()
              : 'M',
          title: title,
          content: content,
          tag: _selectedTag,
          imageUrl: imageUrl.isEmpty ? null : imageUrl,
          time: 'Baru Saja',
          createdAtMs: now,
          updatedAtMs: now,
          replies: [],
        );

    Navigator.pop(
      context,
      _QuestionFormResult(
        question: question,
        skippedLocalImage: skippedLocalImage,
      ),
    );
  }

  Future<String?> _uploadSelectedImage(XFile image) async {
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final url = await SupabaseStorageService.instance
        .uploadQuestionImage(tempId, image);
    if (url == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Upload gambar gagal, posting dilanjutkan tanpa foto.',
          ),
        ),
      );
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Soal' : 'Posting Soal',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedTag,
              decoration: InputDecoration(
                labelText: 'Topik',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: widget.tags
                  .map((tag) => DropdownMenuItem(value: tag, child: Text(tag)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedTag = value);
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Judul pertanyaan',
                hintText: 'Contoh: Cara debug Provider di Flutter',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _contentController,
              minLines: 5,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: 'Detail soal',
                hintText:
                    'Tulis konteks, error, rumus, atau bagian yang belum paham.',
                alignLabelWithHint: true,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galeri'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Kamera'),
                  ),
                ),
              ],
            ),
            if (_selectedImage != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.attach_file,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _selectedImage!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  icon: Icon(_isEditing ? Icons.save : Icons.send),
                  label: Text(
                    _isSubmitting
                        ? 'Upload...'
                        : _isEditing
                        ? 'Simpan'
                        : 'Posting',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final Question question;
  final String currentUserId;
  final String currentUserDisplayName;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onUpvote;

  const _QuestionCard({
    required this.question,
    required this.currentUserId,
    required this.currentUserDisplayName,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    required this.onUpvote,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1.5,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  UserAvatar(
                    url: question.authorAvatarUrl,
                    fallback: question.avatar,
                    radius: 17,
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${timeAgo(question.createdAtMs)} • ${question.tag}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (question.isSolved)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: const Text('Terjawab'),
                      avatar: Icon(
                        Icons.check_circle,
                        color: Colors.green.shade700,
                        size: 16,
                      ),
                      labelStyle: TextStyle(
                        color: Colors.green.shade800,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      backgroundColor: Colors.green.shade50,
                      side: BorderSide.none,
                    ),
                  if (question.ownerId == currentUserId ||
                      (question.ownerId.isEmpty && question.author == currentUserDisplayName))
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Edit soal'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            title: Text('Hapus soal'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                question.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                question.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              if ((question.imageUrl ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => FullScreenImageViewer(imageUrl: question.imageUrl!, heroTag: 'q_${question.id}'),
                      ));
                    },
                    child: Hero(
                      tag: 'q_${question.id}',
                      child: Image.network(
                        question.imageUrl!,
                        height: 130,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 64,
                          color: AppTheme.primaryColor.withValues(alpha: 0.05),
                          alignment: Alignment.center,
                          child: const Text('Lampiran gambar tidak bisa dimuat'),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  InkWell(
                    onTap: onUpvote,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            question.isUpvoted
                                ? Icons.thumb_up_alt
                                : Icons.thumb_up_alt_outlined,
                            color: question.isUpvoted
                                ? AppTheme.primaryColor
                                : Colors.grey.shade600,
                            size: 17,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${question.votes} Upvotes',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.comment_outlined,
                    color: Colors.grey.shade500,
                    size: 17,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${question.answersCount} Jawaban',
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppTheme.primaryColor,
                    size: 13,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
