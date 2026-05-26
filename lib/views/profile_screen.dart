import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ajarin_ya/viewmodels/auth_view_model.dart';
import 'package:ajarin_ya/views/group_gate_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showGroupMembers(BuildContext context, String groupId, String groupName) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Anggota $groupName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('groups').doc(groupId).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Terjadi kesalahan memuat data grup.'));
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Grup ini dibuat dengan format lama. Harap buat ulang grup untuk melihat anggota.'));
                }

                final groupData = snapshot.data!.data() as Map<String, dynamic>;
                final leaderId = groupData['leaderId'] as String?;
                final memberIds = List<String>.from(groupData['memberIds'] ?? []);

                if (memberIds.isEmpty) {
                  return const Center(child: Text('Tidak ada anggota.'));
                }

                return FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance.collection('users').where('uid', whereIn: memberIds).get(),
                  builder: (ctx, userSnap) {
                    if (userSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (userSnap.hasError) {
                      return const Center(child: Text('Terjadi kesalahan memuat data anggota.'));
                    }
                    final users = userSnap.data?.docs ?? [];
                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final userData = users[index].data() as Map<String, dynamic>;
                        final uid = userData['uid'];
                        final name = userData['displayName'] ?? 'User Tanpa Nama';
                        final isLeader = uid == leaderId;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isLeader ? Colors.amber.shade100 : Colors.indigo.shade50,
                            child: Icon(
                              isLeader ? Icons.star : Icons.person,
                              color: isLeader ? Colors.amber.shade800 : Colors.indigo,
                            ),
                          ),
                          title: Text(name, style: TextStyle(fontWeight: isLeader ? FontWeight.bold : FontWeight.normal)),
                          subtitle: isLeader ? Text('Leader', style: TextStyle(color: Colors.amber.shade800, fontSize: 12, fontWeight: FontWeight.bold)) : null,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final user = authViewModel.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Tidak ada pengguna yang masuk.')),
      );
    }

    final String displayName = user.displayName;
    final String email = user.email;
    final String initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M';
    final List<String> groups = user.groupIds;
    final String? activeGroup = user.activeGroupId;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Profil & Grup', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // User Info Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFFE3F2FD),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Logout'),
                            content: const Text('Yakin ingin keluar?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, true), 
                                  child: const Text('Keluar', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          await authViewModel.logout();
                          if (context.mounted) {
                            Navigator.pop(context); // close profile screen
                          }
                        }
                      },
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text('Logout', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Groups Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Grup Anda',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GroupGateScreen(isFromProfile: true),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Gabung'),
                )
              ],
            ),
            const SizedBox(height: 12),
            
            if (groups.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: const Center(
                  child: Text(
                    'Anda belum bergabung ke grup manapun.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...groups.map((gId) {
                final isActive = gId == activeGroup;
                final groupName = user.groupNames[gId] ?? 'Grup $gId';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFE3F2FD) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive ? const Color(0xFF0D47A1) : Colors.grey.shade200,
                      width: isActive ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      'ID: $gId • ${isActive ? "Aktif" : "Ketuk untuk pindah"}',
                      style: TextStyle(
                        color: isActive ? const Color(0xFF0D47A1) : Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.people, color: Color(0xFF0D47A1)),
                          tooltip: 'Lihat Anggota',
                          onPressed: () => _showGroupMembers(context, gId, groupName),
                        ),
                        if (!isActive)
                          IconButton(
                            icon: const Icon(Icons.exit_to_app, color: Colors.red),
                            tooltip: 'Tinggalkan Grup',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Tinggalkan Grup'),
                                  content: Text('Yakin ingin meninggalkan grup "$groupName" ($gId)?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true), 
                                      child: const Text('Tinggalkan', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                authViewModel.leaveGroup(gId);
                              }
                            },
                          ),
                      ],
                    ),
                    onTap: () {
                      if (!isActive) {
                        authViewModel.switchActiveGroup(gId);
                      }
                    },
                  ),
                );
              }),
          ],
        ),
      ),
      ),
      ),
    );
  }
}
