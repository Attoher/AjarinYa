import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ajarin_ya/models/note.dart';
import 'package:ajarin_ya/models/result_state.dart';
import 'package:ajarin_ya/viewmodels/notes_view_model.dart';

class NotesCollectionScreen extends StatefulWidget {
  const NotesCollectionScreen({super.key});

  @override
  State<NotesCollectionScreen> createState() => _NotesCollectionScreenState();
}

class _NotesCollectionScreenState extends State<NotesCollectionScreen> {
  final List<String> _folders = ['Semua Catatan', '📐 Kalkulus II', '💻 Struktur Data', '🎨 UI/UX Design', '📚 Umum'];
  String _selectedFolder = 'Semua Catatan';
  String _searchQuery = '';

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _newNoteFolder = '📚 Umum';

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _showAddNoteBottomSheet(NotesViewModel notesVm) {
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
                    // Dropdown Pilihan Kategori
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
                                  setSheetState(() {
                                    _newNoteFolder = val;
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
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_titleController.text.trim().isNotEmpty && _contentController.text.trim().isNotEmpty) {
                            // Assign a random pretty pastel color
                            final colorOptions = [
                              0xFFFFF8E1, // amber.shade50
                              0xFFE3F2FD, // blue.shade50
                              0xFFE8F5E9, // green.shade50
                              0xFFF3E5F5, // purple.shade50
                              0xFFE0F2F1, // teal.shade50
                            ];
                            final selectedColor = (colorOptions..shuffle()).first;

                            final newNote = Note(
                              title: _titleController.text.trim(),
                              folder: _newNoteFolder,
                              content: _contentController.text.trim(),
                              date: '20 Mei 2026',
                              isBookmarked: false,
                              colorValue: selectedColor,
                            );

                            notesVm.createNote(newNote);

                            _titleController.clear();
                            _contentController.clear();
                            Navigator.pop(sheetCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Catatan berhasil ditambahkan ke koleksi Anda!')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Simpan Catatan', style: TextStyle(fontWeight: FontWeight.bold)),
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
          // Banner Modul Anggota 2
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.teal.shade50,
            child: Row(
              children: [
                Icon(Icons.collections_bookmark, color: Colors.teal.shade800),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Modul 2 Kelompok: Tempat penyimpanan rangkuman & koleksi materi belajar Anda terhubung ke Cloud Firestore.',
                    style: TextStyle(fontSize: 12, color: Colors.teal.shade900, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          
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
                          label: Text(folder, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 11)),
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
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
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
                              border: Border.all(color: Colors.black.withOpacity(0.04)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.01),
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
                                        color: Colors.white.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        note.folder.split(' ').last,
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
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
                                  child: Text(
                                    note.content,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.grey.shade700, fontSize: 11, height: 1.3),
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
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddNoteBottomSheet(notesVm),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.create),
        label: const Text('Catat Materi'),
      ),
    );
  }
}
