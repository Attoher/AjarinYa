import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ajarin_ya/viewmodels/auth_view_model.dart';

class GroupGateScreen extends StatefulWidget {
  final bool isFromProfile;
  const GroupGateScreen({super.key, this.isFromProfile = false});

  @override
  State<GroupGateScreen> createState() => _GroupGateScreenState();
}

class _GroupGateScreenState extends State<GroupGateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _joinGroup() async {
    if (!_formKey.currentState!.validate()) return;
    
    final code = _codeController.text.trim();
    final authVm = Provider.of<AuthViewModel>(context, listen: false);
    final success = await authVm.joinGroup(code, groupName: 'Grup $code');
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authVm.errorMessage ?? 'Gagal bergabung ke grup')),
      );
    } else if (success && mounted && widget.isFromProfile) {
      Navigator.pop(context);
    }
  }

  void _createGroup() async {
    final nameController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();
    
    final groupName = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.add_circle, color: Color(0xFF0D47A1)),
              const SizedBox(width: 8),
              const Text('Buat Grup Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Form(
            key: dialogFormKey,
            child: TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nama Grup Studi',
                hintText: 'Contoh: Belajar Kalkulus, Coding Asik',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Nama grup tidak boleh kosong';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (dialogFormKey.currentState!.validate()) {
                  Navigator.pop(dialogCtx, nameController.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Buat'),
            ),
          ],
        );
      },
    );

    if (groupName == null || groupName.isEmpty) return;

    if (!mounted) return;
    final authVm = Provider.of<AuthViewModel>(context, listen: false);
    final success = await authVm.createGroup(groupName);
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authVm.errorMessage ?? 'Gagal membuat grup')),
      );
    } else if (success && mounted && widget.isFromProfile) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Bergabung ke Grup'),
        leading: widget.isFromProfile ? const BackButton() : null,
        actions: [
          if (!widget.isFromProfile)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => authVm.logout(),
              tooltip: 'Logout',
            )
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.group_add,
                  size: 80,
                  color: Color(0xFF0D47A1),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Satu Langkah Lagi!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Masukkan 6 digit kode grup studi Anda untuk mulai berdiskusi dan bertukar skill.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 36),
                
                // Form Join Group
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: '000000',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade300,
                              letterSpacing: 8,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF5F7FA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 1.5),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.length != 6) {
                              return 'Kode harus 6 digit angka';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: authVm.isLoading ? null : _joinGroup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D47A1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: authVm.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Gabung Grup',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'ATAU',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Create Group Button
                OutlinedButton.icon(
                  onPressed: authVm.isLoading ? null : _createGroup,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Buat Grup Baru'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0D47A1),
                    side: const BorderSide(color: Color(0xFF0D47A1)),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}
