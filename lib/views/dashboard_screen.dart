import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ajarin_ya/services/api_service.dart';
import 'package:ajarin_ya/viewmodels/auth_view_model.dart';
import 'package:ajarin_ya/views/study_spot_screen.dart';
import 'package:ajarin_ya/views/barter_request_screen.dart';
import 'package:ajarin_ya/views/pomodoro_screen.dart';
import 'package:ajarin_ya/views/notes_collection_screen.dart';
import 'package:ajarin_ya/views/question_forum_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  Map<String, String>? _quote;
  bool _isLoadingQuote = true;

  @override
  void initState() {
    super.initState();
    _fetchQuote();
  }

  void _fetchQuote() async {
    try {
      final quoteData = await _apiService.getRandomQuote();
      if (mounted) {
        setState(() {
          _quote = quoteData;
          _isLoadingQuote = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingQuote = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final userDisplayName = authViewModel.user?.displayName ?? 'Mahasiswa ITS';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // Header premium dengan efek gelombang dan gradasi warna modern
          SliverAppBar(
            expandedHeight: 240.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.deepPurple.shade900,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'AjarinYa! Dashboard',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple.shade900, Colors.indigo.shade800, Colors.deepPurple.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Aksen dekoratif melingkar
                    Positioned(
                      right: -30,
                      top: -20,
                      child: CircleAvatar(
                        radius: 110,
                        backgroundColor: Colors.white.withOpacity(0.06),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: -20,
                      child: CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.white.withOpacity(0.04),
                      ),
                    ),
                    
                    // Detail Teks SDG 4
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.shade400.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green.shade300.withOpacity(0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_stories, color: Colors.greenAccent, size: 14),
                                  SizedBox(width: 6),
                                  Text(
                                    'SDG Target 4: Pendidikan Berkualitas',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Hai, $userDisplayName! Selamat belajar di AjarinYa!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Konten Utama
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card Quote Eksternal ZenQuotes API
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF6366F1), // Indigo
                            Color(0xFF4F46E5),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.format_quote_rounded, color: Colors.white, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Kutipan Motivasi Hari Ini (ZenQuotes API)',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _isLoadingQuote
                              ? const SizedBox(
                                  height: 40,
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    ),
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _quote?['quote'] ?? 'Gagal memuat kutipan harian.',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.w500,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Text(
                                        '- ${_quote?['author'] ?? 'Anonim'}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Pengantar & Status Diagnostik Ujian
                    Text(
                      'STATUS INTEGRASI FITUR (Anggota 1)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Card Diagnostik Premium
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildDiagnosticRow(
                            context,
                            Icons.shield_outlined,
                            Colors.amber.shade700,
                            'Null Safety Jingga',
                            'Lokasi GeoPoint null akan otomatis diganti fallback 0.0, 0.0.',
                          ),
                          const Divider(height: 20),
                          _buildDiagnosticRow(
                            context,
                            Icons.verified_user_outlined,
                            Colors.indigo.shade700,
                            'Anti-Cheat Double-Defense',
                            'Penyaringan local asersi & Firestore menjamin anti-self matchmaking.',
                          ),
                          const Divider(height: 20),
                          _buildDiagnosticRow(
                            context,
                            Icons.sync_alt_rounded,
                            Colors.green.shade700,
                            'Atomic Transactions',
                            'Firestore transactions menjamin zero race-conditions.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // SECTION 1: ANGGOTA 1 (SAYA)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.star, color: Colors.deepPurple.shade700, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'MODUL 1 (ANGGOTA 1) - FULL FIREBASE & MAP',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple.shade900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // TOMBOL 1: STUDY SPOT EXPLORER
                    _buildFeatureCard(
                      context,
                      title: 'Study Spot Explorer',
                      subtitle: 'Peta Lokasi & Geolokasi Belajar Bersama',
                      desc: 'Temukan spot belajar yang nyaman di sekitar kampus ITS dengan koordinat terlindungi.',
                      gradient: LinearGradient(
                        colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      icon: Icons.map_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const StudySpotScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // TOMBOL 2: PEER MENTOR MATCHMAKER
                    _buildFeatureCard(
                      context,
                      title: 'Peer Skill Barter',
                      subtitle: 'Matchmaking Mentor Sebaya',
                      desc: 'Ajukan keahlian yang bisa diajarkan dan tukarkan dengan ilmu yang ingin dipelajari secara transaksional.',
                      gradient: LinearGradient(
                        colors: [Colors.indigo.shade700, Colors.indigo.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      icon: Icons.swap_horizontal_circle,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const BarterRequestScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 28),

                    // SECTION 2: ANGGOTA 2
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.palette_outlined, color: Colors.teal.shade800, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'MODUL 2 (ANGGOTA 2) - AKTIF (CRUD FIRESTORE)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // TOMBOL 3: POMODORO TIMER
                    _buildFeatureCard(
                      context,
                      title: 'Sesi Pomodoro Bersama',
                      subtitle: 'Timer Belajar Produktif & Lofi Musik',
                      desc: 'Kelola ritme belajar Anda dengan metode Pomodoro bersuara ambient dan belajar bersama rekan ITS.',
                      gradient: LinearGradient(
                        colors: [Colors.redAccent.shade700, Colors.redAccent.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      icon: Icons.hourglass_empty_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PomodoroScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // TOMBOL 4: NOTES & COLLECTION
                    _buildFeatureCard(
                      context,
                      title: 'Arsip Catatan & Rangkuman',
                      subtitle: 'Notes, Bookmark & Koleksi Folder Materi',
                      desc: 'Tulis rangkuman materi kuliah penting, buat bookmark, dan arsipkan ke dalam folder rapi.',
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade700, Colors.teal.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      icon: Icons.collections_bookmark_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotesCollectionScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 28),

                    // SECTION 3: ANGGOTA 3
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.question_answer_outlined, color: Colors.orange.shade800, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'MODUL 3 (ANGGOTA 3) - AKTIF (CRUD FIRESTORE)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // TOMBOL 5 & 6: DISCUSSION FORUM
                    _buildFeatureCard(
                      context,
                      title: 'Forum Diskusi Soal',
                      subtitle: 'Feed Pertanyaan & Kolom Jawaban Solusi',
                      desc: 'Tanyakan kesulitan soal belajar Anda kepada komunitas mahasiswa lain dan berikan rating jawaban terbaik.',
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade800, Colors.orange.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      icon: Icons.forum_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const QuestionForumScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    
                    // Informasi Sinergi Kelompok
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.grey.shade700, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Sinergi Kelompok (AjarinYa! Ecosystem)',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Seluruh fitur ekosistem AjarinYa! di atas dirancang untuk saling bersinergi mendukung SDG 4 (Pendidikan Berkualitas) secara kohesif. Modul semua anggota kini fungsional 100% dinamis terhubung ke database cloud.',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ]),
          )
        ],
      ),
    );
  }

  Widget _buildDiagnosticRow(
    BuildContext context,
    IconData icon,
    Color color,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String desc,
    required LinearGradient gradient,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                )
              ],
            ),
            const SizedBox(height: 16),
            Text(
              desc,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Mulai Menjelajah',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, color: Colors.white.withOpacity(0.9), size: 14),
              ],
            )
          ],
        ),
      ),
    );
  }
}
