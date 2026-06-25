import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ajarin_ya/models/note.dart';
import 'package:ajarin_ya/theme/app_theme.dart';
import 'package:ajarin_ya/viewmodels/auth_view_model.dart';
import 'package:ajarin_ya/viewmodels/notes_view_model.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  // Timer settings
  int _minutes = 25;
  int _seconds = 0;
  Timer? _timer;
  bool _isRunning = false;
  String _currentMode = 'Focus'; // Focus, Short Break, Long Break
  int _sessionsCompleted = 0;

  // Local state for interactive ambient sounds
  String _selectedAmbient = 'None';
  final List<String> _ambientSounds = ['None', 'Lofi Cafe', 'Hujan Deras', 'Hutan Rileks'];


  // Note ke Notes Collection
  final TextEditingController _noteTitleController = TextEditingController();
  final TextEditingController _noteContentController = TextEditingController();
  String _noteFolder = 'Umum';
  String _noteSaveTarget = 'Umum'; // 'Umum' | 'Diri Sendiri'
  bool _isSavingNote = false;

  // Filter untuk tampilan daftar catatan di tab Pomodoro
  String _noteViewFilter = 'Umum'; // 'Umum' | 'Diri Sendiri'

  @override
  void initState() {
    super.initState();
  }

  void _startTimer() {
    if (_timer != null) return;
    setState(() {
      _isRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_seconds > 0) {
          _seconds--;
        } else {
          if (_minutes > 0) {
            _minutes--;
            _seconds = 59;
          } else {
            // Timer finished
            _timer?.cancel();
            _timer = null;
            _isRunning = false;
            _sessionsCompleted++;
            _showSessionFinishedDialog();
          }
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isRunning = false;
      _setModeDuration(_currentMode);
    });
  }

  void _setModeDuration(String mode) {
    _currentMode = mode;
    _seconds = 0;
    if (mode == 'Focus') {
      _minutes = 25;
    } else if (mode == 'Short Break') {
      _minutes = 5;
    } else {
      _minutes = 15;
    }
  }

  void _showSessionFinishedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Flexible(child: Text('Sesi Selesai!', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text(
          _currentMode == 'Focus'
              ? 'Selamat! Anda menyelesaikan 1 sesi fokus. Waktunya istirahat sejenak!'
              : 'Waktu istirahat selesai! Mari kembali fokus belajar.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                if (_currentMode == 'Focus') {
                  _setModeDuration('Short Break');
                } else {
                  _setModeDuration('Focus');
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(_currentMode == 'Focus' ? 'Ambil Istirahat' : 'Mulai Belajar'),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _noteTitleController.dispose();
    _noteContentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int totalSecs = (_currentMode == 'Focus' ? 25 : _currentMode == 'Short Break' ? 5 : 15) * 60;
    final double progress = totalSecs == 0 ? 0 : (_minutes * 60 + _seconds) / totalSecs;
    final screenWidth = MediaQuery.of(context).size.width;
    final timerSize = screenWidth < 360 ? 180.0 : (screenWidth < 420 ? 220.0 : 240.0);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Sesi Pomodoro Bersama', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              const SizedBox(height: 24),
              
              // Mode Toggles
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildModeButton('Focus', AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  _buildModeButton('Short Break', Colors.teal),
                  const SizedBox(width: 8),
                  _buildModeButton('Long Break', Colors.blue.shade600),
                ],
              ),
              const SizedBox(height: 48),

              // Circular Countdown Timer
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: timerSize,
                    height: timerSize,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey.shade200,
                      strokeCap: StrokeCap.round,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _currentMode == 'Focus' 
                            ? AppTheme.primaryColor 
                            : (_currentMode == 'Short Break' ? Colors.teal : Colors.blue.shade600)
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_minutes.toString().padLeft(2, '0')}:${_seconds.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentMode.toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sesi Selesai: $_sessionsCompleted',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 48),

              // Timer Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Reset Button
                  IconButton(
                    onPressed: _resetTimer,
                    iconSize: 32,
                    color: AppTheme.textSecondary,
                    icon: const Icon(Icons.replay),
                  ),
                  const SizedBox(width: 24),
                  // Play/Pause Floating Action Button
                  GestureDetector(
                    onTap: _isRunning ? _pauseTimer : _startTimer,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Icon(
                        _isRunning ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Skip Session Mock Button
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _sessionsCompleted++;
                        _setModeDuration(_currentMode == 'Focus' ? 'Short Break' : 'Focus');
                      });
                    },
                    iconSize: 32,
                    color: AppTheme.textSecondary,
                    icon: const Icon(Icons.skip_next),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Ambient Sound Simulation Block
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.softShadow,
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.music_note, color: AppTheme.primaryColor, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Musik & Latar Suara Fokus',
                          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _ambientSounds.map((sound) {
                        final isSelected = _selectedAmbient == sound;
                        IconData soundIcon;
                        switch (sound) {
                          case 'Lofi Cafe': soundIcon = Icons.headphones; break;
                          case 'Hujan Deras': soundIcon = Icons.water_drop; break;
                          case 'Hutan Rileks': soundIcon = Icons.park; break;
                          default: soundIcon = Icons.volume_off; break;
                        }
                        return ChoiceChip(
                          avatar: Icon(soundIcon, color: isSelected ? Colors.white : AppTheme.textSecondary, size: 16),
                          label: Text(sound, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textSecondary, fontSize: 11)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedAmbient = sound;
                            });
                          },
                          backgroundColor: Colors.transparent,
                          selectedColor: AppTheme.primaryColor,
                          side: BorderSide(
                            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Notes Section — simpan ke Notes Collection
              Builder(builder: (context) {
                final notesVm = context.watch<NotesViewModel>();
                final savableFolders = notesVm.folders
                    .where((f) => f != 'Semua Catatan')
                    .toList();
                // Pastikan _noteFolder valid
                if (!savableFolders.contains(_noteFolder)) {
                  _noteFolder = savableFolders.isNotEmpty ? savableFolders.first : 'Umum';
                }
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppTheme.softShadow,
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.edit_note, color: AppTheme.primaryColor, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Buat Catatan',
                            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _noteTitleController,
                        decoration: InputDecoration(
                          hintText: 'Judul catatan...',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          filled: true,
                          fillColor: AppTheme.backgroundColor,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _noteContentController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Tulis catatan penting saat sesi fokus...',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          filled: true,
                          fillColor: AppTheme.backgroundColor,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Target simpan: Umum atau Diri Sendiri
                      Row(
                        children: [
                          _buildSaveTargetChip('Umum', onTap: () {
                            setState(() {
                              _noteSaveTarget = 'Umum';
                              _noteFolder = 'Umum';
                            });
                          }),
                          const SizedBox(width: 8),
                          _buildSaveTargetChip('Diri Sendiri', onTap: () {
                            final personal = savableFolders.where((f) => f != 'Umum').toList();
                            if (personal.isEmpty) {
                              // Auto-buat folder "Diri Sendiri" jika belum ada
                              notesVm.addFolder('Diri Sendiri');
                              setState(() {
                                _noteSaveTarget = 'Diri Sendiri';
                                _noteFolder = 'Diri Sendiri';
                              });
                            } else {
                              setState(() {
                                _noteSaveTarget = 'Diri Sendiri';
                                _noteFolder = personal.first;
                              });
                            }
                          }),
                        ],
                      ),
                      // Sub-dropdown folder personal (muncul jika Diri Sendiri dipilih)
                      if (_noteSaveTarget == 'Diri Sendiri') ...[
                        const SizedBox(height: 8),
                        Builder(builder: (_) {
                          final personalFolders = savableFolders
                              .where((f) => f != 'Umum')
                              .toList();
                          if (personalFolders.length <= 1) {
                            return const SizedBox.shrink();
                          }
                          final currentVal = personalFolders.contains(_noteFolder)
                              ? _noteFolder
                              : personalFolders.first;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButton<String>(
                              value: currentVal,
                              isExpanded: true,
                              underline: const SizedBox(),
                              style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                              items: personalFolders
                                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                                  .toList(),
                              onChanged: (v) => setState(() => _noteFolder = v ?? currentVal),
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSavingNote
                              ? null
                              : () async {
                                  final title = _noteTitleController.text.trim();
                                  final content = _noteContentController.text.trim();
                                  if (title.isEmpty && content.isEmpty) return;
                                  setState(() => _isSavingNote = true);
                                  final messenger = ScaffoldMessenger.of(context);
                                  final targetFolder = _noteSaveTarget == 'Umum' ? 'Umum' : _noteFolder;
                                  await notesVm.createNote(Note(
                                    id: '',
                                    title: title.isEmpty ? 'Catatan Pomodoro' : title,
                                    folder: targetFolder,
                                    content: content,
                                    date: DateTime.now().toIso8601String(),
                                    isBookmarked: false,
                                    colorValue: 0xFFFFFFFF,
                                    ownerId: '',
                                  ));
                                  _noteTitleController.clear();
                                  _noteContentController.clear();
                                  if (mounted) {
                                    setState(() => _isSavingNote = false);
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text('Catatan berhasil disimpan')),
                                    );
                                  }
                                },
                          icon: _isSavingNote
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.save_outlined, size: 16),
                          label: Text(_isSavingNote ? 'Menyimpan...' : 'Simpan ke Catatan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),

              // Tampilkan Catatan — Semua & Diri Sendiri
              Builder(builder: (context) {
                final notesVm = context.watch<NotesViewModel>();
                final allNotes = notesVm.notes;
                final filtered = _noteViewFilter == 'Diri Sendiri'
                    ? allNotes.where((n) => n.folder != 'Umum').toList()
                    : allNotes.where((n) => n.folder == 'Umum').toList();
                final displayName = context.read<AuthViewModel>().user?.displayName ?? '';

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppTheme.softShadow,
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notes_rounded, color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Catatan Saya',
                              style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          // Filter chips
                          _buildNoteFilterChip('Umum'),
                          const SizedBox(width: 6),
                          _buildNoteFilterChip('Diri Sendiri'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (filtered.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Belum ada catatan',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length > 5 ? 5 : filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final note = filtered[i];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(note.colorValue).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Color(note.colorValue).withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          note.title.isEmpty ? '(tanpa judul)' : note.title,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          note.folder,
                                          style: const TextStyle(fontSize: 9, color: AppTheme.primaryColor, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () => _showEditNoteDialog(note, notesVm),
                                        child: const Icon(Icons.edit_outlined, size: 15, color: AppTheme.textSecondary),
                                      ),
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: () => _confirmDeleteNote(note, notesVm),
                                        child: const Icon(Icons.delete_outline, size: 15, color: Colors.redAccent),
                                      ),
                                    ],
                                  ),
                                  if (note.content.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      note.content,
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  if (_noteViewFilter == 'Umum' && displayName.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'oleh $displayName',
                                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      if (filtered.length > 5)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '+${filtered.length - 5} catatan lainnya — lihat di tab Catatan',
                            style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor),
                          ),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditNoteDialog(Note note, NotesViewModel notesVm) {
    final titleCtrl = TextEditingController(text: note.title);
    final contentCtrl = TextEditingController(text: note.content);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Catatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: 'Judul',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Isi catatan',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              notesVm.updateNote(Note(
                id: note.id,
                title: titleCtrl.text.trim(),
                folder: note.folder,
                content: contentCtrl.text.trim(),
                date: note.date,
                isBookmarked: note.isBookmarked,
                colorValue: note.colorValue,
                ownerId: note.ownerId,
                imageUrl: note.imageUrl,
              ));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteNote(Note note, NotesViewModel notesVm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Catatan?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Catatan "${note.title.isEmpty ? '(tanpa judul)' : note.title}" akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              notesVm.deleteNote(note.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveTargetChip(String label, {required VoidCallback onTap}) {
    final isSelected = _noteSaveTarget == label;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildNoteFilterChip(String label) {
    final isSelected = _noteViewFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _noteViewFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton(String mode, Color activeColor) {
    final isSelected = _currentMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _setModeDuration(mode);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          mode,
          style: TextStyle(
            color: isSelected ? activeColor : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
