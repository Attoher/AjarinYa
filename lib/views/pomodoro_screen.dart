import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ajarin_ya/models/pomodoro_preset.dart';
import 'package:ajarin_ya/theme/app_theme.dart';
import 'package:ajarin_ya/viewmodels/auth_view_model.dart';
import 'package:ajarin_ya/viewmodels/pomodoro_view_model.dart';

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

  // Online study group simulation
  List<Map<String, String>> _onlinePeers = [];
  bool _isLoadingPeers = true;
  bool _isPeersExpanded = false;
  String _activeGroupName = 'Ruang Belajar Aktif';

  // Local session notes
  final List<String> _sessionNotes = [];
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchGroupMembers();
    });
  }

  Future<void> _fetchGroupMembers() async {
    final authVm = Provider.of<AuthViewModel>(context, listen: false);
    final activeGroupId = authVm.user?.activeGroupId;
    
    if (activeGroupId == null) {
      if (mounted) {
        setState(() {
          _onlinePeers = [];
          _isLoadingPeers = false;
        });
      }
      return;
    }

    try {
      final groupDoc = await FirebaseFirestore.instance.collection('groups').doc(activeGroupId).get();
      if (!groupDoc.exists) {
        if (mounted) setState(() => _isLoadingPeers = false);
        return;
      }
      
      final groupName = groupDoc.data()?['name'] ?? 'Ruang Belajar Aktif';
      final memberIds = List<String>.from(groupDoc.data()?['memberIds'] ?? []);
      
      List<Map<String, String>> peers = [];
      for (final id in memberIds) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(id).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          peers.add({
            'name': data['displayName'] ?? 'Pengguna',
            'status': 'Online',
            'time': 'Sekarang',
          });
        }
      }
      
      if (mounted) {
        setState(() {
          _activeGroupName = groupName;
          _onlinePeers = peers;
          _isLoadingPeers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPeers = false);
      }
    }
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
    } else if (mode == 'Long Break') {
      _minutes = 15;
    }
  }

  void _showSessionFinishedDialog() {
    // Auto-save Focus session to Firestore
    if (_currentMode == 'Focus') {
      context.read<PomodoroViewModel>().saveSession('Focus', 25);
    }
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

  void _applyPreset(PomodoroPreset preset) {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isRunning = false;
      _seconds = 0;
      if (_currentMode == 'Focus') {
        _minutes = preset.focusMinutes;
      } else if (_currentMode == 'Short Break') {
        _minutes = preset.shortBreakMinutes;
      } else {
        _minutes = preset.longBreakMinutes;
      }
    });
  }

  void _showPresetDialog(BuildContext context, PomodoroViewModel pomodoroVm, {PomodoroPreset? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final focusCtrl = TextEditingController(text: '${existing?.focusMinutes ?? 25}');
    final shortCtrl = TextEditingController(text: '${existing?.shortBreakMinutes ?? 5}');
    final longCtrl  = TextEditingController(text: '${existing?.longBreakMinutes ?? 15}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          existing == null ? 'Buat Preset Baru' : 'Edit Preset',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama Preset',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: focusCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Fokus (mnt)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: shortCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Break Pendek',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: longCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Break Panjang',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final focus = int.tryParse(focusCtrl.text) ?? 25;
              final short = int.tryParse(shortCtrl.text) ?? 5;
              final long  = int.tryParse(longCtrl.text) ?? 15;
              if (existing == null) {
                pomodoroVm.createPreset(PomodoroPreset(
                  name: name,
                  focusMinutes: focus,
                  shortBreakMinutes: short,
                  longBreakMinutes: long,
                ));
              } else {
                pomodoroVm.updatePreset(existing.copyWith(
                  name: name,
                  focusMinutes: focus,
                  shortBreakMinutes: short,
                  longBreakMinutes: long,
                ));
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(existing == null ? 'Simpan' : 'Perbarui'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pomodoroVm = context.watch<PomodoroViewModel>();
    final double progress = (_minutes * 60 + _seconds) /
        (_currentMode == 'Focus' ? 25 * 60 : (_currentMode == 'Short Break' ? 5 * 60 : 15 * 60));
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

              // Preset Sesi Block
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.tune, color: AppTheme.primaryColor, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Preset Sesi',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.add_circle_outline,
                              color: AppTheme.primaryColor, size: 22),
                          onPressed: () => _showPresetDialog(context, pomodoroVm),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (pomodoroVm.presets.isEmpty)
                      Text(
                        'Belum ada preset. Ketuk + untuk membuat preset durasi timer kustom.',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: pomodoroVm.presets.map((preset) {
                          return GestureDetector(
                            onTap: () => _applyPreset(preset),
                            onLongPress: () {
                              showModalBottomSheet(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                builder: (_) => SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.edit_outlined),
                                        title: const Text('Edit Preset'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _showPresetDialog(context, pomodoroVm, existing: preset);
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                        title: const Text('Hapus Preset', style: TextStyle(color: Colors.redAccent)),
                                        onTap: () {
                                          Navigator.pop(context);
                                          pomodoroVm.deletePreset(preset.id);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    preset.name,
                                    style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${preset.focusMinutes}/${preset.shortBreakMinutes}/${preset.longBreakMinutes} mnt',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 9),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Online Study Room Simulation Block
              Container(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.people_alt, color: Colors.teal, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _activeGroupName,
                                  style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_onlinePeers.length} Online',
                            style: const TextStyle(color: Colors.teal, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isLoadingPeers)
                      const Center(child: CircularProgressIndicator())
                    else if (_onlinePeers.isEmpty)
                      const Text('Belum ada anggota yang bergabung.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))
                    else
                      Column(
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _isPeersExpanded ? _onlinePeers.length : (_onlinePeers.length > 3 ? 3 : _onlinePeers.length),
                            itemBuilder: (ctx, idx) {
                              final peer = _onlinePeers[idx];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                                      child: Text(
                                        peer['name']!.isNotEmpty ? peer['name']![0].toUpperCase() : '?',
                                        style: const TextStyle(color: AppTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            peer['name']!,
                                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${peer['status']}',
                                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            'Mulai sejak ${peer['time']}',
                                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.circle, color: Colors.teal, size: 8),
                                  ],
                                ),
                              );
                            },
                          ),
                          if (_onlinePeers.length > 3)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isPeersExpanded = !_isPeersExpanded;
                                });
                              },
                              child: Text(
                                _isPeersExpanded ? 'Tampilkan Lebih Sedikit' : 'Tampilkan ${_onlinePeers.length - 3} Lainnya',
                                style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12),
                              ),
                            )
                        ],
                      ),
                  ],
                ),
              ),
              // Notes Section
              Container(
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
                          'Catatan Kecil',
                          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_sessionNotes.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _sessionNotes.length,
                        itemBuilder: (ctx, idx) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('•', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_sessionNotes[idx], style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    if (_sessionNotes.isNotEmpty) const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _noteController,
                            maxLines: 1,
                            decoration: InputDecoration(
                              hintText: 'Tulis catatan penting saat sesi fokus...',
                              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                              filled: true,
                              fillColor: AppTheme.backgroundColor,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed: () {
                              if (_noteController.text.trim().isNotEmpty) {
                                setState(() {
                                  _sessionNotes.add(_noteController.text.trim());
                                  _noteController.clear();
                                });
                              }
                            },
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Riwayat Sesi
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
                        Icon(Icons.history, color: AppTheme.primaryColor, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Riwayat Sesi',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (pomodoroVm.sessions.isEmpty)
                      Text(
                        'Belum ada sesi selesai. Selesaikan sesi fokus untuk menyimpan riwayat.',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: pomodoroVm.sessions.length > 10 ? 10 : pomodoroVm.sessions.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, idx) {
                          final s = pomodoroVm.sessions[idx];
                          final d = s.completedAt;
                          final dateStr = '${d.day.toString().padLeft(2,'0')}/'
                              '${d.month.toString().padLeft(2,'0')}/'
                              '${d.year}  '
                              '${d.hour.toString().padLeft(2,'0')}:'
                              '${d.minute.toString().padLeft(2,'0')}';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    s.mode,
                                    style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${s.durationMinutes} menit',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        dateStr,
                                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                  onPressed: () => pomodoroVm.deleteSession(s.id),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 120),
            ],
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
