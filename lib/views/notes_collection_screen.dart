import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ajarin_ya/models/note.dart';
import 'package:ajarin_ya/models/result_state.dart';
import 'package:ajarin_ya/models/result_state.dart';
import 'package:ajarin_ya/services/supabase_storage_service.dart';
import 'package:ajarin_ya/viewmodels/notes_view_model.dart';
import 'package:ajarin_ya/widgets/full_screen_image_viewer.dart';

class NotesCollectionScreen extends StatefulWidget {
  const NotesCollectionScreen({super.key});

  @override
  State<NotesCollectionScreen> createState() => _NotesCollectionScreenState();
}

class _NotesCollectionScreenState extends State<NotesCollectionScreen> {
  final List<String> _folders = ['Semua Catatan', 'Kalkulus II', 'Struktur Data', 'UI/UX Design', 'Umum'];
  String _selectedFolder = 'Semua Catatan';
  String _searchQuery = '';

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _newNoteFolder = 'Umum';
  final _imagePicker = ImagePicker();
  XFile? _selectedNoteImage;
  bool _isSavingNote = false;

  IconData _folderIcon(String folder) {
    switch (folder) {
      case 'Kalkulus II': return Icons.architecture;
      case 'Struktur Data': return Icons.code;
      case 'UI/UX Design': return Icons.palette;
      case 'Umum': return Icons.menu_book;
      default: return Icons.folder;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _showAddNoteBottomSheet(NotesViewModel notesVm) {
    _selectedNoteImage = null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Buat Catatan Baru',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetCtx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Kategori:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _newNoteFolder,
                              items: _folders
                                  .where((f) => f != 'Semua Catatan')
                                  .map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 12))))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setSheetState(() => _newNoteFolder = val);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Judul Catatan',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _contentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Tulis Rangkuman Belajar...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Image picker row
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final source = await showDialog<ImageSource>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Pilih Sumber Gambar', style: TextStyle(fontSize: 16)),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.photo_library),
                                        title: const Text('Galeri Foto'),
                                        onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.photo_camera),
                                        title: const Text('Kamera'),
                                        onTap: () => Navigator.of(context).pop(ImageSource.camera),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                            
                            if (source == null) return;

                            final image = await _imagePicker.pickImage(
                              source: source,
                              imageQuality: 80,
                            );
                            if (image != null) {
                              setSheetState(() => _selectedNoteImage = image);
                            }
                          },
                          icon: const Icon(Icons.image_outlined, size: 16),
                          label: const Text('Lampirkan Gambar', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        if (_selectedNoteImage != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedNoteImage!.name,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setSheetState(() => _selectedNoteImage = null),
                            child: const Icon(Icons.close, size: 16, color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSavingNote
                            ? null
                            : () async {
                                if (_titleController.text.trim().isEmpty) return;
                                setSheetState(() => _isSavingNote = true);

                                String? imageUrl;
                                if (_selectedNoteImage != null) {
                                  final tempId = DateTime.now().millisecondsSinceEpoch.toString();
                                  imageUrl = await SupabaseStorageService.instance
                                      .uploadNoteImage(tempId, _selectedNoteImage!);
                                }

                                final colorOptions = [
                                  0xFFFFF8E1,
                                  0xFFE3F2FD,
                                  0xFFE8F5E9,
                                  0xFFE0F2F1,
                                ];
                                final selectedColor = (colorOptions..shuffle()).first;

                                final newNote = Note(
                                  title: _titleController.text.trim(),
                                  folder: _newNoteFolder,
                                  content: _contentController.text.trim().isEmpty
                                      ? ' '
                                      : _contentController.text.trim(),
                                  date: '${DateTime.now().day} ${_monthName(DateTime.now().month)} ${DateTime.now().year}',
                                  isBookmarked: false,
                                  colorValue: selectedColor,
                                  imageUrl: imageUrl,
                                );

                                notesVm.createNote(newNote);

                                _titleController.clear();
                                _contentController.clear();
                                setSheetState(() {
                                  _selectedNoteImage = null;
                                  _isSavingNote = false;
                                });
                                if (context.mounted) Navigator.pop(sheetCtx);
                                if (mounted) {
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    const SnackBar(content: Text('Catatan berhasil ditambahkan!')),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isSavingNote
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text('Simpan Catatan', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _monthName(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return names[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final notesVm = Provider.of<NotesViewModel>(context);

    // Filter notes based on folder & search query
    final filteredNotes = notesVm.notes.where((note) {
      final matchesFolder = _selectedFolder == 'Semua Catatan' || note.folder == _selectedFolder;
      final matchesSearch = note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note.content.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFolder && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Arsip Catatan & Bookmark', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.teal.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [

          // Search & Filter Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari catatan atau rangkuman...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                const SizedBox(height: 12),
                
                // Horizontal Folder Toggles
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _folders.length,
                    itemBuilder: (ctx, idx) {
                      final folder = _folders[idx];
                      final isSelected = _selectedFolder == folder;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (folder != 'Semua Catatan') ...[Icon(_folderIcon(folder), size: 14, color: isSelected ? Colors.white : Colors.black54), const SizedBox(width: 4)],
                              Text(folder, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 11)),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFolder = folder;
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: Colors.teal.shade700,
                          side: BorderSide(color: isSelected ? Colors.teal.shade700 : Colors.grey.shade300),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Notes List
          Expanded(
            child: notesVm.state is ResultStateLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                : filteredNotes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notes_rounded, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Tidak ada catatan ditemukan.',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                        itemCount: filteredNotes.length,
                        itemBuilder: (ctx, idx) {
                          final note = filteredNotes[idx];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Color(note.colorValue),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.01),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        note.folder,
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                      icon: Icon(
                                        note.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                        color: note.isBookmarked ? Colors.orange : Colors.grey.shade600,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        notesVm.toggleBookmark(note);
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  note.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.2),
                                ),
                                const SizedBox(height: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        note.content,
                                        maxLines: (note.imageUrl ?? '').isNotEmpty ? 2 : 4,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: Colors.grey.shade700, fontSize: 11, height: 1.3),
                                      ),
                                      if ((note.imageUrl ?? '').isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.push(context, MaterialPageRoute(
                                                builder: (_) => FullScreenImageViewer(imageUrl: note.imageUrl!, heroTag: 'n_${note.id}'),
                                              ));
                                            },
                                            child: Hero(
                                              tag: 'n_${note.id}',
                                              child: Image.network(
                                                note.imageUrl!,
                                                height: 60,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, e, s) => const SizedBox.shrink(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      note.date,
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 9),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        notesVm.deleteNote(note.id);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Catatan dihapus.')),
                                        );
                                      },
                                      child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 14),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          );
                        },
                      );
                    }),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton.extended(
          heroTag: 'notes_fab',
          onPressed: () => _showAddNoteBottomSheet(notesVm),
          backgroundColor: Colors.teal.shade700,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.create),
          label: const Text('Catat Materi'),
        ),
      ),
    );
  }
}
