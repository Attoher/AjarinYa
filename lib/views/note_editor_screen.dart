import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../services/supabase_storage_service.dart';
import '../viewmodels/notes_view_model.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note note;

  const NoteEditorScreen({
    super.key,
    required this.note,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String _selectedFolder;

  final ImagePicker _picker = ImagePicker();
  XFile? _newImage;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: widget.note.title,
    );

    _contentController = TextEditingController(
      text: widget.note.content,
    );

    _selectedFolder =
    widget.note.folder.isEmpty ? 'Umum' : widget.note.folder;
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul catatan tidak boleh kosong'),
        ),
      );
      return;
    }

    final notesVm = Provider.of<NotesViewModel>(context, listen: false);

    setState(() {
      _saving = true;
    });

    try {
      String? imageUrl = widget.note.imageUrl;

      // Upload gambar baru jika dipilih oleh pengguna
      if (_newImage != null) {
        imageUrl = await SupabaseStorageService.instance.uploadNoteImage(
          widget.note.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : widget.note.id,
          _newImage!,
        );
      }

      final targetNote = Note(
        id: widget.note.id,
        title: _titleController.text.trim(),
        folder: _selectedFolder,
        content: _contentController.text.trim(),
        date: widget.note.date.isEmpty ? DateTime.now().toString().split(' ')[0] : widget.note.date,
        colorValue: widget.note.colorValue,
        ownerId: widget.note.ownerId,
        isBookmarked: widget.note.isBookmarked,
        imageUrl: imageUrl,
      );

      // DETEKSI OTOMATIS: Jika id kosong berarti tambah baru, jika ada berarti update catatan lama
      bool success;
      if (widget.note.id.isEmpty) {
        success = await notesVm.createNote(targetNote);
      } else {
        success = await notesVm.updateNote(targetNote);
      }

      if (!mounted) return;

      if (success) {
        // Mengirimkan data true kembali ke halaman notes_collection_screen untuk memicu Snackbar
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.note.id.isEmpty ? 'Gagal menambahkan catatan' : 'Gagal memperbarui catatan'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan saat menyimpan: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _newImage = image;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesVm = context.watch<NotesViewModel>();

    // Sinkronisasi item dropdown agar tidak crash jika 'Umum' atau folder terpilih belum ada di list view model
    final dynamicDropdownItems = notesVm.folders.contains(_selectedFolder)
        ? notesVm.folders
        : [...notesVm.folders, _selectedFolder];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note.id.isEmpty ? 'Tambah Catatan' : 'Edit Catatan'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedFolder,
              decoration: const InputDecoration(
                labelText: 'Folder',
                border: OutlineInputBorder(),
              ),
              items: dynamicDropdownItems
                  .map(
                    (folder) => DropdownMenuItem(
                  value: folder,
                  child: Text(folder),
                ),
              )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedFolder = value;
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Judul',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _contentController,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Isi Catatan',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Preview gambar baru dari lokal lokal file path device
            if (_newImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _newImage!.path,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )

            // Tampilan gambar lama dari URL Supabase/Network Storage
            else if ((widget.note.imageUrl ?? '').isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.note.imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: Text((widget.note.imageUrl ?? '').isNotEmpty || _newImage != null ? 'Ganti Gambar' : 'Tambah Gambar'),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _saving
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
                    : Text(widget.note.id.isEmpty ? 'Tambah Catatan Baru' : 'Simpan Perubahan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
