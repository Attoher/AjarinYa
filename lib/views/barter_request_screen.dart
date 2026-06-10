import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ajarin_ya/models/barter_request.dart';
import 'package:ajarin_ya/models/result_state.dart';
import 'package:ajarin_ya/viewmodels/barter_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ajarin_ya/theme/app_theme.dart';
import 'package:ajarin_ya/viewmodels/auth_view_model.dart';

import 'package:ajarin_ya/views/private_chat_screen.dart';

class BarterRequestScreen extends StatefulWidget {
  final bool isStandalone;

  const BarterRequestScreen({super.key, this.isStandalone = true});

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
      if (!mounted) return;
      final authVm = context.read<AuthViewModel>();
      final activeGroupId = authVm.user?.activeGroupId;
      if (activeGroupId != null && activeGroupId.isNotEmpty) {
        barterViewModel.fetchBarterRequests(_currentUserId, activeGroupId);
      }
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
              Icon(existingRequest == null ? Icons.handshake_outlined : Icons.edit_note, color: AppTheme.primaryColor),
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
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  final authVm = Provider.of<AuthViewModel>(context, listen: false);
                  final activeGroupId = authVm.user?.activeGroupId;
                  final currentUserName = authVm.user?.displayName;

                  final request = BarterRequest(
                    requestId: existingRequest?.requestId ?? '',
                    groupId: activeGroupId,
                    userId: _currentUserId,
                    userName: currentUserName,
                    canTeach: _canTeachController.text,
                    wantToLearn: _wantToLearnController.text,
                    status: existingRequest?.status ?? 'PENDING',
                    matchedWith: existingRequest?.matchedWith,
                  );

                  final vm = Provider.of<BarterViewModel>(context, listen: false);
                  if (existingRequest == null) {
                    await vm.createBarterRequest(request);
                  } else {
                    await vm.updateBarterRequest(request);
                  }

