import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ajarin_ya/models/barter_request.dart';
import 'package:ajarin_ya/models/result_state.dart';
import 'package:ajarin_ya/viewmodels/barter_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BarterRequestScreen extends StatefulWidget {
  const BarterRequestScreen({super.key});

  @override
  State<BarterRequestScreen> createState() => _BarterRequestScreenState();
}

class _BarterRequestScreenState extends State<BarterRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _canTeachController = TextEditingController();
  final _wantToLearnController = TextEditingController();
  
  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

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

  void _showAddRequestDialog(BuildContext context, {BarterRequest? existingRequest}) {
    if (existingRequest != null) {
      _canTeachController.text = existingRequest.canTeach;
      _wantToLearnController.text = existingRequest.wantToLearn;
    } else {
      _canTeachController.clear();
      _wantToLearnController.clear();
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(existingRequest == null ? Icons.handshake_outlined : Icons.edit_note, color: Colors.indigo.shade700),
              const SizedBox(width: 8),
              Text(existingRequest == null ? 'Buat Barter Skill' : 'Edit Barter Skill', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    requestId: existingRequest?.requestId ?? '',
                    userId: _currentUserId,
                    canTeach: _canTeachController.text,
                    wantToLearn: _wantToLearnController.text,
                    status: existingRequest?.status ?? 'PENDING',
                  );

                  final vm = Provider.of<BarterViewModel>(context, listen: false);
                  if (existingRequest == null) {
                    await vm.createBarterRequest(request);
                  } else {
                    await vm.updateBarterRequest(request);
                  }

                  if (context.mounted) {
                    Navigator.pop(dialogCtx);
                    vm.fetchBarterRequests(_currentUserId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(existingRequest == null ? 'Request barter Anda sukses dipublikasikan!' : 'Request barter berhasil diperbarui!')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(existingRequest == null ? 'Publikasikan' : 'Simpan'),
            ),
          ],
        );
      },
    );
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

          const Divider(height: 1),

          // LIST DATA REQUEST
          Expanded(
            child: Consumer<BarterViewModel>(
              builder: (context, vm, child) {
                final state = vm.barterRequestsState;
                final matchedState = vm.matchedRequestsState;

                if (state is ResultStateLoading || matchedState is ResultStateLoading) {
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
                } else if (state is ResultStateSuccess<List<BarterRequest>> && matchedState is ResultStateSuccess<List<BarterRequest>>) {
                  final requests = state.data;
                  final matchedRequests = matchedState.data;

                  if (requests.isEmpty && matchedRequests.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.connect_without_contact_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada request barter atau riwayat match Anda.',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  }

                  final myRequests = requests.where((r) => r.userId == _currentUserId).toList();
                  final otherRequests = requests.where((r) => r.userId != _currentUserId).toList();

                  return ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      if (myRequests.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
                          child: Text('Request Saya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo.shade900)),
                        ),
                        ...myRequests.map((req) => _buildRequestCard(req, true, vm, context)),
                      ],
                      if (otherRequests.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
                          child: Text('Tersedia untuk Barter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo.shade900)),
                        ),
                        ...otherRequests.map((req) => _buildRequestCard(req, false, vm, context)),
                      ],
                      if (matchedRequests.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
                          child: Text('Riwayat Match Saya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo.shade900)),
                        ),
                        ...matchedRequests.map((req) => _buildRequestCard(req, req.userId == _currentUserId, vm, context, isMatched: true)),
                      ],
                    ],
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

  Widget _buildRequestCard(BarterRequest req, bool isMine, BarterViewModel vm, BuildContext context, {bool isMatched = false}) {
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
                      Text(req.wantToLearn, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.end, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isMatched)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        'Matched dengan ID: ${req.userId == _currentUserId ? req.matchedWith : req.userId}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              )
            else if (isMine)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showAddRequestDialog(context, existingRequest: req),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await vm.deleteBarterRequest(req.requestId);
                        vm.fetchBarterRequests(_currentUserId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Request barter Anda berhasil dihapus.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                      label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
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
  }
}
