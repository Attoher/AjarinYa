import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ajarin_ya/models/note.dart';
import 'package:ajarin_ya/models/result_state.dart';
import 'package:ajarin_ya/viewmodels/notes_view_model.dart';
import 'package:ajarin_ya/widgets/full_screen_image_viewer.dart';
import 'package:ajarin_ya/views/note_editor_screen.dart';

class NotesCollectionScreen extends StatefulWidget {
  const NotesCollectionScreen({super.key});

  @override
  State<NotesCollectionScreen> createState() => _NotesCollectionScreenState();
}

class _NotesCollectionScreenState extends State<NotesCollectionScreen> {
  String _selectedFolder = 'Semua Catatan';
  String _searchQuery = '';

  IconData _folderIcon(String folder) {
    switch (folder) {
      case 'Kalkulus II': return Icons.architecture;
      case 'Struktur Data': return Icons.code;
      case 'UI/UX Design': return Icons.palette;
      case 'Umum': return Icons.menu_book;
      default: return Icons.folder;
    }
  }

  void _showAddFolderDialog(NotesViewModel notesVm) {
    final folderController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Folder Baru'),
        content: TextField(
          controller: folderController,
          decoration: const InputDecoration(hintText: 'Nama folder...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              if (folderController.text.trim().isNotEmpty) {
                notesVm.addFolder(folderController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesVm = Provider.of<NotesViewModel>(context);

    final foldersList = notesVm.folders.isEmpty
        ? ['Semua Catatan', 'Kalkulus II', 'Struktur Data', 'UI/UX Design', 'Umum']
        : notesVm.folders;

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
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: () => _showAddFolderDialog(notesVm),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
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
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: foldersList.length,
                    itemBuilder: (ctx, idx) {
                      final folder = foldersList[idx];
                      final isSelected = _selectedFolder == folder;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          onLongPress: () {
                            if (folder != 'Semua Catatan' && folder != 'Umum') {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Hapus Folder'),
                                  content: Text('Apakah kamu yakin ingin menghapus folder "$folder"?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                                    TextButton(
                                      onPressed: () {
                                        notesVm.deleteFolder(folder);
                                        if (_selectedFolder == folder) {
                                          setState(() => _selectedFolder = 'Semua Catatan');
                                        }
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          child: ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (folder != 'Semua Catatan') ...[
                                  Icon(_folderIcon(folder), size: 14, color: isSelected ? Colors.white : Colors.black54),
                                  const SizedBox(width: 4)
                                ],
                                Text(folder, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 11)),
                              ],
                            ),
                            selected: isSelected,
                            onSelected: (selected) => setState(() => _selectedFolder = folder),
                            backgroundColor: Colors.white,
                            selectedColor: Colors.teal.shade700,
                            side: BorderSide(color: isSelected ? Colors.teal.shade700 : Colors.grey.shade300),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
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
                  Text('Tidak ada catatan ditemukan.', style: TextStyle(color: Colors.grey.shade600)),
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

                      return GestureDetector(
                        onTap: () async {
                          // 1. KUNCI PERBAIKAN: Ambil ScaffoldMessenger sebelum Navigator dijalankan
                          final messenger = ScaffoldMessenger.of(context);

                          final isUpdated = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NoteEditorScreen(note: note),
                            ),
                          );

                          // 2. KUNCI PERBAIKAN: Gunakan addPostFrameCallback agar dijalankan di frame setelah refresh selesai
                          if (isUpdated == true) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              messenger.removeCurrentSnackBar();
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Catatan berhasil diperbarui!'),
                                  backgroundColor: Colors.teal,
                                ),
                              );
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Color(note.colorValue),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
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
                                    onPressed: () => notesVm.toggleBookmark(note),
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
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => FullScreenImageViewer(
                                                  imageUrl: note.imageUrl!,
                                                  heroTag: 'n_${note.id}',
                                                ),
                                              ),
                                            );
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
                                  Text(note.date, style: TextStyle(color: Colors.grey.shade500, fontSize: 9)),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () async {
                                          // KUNCI PERBAIKAN DI AREA TOMBOL PENSIL
                                          final messenger = ScaffoldMessenger.of(context);

                                          final isUpdated = await Navigator.push<bool>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => NoteEditorScreen(note: note),
                                            ),
                                          );

                                          if (isUpdated == true) {
                                            WidgetsBinding.instance.addPostFrameCallback((_) {
                                              messenger.removeCurrentSnackBar();
                                              messenger.showSnackBar(
                                                const SnackBar(
                                                  content: Text('Catatan berhasil diperbarui!'),
                                                  backgroundColor: Colors.teal,
                                                ),
                                              );
                                            });
                                          }
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.only(right: 12),
                                          child: Icon(Icons.edit_outlined, color: Colors.blue, size: 14),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          final messenger = ScaffoldMessenger.of(context);
                                          final success = await notesVm.deleteNote(note.id);

                                          if (!mounted) return;
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(success ? 'Catatan dihapus.' : 'Gagal menghapus catatan.'),
                                            ),
                                          );
                                        },
                                        child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 14),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
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
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);

            final emptyNote = Note(
                id: '',
                title: '',
                content: '',
                date: '',
                folder: 'Umum',
                colorValue: Colors.white.value
            );

            final isSaved = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => NoteEditorScreen(note: emptyNote),
              ),
            );

            if (isSaved == true) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                messenger.removeCurrentSnackBar();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Catatan berhasil ditambahkan!'),
                    backgroundColor: Colors.green,
                  ),
                );
              });
            }
          },
          backgroundColor: Colors.teal.shade700,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.create),
          label: const Text('Catat Materi'),
        ),
      ),
    );
  }
}
