import 'dart:async';
import 'package:flutter/material.dart';

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
  final List<Map<String, String>> _onlinePeers = [
    {'name': 'Ahmad Fauzi (Teknik Informatika)', 'status': 'Focusing', 'time': '12:45'},
    {'name': 'Nabila Putri (Sistem Informasi)', 'status': 'Focusing', 'time': '18:10'},
    {'name': 'Budi Santoso (Teknik Elektro)', 'status': 'Short Break', 'time': '02:15'},
  ];

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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 28),
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
              backgroundColor: Colors.redAccent,
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double progress = (_minutes * 60 + _seconds) / 
        (_currentMode == 'Focus' ? 25 * 60 : (_currentMode == 'Short Break' ? 5 * 60 : 15 * 60));
    final screenWidth = MediaQuery.of(context).size.width;
    final timerSize = screenWidth < 360 ? 180.0 : (screenWidth < 420 ? 220.0 : 240.0);

    return Scaffold(
      backgroundColor: const Color(0xFF1E0E11), // Deep premium dark crimson background
      appBar: AppBar(
        title: const Text('Sesi Pomodoro Bersama', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              // Subtitle SDG 4 Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.redAccent.shade700.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.redAccent.shade700.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hourglass_bottom, color: Colors.redAccent, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Modul 2 UI/UX: Fokus & Produktivitas Belajar',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Mode Toggles
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildModeButton('Focus', const Color(0xFFE57373)),
                  const SizedBox(width: 8),
                  _buildModeButton('Short Break', const Color(0xFF81C784)),
                  const SizedBox(width: 8),
                  _buildModeButton('Long Break', const Color(0xFF64B5F6)),
                ],
              ),
              const SizedBox(height: 36),

              // Circular Countdown Timer
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: timerSize,
                    height: timerSize,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _currentMode == 'Focus' 
                            ? Colors.redAccent 
                            : (_currentMode == 'Short Break' ? Colors.greenAccent : Colors.blueAccent)
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_minutes.toString().padLeft(2, '0')}:${_seconds.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentMode.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sesi Selesai: $_sessionsCompleted',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 40),

              // Timer Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Reset Button
                  IconButton(
                    onPressed: _resetTimer,
                    iconSize: 32,
                    color: Colors.white60,
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
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withValues(alpha: 0.4),
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
                    color: Colors.white60,
                    icon: const Icon(Icons.skip_next),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Ambient Sound Simulation Block
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.music_note, color: Colors.redAccent, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Musik & Latar Suara Fokus',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
                          avatar: Icon(soundIcon, color: isSelected ? Colors.white : Colors.white60, size: 16),
                          label: Text(sound, style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontSize: 11)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedAmbient = sound;
                            });
                          },
                          backgroundColor: Colors.transparent,
                          selectedColor: Colors.redAccent.shade700,
                          side: BorderSide(
                            color: isSelected ? Colors.redAccent : Colors.white24,
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
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.people_alt, color: Colors.greenAccent, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Ruang Belajar Aktif (ITS)',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '3 Online',
                            style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _onlinePeers.length,
                      itemBuilder: (ctx, idx) {
                        final peer = _onlinePeers[idx];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
                                child: Text(
                                  peer['name']![0],
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      peer['name']!,
                                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${peer['status']}',
                                      style: TextStyle(color: Colors.white30, fontSize: 10),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      'Mulai sejak ${peer['time']}',
                                      style: const TextStyle(color: Colors.white30, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
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
          color: isSelected ? activeColor : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : Colors.white12,
          ),
        ),
        child: Text(
          mode,
          style: TextStyle(
            color: isSelected ? Colors.black87 : Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
