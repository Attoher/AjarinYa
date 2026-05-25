import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ajarin_ya/services/api_service.dart';
import 'package:ajarin_ya/viewmodels/auth_view_model.dart';
import 'package:ajarin_ya/viewmodels/question_view_model.dart';
import 'package:ajarin_ya/viewmodels/study_spot_view_model.dart';
import 'package:ajarin_ya/viewmodels/barter_view_model.dart';
import 'package:ajarin_ya/viewmodels/notes_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ajarin_ya/views/study_spot_screen.dart';
import 'package:ajarin_ya/views/barter_request_screen.dart';
import 'package:ajarin_ya/views/pomodoro_screen.dart';
import 'package:ajarin_ya/views/notes_collection_screen.dart';
import 'package:ajarin_ya/views/question_forum_screen.dart';
import 'package:ajarin_ya/views/answer_question_screen.dart';
import 'package:ajarin_ya/views/profile_screen.dart';
import 'package:ajarin_ya/views/group_gate_screen.dart';
import 'package:ajarin_ya/models/study_spot.dart';
import 'package:ajarin_ya/models/barter_request.dart';
import 'package:ajarin_ya/models/result_state.dart';

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
    
    // Pemuatan data ViewModel secara asinkron di awal agar data real-time tampil di Home
    Future.microtask(() {
      if (mounted) {
        context.read<StudySpotViewModel>().fetchStudySpots();
      context.read<BarterViewModel>().fetchBarterRequests(FirebaseAuth.instance.currentUser?.uid ?? '');
        context.read<NotesViewModel>().loadNotes();
        context.read<QuestionViewModel>().loadQuestions();
      }
    });
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

  void _showGroupSelectorBottomSheet(BuildContext context, AuthViewModel authViewModel) {
    final user = authViewModel.user;
    if (user == null) return;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (bottomSheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pilih Grup Studi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(bottomSheetCtx),
                    )
                  ],
                ),
              ),
              const Divider(),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: user.groupIds.length,
                  itemBuilder: (ctx, idx) {
                    final gId = user.groupIds[idx];
                    final groupName = user.groupNames[gId] ?? 'Grup $gId';
                    final isActive = gId == user.activeGroupId;
                    
                    return Card(
                      color: isActive ? const Color(0xFFE3F2FD) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isActive ? const Color(0xFF0D47A1) : Colors.grey.shade200,
                          width: isActive ? 1.5 : 1,
                        ),
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isActive ? const Color(0xFF0D47A1) : Colors.grey.shade200,
                          child: Icon(
                            Icons.group,
                            color: isActive ? Colors.white : Colors.grey.shade600,
                          ),
                        ),
                        title: Text(
                          groupName,
                          style: TextStyle(
                            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                        subtitle: Text(
                          'ID: $gId',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                        trailing: isActive 
                            ? const Icon(Icons.check_circle, color: Color(0xFF0D47A1))
                            : null,
                        onTap: () {
                          if (!isActive) {
                            authViewModel.switchActiveGroup(gId);
                          }
                          Navigator.pop(bottomSheetCtx);
                        },
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(bottomSheetCtx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GroupGateScreen(isFromProfile: true),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Gabung atau Buat Grup Baru'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final user = authViewModel.user;
    final userDisplayName = user?.displayName ?? 'Mahasiswa ITS';
    final userInitial = userDisplayName.isNotEmpty ? userDisplayName[0].toUpperCase() : 'M';
    final activeGroupId = user?.activeGroupId;
    final activeGroupName = user?.groupNames[activeGroupId] ?? activeGroupId ?? 'Tidak ada grup';

    // Mendapatkan data statistik reaktif dari ViewModels
    final studySpotViewModel = Provider.of<StudySpotViewModel>(context);
    final barterViewModel = Provider.of<BarterViewModel>(context);
    final notesViewModel = Provider.of<NotesViewModel>(context);
    final questionViewModel = Provider.of<QuestionViewModel>(context);

    // Hitung statistik dynamic
    int totalSpots = 0;
    if (studySpotViewModel.studySpotsState is ResultStateSuccess<List<StudySpot>>) {
      totalSpots = (studySpotViewModel.studySpotsState as ResultStateSuccess<List<StudySpot>>).data.length;
    }
    int totalNotes = notesViewModel.notes.length;
    int totalQuestions = questionViewModel.questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header Modern & Premium dengan Gradient Halus & Curved Design
          SliverAppBar(
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF0D47A1),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 18,
                      child: Text(
                        userInitial,
                        style: const TextStyle(
                          color: Color(0xFF0D47A1),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'AjarinYa!',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                  fontSize: 20,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 50),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_stories, color: Colors.white, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'SDG Target 4: Pendidikan Berkualitas',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Hai, $userDisplayName!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () {
                            _showGroupSelectorBottomSheet(context, authViewModel);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.group_rounded, color: Color(0xFF0D47A1), size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  'Grup: $activeGroupName',
                                  style: const TextStyle(
                                    color: Color(0xFF0D47A1),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF0D47A1), size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Konten Utama Dashboard
          SliverList(
            delegate: SliverChildListDelegate([
              // 1. STATS BANNER - Ringkasan Ekosistem Belajar (Dynamic & Premium)
              Transform.translate(
                offset: const Offset(0, -20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(Icons.group_work_rounded, '${user?.groupIds.length ?? 0}', 'Grup Studi', Colors.blue.shade800),
                        _buildStatItem(Icons.map_rounded, '$totalSpots', 'Spot Belajar', Colors.deepPurple.shade700),
                        _buildStatItem(Icons.collections_bookmark_rounded, '$totalNotes', 'Rangkuman', Colors.teal.shade700),
                        _buildStatItem(Icons.forum_rounded, '$totalQuestions', 'Pertanyaan', Colors.orange.shade800),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. MOTIVATIONAL QUOTE - Beautiful Glassmorphic Quote Card
                    _isLoadingQuote
                        ? const SizedBox()
                        : Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.indigo.shade900, const Color(0xFF0D47A1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.indigo.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.format_quote_rounded, color: Colors.white70, size: 24),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Mutiara Hikmah Hari Ini',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _quote?['quote'] ?? 'Belajar adalah satu-satunya hal yang tidak pernah membuat pikiran lelah.',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w500,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    '— ${_quote?['author'] ?? 'Anonim'}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                    const SizedBox(height: 24),

                    // 3. PUSAT FITUR (QUICK ACCESS GRID HUB - 7 ITEMS)
                    _buildSectionHeader(
                      icon: Icons.grid_view_rounded,
                      color: const Color(0xFF0D47A1),
                      bgColor: const Color(0xFFE3F2FD),
                      label: 'PUSAT NAVIGASI FITUR',
                    ),
                    const SizedBox(height: 14),

                    // Grid menu premium yang menampilkan semua 7 fitur dengan elegan
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 500 ? 3 : 2;
                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.45,
                          children: [
                        _buildQuickActionCard(
                          context,
                          title: 'Home',
                          desc: 'Pusat Dasbor Utama',
                          icon: Icons.dashboard_rounded,
                          startColor: const Color(0xFF0D47A1),
                          endColor: const Color(0xFF1976D2),
                          onTap: () {}, // Sudah di Home
                        ),
                        _buildQuickActionCard(
                          context,
                          title: 'Study spot',
                          desc: 'Peta Geolokasi ITS',
                          icon: Icons.map_rounded,
                          startColor: Colors.deepPurple.shade800,
                          endColor: Colors.deepPurple.shade500,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const StudySpotScreen()));
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          title: 'Request Barter Skill',
                          desc: 'Match Mentor Sebaya',
                          icon: Icons.swap_horizontal_circle,
                          startColor: Colors.indigo.shade800,
                          endColor: Colors.indigo.shade500,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const BarterRequestScreen()));
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          title: 'Sesi Pomodoro',
                          desc: 'Timer Fokus Belajar',
                          icon: Icons.hourglass_full_rounded,
                          startColor: Colors.red.shade800,
                          endColor: Colors.red.shade500,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const PomodoroScreen()));
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          title: 'Notes / Collection',
                          desc: 'Arsip & Bookmark',
                          icon: Icons.collections_bookmark_rounded,
                          startColor: Colors.teal.shade800,
                          endColor: Colors.teal.shade500,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const NotesCollectionScreen()));
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          title: 'Question Forum',
                          desc: 'Forum Komunitas',
                          icon: Icons.forum_rounded,
                          startColor: Colors.orange.shade900,
                          endColor: Colors.orange.shade600,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const QuestionForumScreen()));
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          title: 'Answer Question',
                          desc: 'Bantu Rekan Anda',
                          icon: Icons.rate_review_rounded,
                          startColor: Colors.amber.shade900,
                          endColor: Colors.amber.shade600,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const AnswerQuestionScreen()));
                          },
                        ),
                      ],
                    );
                      },
                    ),
                    const SizedBox(height: 28),

                    // 4. LIVE UPDATE STREAM (REAL-TIME DATA DARI VIEWMODELS)
                    
                    // A. Live Update: Spot Belajar Terfavorit
                    _buildSectionHeader(
                      icon: Icons.explore_rounded,
                      color: Colors.deepPurple.shade800,
                      bgColor: Colors.deepPurple.shade50,
                      label: 'SPOT BELAJAR PILIHAN DI ITS',
                    ),
                    const SizedBox(height: 12),
                    _buildLiveStudySpots(studySpotViewModel),
                    const SizedBox(height: 24),

                    // B. Live Update: Barter Skill Terbaru
                    _buildSectionHeader(
                      icon: Icons.people_outline_rounded,
                      color: Colors.indigo.shade800,
                      bgColor: Colors.indigo.shade50,
                      label: 'BUTUH MENTOR SEBAYA (BARTER SKILL)',
                    ),
                    const SizedBox(height: 12),
                    _buildLiveBarters(barterViewModel),
                    const SizedBox(height: 24),

                    // C. Live Update: Pertanyaan Forum yang Membutuhkan Jawaban
                    _buildSectionHeader(
                      icon: Icons.question_answer_rounded,
                      color: Colors.orange.shade800,
                      bgColor: Colors.orange.shade50,
                      label: 'DISKUSI AKTIF - BANTU JAWAB SOAL',
                    ),
                    const SizedBox(height: 12),
                    _buildLiveQuestions(questionViewModel),
                    
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

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required String title,
    required String desc,
    required IconData icon,
    required Color startColor,
    required Color endColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shadowColor: startColor.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [startColor, endColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 12),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // A. Live Study Spots List
  Widget _buildLiveStudySpots(StudySpotViewModel vm) {
    final state = vm.studySpotsState;
    if (state is ResultStateSuccess<List<StudySpot>>) {
      final list = state.data;
      if (list.isEmpty) {
        return _buildEmptyState('Belum ada spot belajar yang terdaftar.');
      }
      // Ambil maks 2 spot
      final showList = list.take(2).toList();
      return Column(
        children: showList.map((spot) {
          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: CircleAvatar(
                backgroundColor: Colors.deepPurple.shade50,
                child: Icon(Icons.location_on_rounded, color: Colors.deepPurple.shade700),
              ),
              title: Text(spot.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text(spot.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const StudySpotScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Buka Peta', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          );
        }).toList(),
      );
    }
    return const Center(child: SizedBox(height: 30, width: 30, child: CircularProgressIndicator(strokeWidth: 2)));
  }

  // B. Live Barter Skill List
  Widget _buildLiveBarters(BarterViewModel vm) {
    final state = vm.barterRequestsState;
    if (state is ResultStateSuccess<List<BarterRequest>>) {
      final list = state.data;
      if (list.isEmpty) {
        return _buildEmptyState('Tidak ada penawaran barter mentor dari orang lain.');
      }
      final showList = list.take(2).toList();
      return Column(
        children: showList.map((req) {
          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.school, color: Colors.indigo.shade700, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Bisa: ${req.canTeach}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.menu_book, color: Colors.indigo.shade700, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Mau belajar: ${req.wantToLearn}',
                                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 11, color: Colors.grey.shade700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const BarterRequestScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Match', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
          );
        }).toList(),
      );
    }
    return const Center(child: SizedBox(height: 30, width: 30, child: CircularProgressIndicator(strokeWidth: 2)));
  }

  // C. Live Question Forum List
  Widget _buildLiveQuestions(QuestionViewModel vm) {
    final list = vm.questions;
    if (list.isEmpty) {
      return _buildEmptyState('Belum ada pertanyaan yang diajukan di forum.');
    }
    final showList = list.take(2).toList();
    return Column(
      children: showList.map((q) {
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: Colors.orange.shade50,
              child: Text(q.avatar, style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            title: Text(q.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text('Kategori: ${q.tag} • ${q.replies.length} Jawaban', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            trailing: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AnswerQuestionScreen(questionId: q.id)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Bantu Jawab', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }
}