                  if (context.mounted) {
                    Navigator.pop(dialogCtx);
                    final freshGroupId = Provider.of<AuthViewModel>(context, listen: false).user?.activeGroupId;
                    if (freshGroupId != null && freshGroupId.isNotEmpty) {
                      vm.fetchBarterRequests(_currentUserId, freshGroupId);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(existingRequest == null ? 'Request barter Anda sukses dipublikasikan!' : 'Request barter berhasil diperbarui!')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
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
    final activeGroupId = context.watch<AuthViewModel>().user?.activeGroupId;

    if (activeGroupId == null || activeGroupId.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: widget.isStandalone
            ? AppBar(
                title: const Text('Barter Skill', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                backgroundColor: AppTheme.primaryColor,
                iconTheme: const IconThemeData(color: Colors.white),
                elevation: 0,
              )
            : null,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group_off, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('Silakan pilih atau gabung grup terlebih dahulu', style: TextStyle(fontSize: 16)),
              const Text('untuk melihat dan berbagi Skill Barter.', style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: widget.isStandalone
          ? AppBar(
              title: const Text('Barter Skill', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              backgroundColor: AppTheme.primaryColor,
              iconTheme: const IconThemeData(color: Colors.white),
              elevation: 0,
            )
          : null,
      body: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: Consumer<BarterViewModel>(
              builder: (context, vm, child) {
                final state = vm.barterRequestsState;
                final matchedState = vm.matchedRequestsState;

                if (state is ResultStateIdle || state is ResultStateLoading ||
                    matchedState is ResultStateLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                } else if (state is ResultStateError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: AppTheme.errorColor, size: 48),
                          const SizedBox(height: 12),
                          const Text('Peringatan Sistem Ditangkap!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text(
                            (state as ResultStateError<List<BarterRequest>>).message,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              final activeGroup = context.read<AuthViewModel>().user?.activeGroupId;
                              if (activeGroup != null && activeGroup.isNotEmpty) {
                                vm.fetchBarterRequests(_currentUserId, activeGroup);
                              }
                            },
                            child: const Text('Muat Ulang'),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (state is ResultStateSuccess<List<BarterRequest>>) {
                  final requests = state.data;
                  final matchedRequests = matchedState is ResultStateSuccess<List<BarterRequest>>
                      ? matchedState.data
                      : <BarterRequest>[];

                  if (requests.isEmpty && matchedRequests.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.connect_without_contact_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada request barter atau riwayat match.',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tekan tombol "Buat Barter" untuk mulai!',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }

                  final myRequests = requests.where((r) => r.userId == _currentUserId).toList();
                  final otherRequests = requests.where((r) => r.userId != _currentUserId).toList();

                  return LayoutBuilder(
                    builder: (ctx, constraints) {
                      final isWide = constraints.maxWidth >= 600;
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                        children: [
                          if (myRequests.isNotEmpty) ...[
                            _sectionHeader('Request Saya', topPadding: 8),
                            ..._buildAdaptiveCards(myRequests, true, vm, context, isWide: isWide),
                          ],
                          if (otherRequests.isNotEmpty) ...[
                            _sectionHeader('Tersedia untuk Barter', topPadding: 16),
                            ..._buildAdaptiveCards(otherRequests, false, vm, context, isWide: isWide),
                          ],
                          if (matchedRequests.isNotEmpty) ...[
                            _sectionHeader('Riwayat Match Saya', topPadding: 16),
                            ..._buildAdaptiveCards(
                              matchedRequests,
                              null,
                              vm,
                              context,
                              isWide: isWide,
                              isMatchedSection: true,
                            ),
                          ],
                        ],
                      );
                    },
                  );
                }
                return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: widget.isStandalone ? 16.0 : 90.0),
        child: FloatingActionButton.extended(
          heroTag: 'barter_fab',
          onPressed: () => _showAddRequestDialog(context),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Buat Barter'),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, {double topPadding = 8}) {
    return Padding(
      padding: EdgeInsets.only(left: 4, bottom: 8, top: topPadding),
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryDark),
      ),
    );
  }

  List<Widget> _buildAdaptiveCards(
    List<BarterRequest> items,
    bool? isMine,
    BarterViewModel vm,
    BuildContext context, {
    required bool isWide,
    bool isMatchedSection = false,
  }) {
    Widget card(BarterRequest req) {
      final mine = isMine ?? (req.userId == _currentUserId);
      return _buildRequestCard(req, mine, vm, context, isMatched: isMatchedSection);
    }

    if (!isWide) {
      return items.map(card).toList();
    }

    final widgets = <Widget>[];
    for (int i = 0; i < items.length; i += 2) {
      if (i + 1 < items.length) {
        widgets.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: card(items[i])),
                const SizedBox(width: 8),
                Expanded(child: card(items[i + 1])),
              ],
            ),
          ),
        );
      } else {
        widgets.add(Row(
          children: [
            Expanded(child: card(items[i])),
            const Expanded(child: SizedBox()),
          ],
        ));
      }
    }
    return widgets;
  }

  Widget _buildRequestCard(BarterRequest req, bool isMine, BarterViewModel vm, BuildContext context, {bool isMatched = false}) {
    final displayName = req.userName ?? 'Pengguna';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: isMine
                          ? AppTheme.primaryColor.withValues(alpha: 0.15)
                          : AppTheme.accentColor.withValues(alpha: 0.15),
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isMine ? AppTheme.primaryColor : AppTheme.accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isMine ? 'Saya ($displayName)' : displayName,
                      style: TextStyle(
                        color: isMine ? AppTheme.primaryColor : AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isMatched ? Colors.green.shade50 : AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    req.status,
                    style: TextStyle(
                      color: isMatched ? Colors.green.shade700 : AppTheme.primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
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
              Column(
                children: [
                  _buildMatchedBadge(req),
                  if (req.userId == _currentUserId || req.matchedWith == _currentUserId)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PrivateChatScreen(barterRequest: req),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Buka Chat Barter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
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
                        final activeGroup = context.read<AuthViewModel>().user?.activeGroupId;
                        await vm.deleteBarterRequest(req.requestId);
                        if (activeGroup != null && activeGroup.isNotEmpty) {
                          vm.fetchBarterRequests(_currentUserId, activeGroup);
                        }
                        if (context.mounted) {
                          final state = vm.crudActionState;
                          if (state is ResultStateError) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text((state).message), backgroundColor: AppTheme.errorColor),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Request barter Anda berhasil dihapus.')),
                            );
                          }
                          vm.resetCrudActionState();
                        }
                      },
                      icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                      label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              )
            else
              Consumer<BarterViewModel>(
                builder: (context, matchVm, _) {
                  final isMatching = matchVm.crudActionState is ResultStateLoading;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isMatching
                          ? null
                          : () async {
                              final activeGroup = context.read<AuthViewModel>().user?.activeGroupId;
                              await matchVm.applyBarter(req.requestId, _currentUserId);
                              if (activeGroup != null && activeGroup.isNotEmpty) {
                                matchVm.fetchBarterRequests(_currentUserId, activeGroup);
                              }
                              if (context.mounted) {
                                final resultState = matchVm.crudActionState;
                                if (resultState is ResultStateError) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text((resultState).message),
                                      backgroundColor: AppTheme.errorColor,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle, color: Colors.white, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text('Selamat! Kamu berhasil match barter dengan $displayName!'),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                                matchVm.resetCrudActionState();
                              }
                            },
                      icon: isMatching
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.handshake_outlined, size: 18),
                      label: Text(isMatching ? 'Memproses...' : 'Match Mentor'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchedBadge(BarterRequest req) {
    final isOriginalPoster = req.userId == _currentUserId;
    final partnerName = isOriginalPoster
        ? 'seseorang'
        : (req.userName ?? 'pengguna lain');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isOriginalPoster
                  ? 'Request kamu telah diambil oleh $partnerName!'
                  : 'Kamu berhasil match barter dengan $partnerName!',
              style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
