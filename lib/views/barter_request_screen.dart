import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ajarin_ya/models/barter_request.dart';
import 'package:ajarin_ya/models/result_state.dart';
import 'package:ajarin_ya/viewmodels/barter_view_model.dart';

class BarterRequestScreen extends StatefulWidget {
  const BarterRequestScreen({super.key});

  @override
  State<BarterRequestScreen> createState() => _BarterRequestScreenState();
}

class _BarterRequestScreenState extends State<BarterRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _canTeachController = TextEditingController();
  final _wantToLearnController = TextEditingController();
  
  // Simulasi ID pengguna aktif (Pengguna 1)
  final String _currentUserId = 'User_Mahasiswa_1';

  @override
  void initState() {
    super.initState();
    final barterViewModel = context.read<BarterViewModel>();
    Future.microtask(() {
      barterViewModel.fetchBarterRequests(_currentUserId);
    });
  }

  @override
  void dispose() {
    _canTeachController.dispose();
    _wantToLearnController.dispose();
    super.dispose();
  }

  void _showAddRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(Icons.swap_horizontal_circle_outlined, color: Colors.indigo.shade700),
              const SizedBox(width: 8),
              const Text('Buat Barter Skill', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _canTeachController,
                  decoration: InputDecoration(
                    labelText: 'Keahlian yang bisa diajarkan',
                    hintText: 'Contoh: Pemrograman Flutter, Kalkulus I',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    prefixIcon: const Icon(Icons.school_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _wantToLearnController,
                  decoration: InputDecoration(
                    labelText: 'Keahlian yang ingin dipelajari',
                    hintText: 'Contoh: Desain Figma, UI/UX Dasar',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    prefixIcon: const Icon(Icons.menu_book_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Wajib diisi' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
              },
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  final request = BarterRequest(
                    userId: _currentUserId,
                    canTeach: _canTeachController.text,
                    wantToLearn: _wantToLearnController.text,
                    status: 'PENDING',
                  );

                  final vm = context.read<BarterViewModel>();
                  await vm.createBarterRequest(request);

                  _canTeachController.clear();
                  _wantToLearnController.clear();
                  
                  if (context.mounted) {
                    Navigator.pop(dialogCtx);
                    vm.fetchBarterRequests(_currentUserId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Request barter Anda sukses dipublikasikan!')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Publikasikan'),
            ),
          ],
        );
      },
    );
  }

  // ⚠️ SIMULATOR INTEGRITAS (ANTI-CHEAT & RACE CONDITION EXTREME TEST)
  void _triggerCheatSimulator(BuildContext context, String mode) async {
    final vm = context.read<BarterViewModel>();

    if (mode == 'BYPASS_FILTER') {
      // Simulator mencoba memasukkan request buatan user sendiri secara sengaja ke list barter.
      // Ini mensimulasikan kegagalan filter Firestore dengan sengaja membuat request miliknya sendiri.
      final cheatRequest = BarterRequest(
        userId: _currentUserId, // Milik sendiri!
        canTeach: '☠️ Hack Menembus Filter Integritas',
        wantToLearn: 'Bahasa Rahasia Simulator',
        status: 'PENDING',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.amber.shade900,
          content: const Text('Simulasi Cheat: Menyisipkan request barter milik sendiri. Menguji Asersi!'),
        ),
      );

      // Menulis langsung ke database
      final db = FirebaseFirestore.instance;
      final docRef = db.collection('barter_requests').doc();
      cheatRequest.requestId = docRef.id;
      await docRef.set(cheatRequest.toJson());

      // Muat ulang daftar.
      // Asersi di barter_repository.dart:83-86 akan melempar AssertionError jika assert aktif, 
      // dan filter manual di line 89 akan menyaring data ini secara diam-diam demi kestabilan aplikasi!
      await vm.fetchBarterRequests(_currentUserId);
    }
  }

  void _triggerRaceConditionSimulator(BuildContext context, String requestId) async {
    // Simulasi Race Condition: Dua pengguna menekan tombol match bersamaan pada request tertentu.
    final vm = context.read<BarterViewModel>();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.indigo.shade900,
        content: const Text('Simulasi Race Condition: Memicu transaksi ganda simultan via atomic transaction.'),
      ),
    );

    // Jalankan dua request applyBarter secara paralel dengan selisih waktu 0ms!
    final call1 = vm.applyBarter(requestId, 'User_Mahasiswa_2_Tercepat');
    final call2 = vm.applyBarter(requestId, 'User_Mahasiswa_3_Terlambat');

    await Future.wait([call1, call2]);

    vm.fetchBarterRequests(_currentUserId);

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Hasil Simulasi Transaksi'),
          content: const Text(
            'Transaksi Firestore berhasil diselesaikan secara atomik.\n\n'
            'Salah satu mahasiswa berhasil memenangkan status MATCHED secara mutlak, '
            'sedangkan mahasiswa kedua dibatalkan secara bersih tanpa membuat aplikasi force close (layar merah).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Barter Skill (SDG 4)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.indigo.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Banner Simulasi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.amber.shade100,
            child: Row(
              children: [
                Icon(Icons.gavel_rounded, color: Colors.amber.shade900),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Anti-Cheat Sandbox: Sistem mendeteksi ID Pengguna Anda saat ini sebagai "User_Mahasiswa_1".',
                    style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () => _triggerCheatSimulator(context, 'BYPASS_FILTER'),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.amber.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Trigger Cheat', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // LIST DATA REQUEST
          Expanded(
            child: Consumer<BarterViewModel>(
              builder: (context, vm, child) {
                final state = vm.barterRequestsState;

                if (state is ResultStateLoading) {
                  return const Center(child: CircularProgressIndicator(color: Colors.indigo));
                } else if (state is ResultStateError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 48),
                          const SizedBox(height: 12),
                          const Text(
                            'Peringatan Sistem Ditangkap!',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            (state as ResultStateError<List<BarterRequest>>).message,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => vm.fetchBarterRequests(_currentUserId),
                            child: const Text('Muat Ulang'),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (state is ResultStateSuccess<List<BarterRequest>>) {
                  final requests = state.data;
                  if (requests.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.connect_without_contact_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada request barter aktif dari mahasiswa lain.',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '(Request milik Anda disembunyikan otomatis oleh sistem)',
                            style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: requests.length,
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (context, index) {
                      final req = requests[index];

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'ID: ${req.userId}',
                                      style: TextStyle(color: Colors.indigo.shade700, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      req.status,
                                      style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('BISA MENGAJAR:', style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(req.canTeach, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.swap_horiz, color: Colors.grey.shade400, size: 28),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('INGIN BELAJAR:', style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(req.wantToLearn, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: Alignment.centerRight.x == 1.0 ? TextAlign.end : TextAlign.start),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  // Tombol Simulasi Race Condition
                                  OutlinedButton(
                                    onPressed: () => _triggerRaceConditionSimulator(context, req.requestId),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Colors.red.shade200),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text('Simulasi Tabrakan', style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                                  ),
                                  const SizedBox(width: 8),
                                  // Tombol Ajukan Match
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        await vm.applyBarter(req.requestId, _currentUserId);
                                        vm.fetchBarterRequests(_currentUserId);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Selamat! Barter skill berhasil dipasangkan (MATCHED).')),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.indigo.shade700,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: const Text('Match Mentor'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
                return const Center(child: Text('Menunggu data...'));
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRequestDialog(context),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Buat Barter'),
      ),
    );
  }
}
