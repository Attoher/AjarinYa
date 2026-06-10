import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ajarin_ya/config/supabase_config.dart';
import 'package:ajarin_ya/services/supabase_storage_service.dart';
import 'package:ajarin_ya/viewmodels/auth_view_model.dart';
import 'package:ajarin_ya/views/group_gate_screen.dart';
import 'package:ajarin_ya/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _imagePicker = ImagePicker();
  bool _isUploadingAvatar = false;

  Future<void> _pickAndUploadAvatar(AuthViewModel authVm) async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null || !mounted) return;
    setState(() => _isUploadingAvatar = true);
    try {
      final url = await SupabaseStorageService.instance.uploadOrThrow(
        SupabaseConfig.bucketAvatars,
        'user_${authVm.user!.uid}',
        image,
      );
      await authVm.updateAvatarUrl(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diperbarui.')),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('Bucket not found')
            ? 'Bucket "avatars" belum dibuat di Supabase Storage.'
            : e.toString().contains('row-level security') || e.toString().contains('new row violates')
                ? 'Akses ditolak — periksa RLS policy di Supabase.'
                : 'Upload gagal: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _showGroupMembers(
      BuildContext context, String groupId, String groupName, String currentUserId) async {
    showDialog(
      context: context,
      builder: (ctx) => _GroupMembersDialog(
        groupId: groupId,
        groupName: groupName,
        currentUserId: currentUserId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final user = authViewModel.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final String displayName = user.displayName;
    final String email = user.email;
    final String initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    final List<String> groups = user.groupIds;
    final String? activeGroup = user.activeGroupId;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── User card ──────────────────────────────────────────────
                _UserCard(
                  displayName: displayName,
                  email: email,
                  initial: initial,
                  avatarUrl: user.avatarUrl,
                  isUploadingAvatar: _isUploadingAvatar,
                  onAvatarTap: () => _pickAndUploadAvatar(authViewModel),
                  onLogout: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Yakin ingin keluar dari akun?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Keluar',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      await authViewModel.logout();
                    }
                  },
                ),
                const SizedBox(height: 28),

                // ── Groups header ──────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Grup Belajar',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        _GroupActionButton(
                          icon: Icons.add,
                          label: 'Buat',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const GroupGateScreen(isFromProfile: true),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _GroupActionButton(
                          icon: Icons.group_add_outlined,
                          label: 'Gabung',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const GroupGateScreen(isFromProfile: true),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Group list ─────────────────────────────────────────────
                if (groups.isEmpty)
                  _EmptyGroupCard()
                else
                  ...([...groups]..sort((a, b) {
                      if (a == activeGroup) return -1;
                      if (b == activeGroup) return 1;
                      return 0;
                    })).map((gId) {
                    final isActive = gId == activeGroup;
                    final groupName = user.groupNames[gId] ?? 'Grup $gId';
                    return _GroupCard(
                      groupId: gId,
                      groupName: groupName,
                      isActive: isActive,
                      currentUserId: user.uid,
                      onSwitch: () => authViewModel.switchActiveGroup(gId),
                      onLeave: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Tinggalkan Grup'),
                            content: Text(
                                'Yakin ingin meninggalkan "$groupName"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Batal'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Tinggalkan',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) authViewModel.leaveGroup(gId);
                      },
                      onViewMembers: () =>
                          _showGroupMembers(context, gId, groupName, user.uid),
                    );
                  }),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final String displayName;
  final String email;
  final String initial;
  final String avatarUrl;
  final bool isUploadingAvatar;
  final VoidCallback onAvatarTap;
  final VoidCallback onLogout;

  const _UserCard({
    required this.displayName,
    required this.email,
    required this.initial,
    required this.avatarUrl,
    required this.isUploadingAvatar,
    required this.onAvatarTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: isUploadingAvatar ? null : onAvatarTap,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: isUploadingAvatar
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : avatarUrl.isNotEmpty
                          ? Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, e, s) => Center(
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                ),
                if (!isUploadingAvatar)
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child:
                        const Icon(Icons.camera_alt, color: Colors.white, size: 10),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Name + email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Logout button
          IconButton(
            onPressed: onLogout,
            icon: const Icon(Icons.logout, color: Colors.red, size: 20),
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }
}

class _GroupActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GroupActionButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.primaryColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyGroupCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.group_outlined, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(
            'Belum bergabung ke grup manapun.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Buat atau gabung grup untuk mulai belajar bersama.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final String groupId;
  final String groupName;
  final bool isActive;
  final String currentUserId;
  final VoidCallback onSwitch;
  final VoidCallback onLeave;
  final VoidCallback onViewMembers;

  const _GroupCard({
    required this.groupId,
    required this.groupName,
    required this.isActive,
    required this.currentUserId,
    required this.onSwitch,
    required this.onLeave,
    required this.onViewMembers,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isActive
            ? AppTheme.primaryColor.withValues(alpha: 0.06)
            : Colors.white,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: isActive ? null : onSwitch,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive
                    ? AppTheme.primaryColor.withValues(alpha: 0.5)
                    : Colors.grey.shade200,
                width: isActive ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.primaryColor
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.group_rounded,
                    color: isActive ? Colors.white : Colors.grey.shade500,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Name + status + kode grup
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        groupName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isActive
                              ? AppTheme.primaryColor
                              : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (isActive) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Aktif',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ] else
                            Text(
                              'Ketuk untuk aktifkan',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Kode grup — ketuk untuk salin
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: groupId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Kode grup "$groupId" disalin!'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Kode: $groupId',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontFamily: 'monospace',
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.copy_outlined,
                                size: 11, color: Colors.grey.shade500),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions
                IconButton(
                  icon: Icon(Icons.people_outline,
                      size: 18,
                      color: isActive
                          ? AppTheme.primaryColor
                          : Colors.grey.shade600),
                  tooltip: 'Lihat Anggota',
                  onPressed: onViewMembers,
                ),
                if (isActive)
                  IconButton(
                    icon: const Icon(Icons.exit_to_app,
                        size: 18, color: Colors.red),
                    tooltip: 'Tinggalkan Grup',
                    onPressed: onLeave,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Group members dialog — uses documentId lookup (no uid field dependency)
// ─────────────────────────────────────────────────────────────────────────────

class _GroupMembersDialog extends StatelessWidget {
  final String groupId;
  final String groupName;
  final String currentUserId;

  const _GroupMembersDialog({
    required this.groupId,
    required this.groupName,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        groupName,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
      ),
      contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      content: SizedBox(
        width: double.maxFinite,
        height: 320,
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('groups')
              .doc(groupId)
              .get(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError || !snap.hasData) {
              return _errorBody(
                  snap.hasError ? snap.error.toString() : 'Grup tidak ditemukan.');
            }
            if (!snap.data!.exists) {
              return _infoBody(
                  'Data grup belum tersedia.\nCoba buat ulang grup dari menu "Buat".');
            }

            final groupData = snap.data!.data() as Map<String, dynamic>;
            final leaderId = groupData['leaderId'] as String?;
            final memberIds =
                List<String>.from(groupData['memberIds'] ?? []);

            if (memberIds.isEmpty) {
              return _infoBody('Belum ada anggota di grup ini.');
            }

            // Query by document ID — more reliable than querying by uid field
            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .where(FieldPath.documentId, whereIn: memberIds)
                  .get(),
              builder: (ctx, userSnap) {
                if (userSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (userSnap.hasError) {
                  return _errorBody(userSnap.error.toString());
                }

                final docs = userSnap.data?.docs ?? [];

                // Build a map docId → displayName for fast lookup
                final nameMap = {
                  for (final d in docs)
                    d.id: (d.data() as Map<String, dynamic>)['displayName']
                            as String? ??
                        'Pengguna'
                };

                return ListView.builder(
                  itemCount: memberIds.length,
                  itemBuilder: (context, i) {
                    final uid = memberIds[i];
                    final name = nameMap[uid] ?? 'Pengguna';
                    final isLeader = uid == leaderId;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isLeader
                            ? Colors.amber.shade100
                            : AppTheme.primaryColor.withValues(alpha: 0.1),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: TextStyle(
                            color: isLeader
                                ? Colors.amber.shade900
                                : AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      title: Text(name,
                          style: TextStyle(
                              fontWeight: isLeader
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                      subtitle: isLeader
                          ? Text('Leader',
                              style: TextStyle(
                                  color: Colors.amber.shade800,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold))
                          : null,
                      trailing: (currentUserId == leaderId && uid != leaderId)
                          ? IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: Colors.red, size: 18),
                              tooltip: 'Keluarkan',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Keluarkan Anggota'),
                                    content: Text('Keluarkan $name dari grup?'),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Batal')),
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text('Keluarkan',
                                              style: TextStyle(
                                                  color: Colors.red))),
                                    ],
                                  ),
                                );
                                if (confirm == true && context.mounted) {
                                  await FirebaseFirestore.instance
                                      .collection('groups')
                                      .doc(groupId)
                                      .update({
                                    'memberIds':
                                        FieldValue.arrayRemove([uid])
                                  });
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(uid)
                                      .update({
                                    'groupIds':
                                        FieldValue.arrayRemove([groupId])
                                  });
                                  if (context.mounted) Navigator.pop(context);
                                }
                              },
                            )
                          : null,
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }

  Widget _errorBody(String message) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 36),
            const SizedBox(height: 10),
            const Text('Gagal memuat anggota.',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _infoBody(String message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
}
