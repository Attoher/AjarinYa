import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ajarin_ya/models/study_spot.dart';
import 'package:ajarin_ya/models/result_state.dart';
import 'package:ajarin_ya/widgets/full_screen_image_viewer.dart';
import 'package:ajarin_ya/services/supabase_storage_service.dart';
import 'package:ajarin_ya/viewmodels/study_spot_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:ajarin_ya/theme/app_theme.dart';
import 'package:ajarin_ya/viewmodels/auth_view_model.dart';

class StudySpotScreen extends StatefulWidget {
  final bool isStandalone;

  const StudySpotScreen({super.key, this.isStandalone = true});

  @override
  State<StudySpotScreen> createState() => _StudySpotScreenState();
}

class _StudySpotScreenState extends State<StudySpotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _mapController = MapController();
  final _imagePicker = ImagePicker();

  double? _selectedLat;
  double? _selectedLng;
  XFile? _selectedSpotImage;
  bool _isUploadingSpot = false;
  String? _lastGroupId;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        _mapController.move(LatLng(pos.latitude, pos.longitude), 16.0);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final activeGroupId = context.read<AuthViewModel>().user?.activeGroupId;
    if (activeGroupId != _lastGroupId) {
      _lastGroupId = activeGroupId;
      if (activeGroupId != null && activeGroupId.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Provider.of<StudySpotViewModel>(context, listen: false).fetchStudySpots(activeGroupId);
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _showAddSpotDialog(BuildContext context, {double? preLat, double? preLng, StudySpot? existingSpot}) {
    double dialogLat = preLat ?? _mapController.camera.center.latitude;
    double dialogLng = preLng ?? _mapController.camera.center.longitude;

    if (existingSpot != null) {
      _nameController.text = existingSpot.name;
      _descController.text = existingSpot.description;
      if (existingSpot.hasValidLocation()) {
        dialogLat = existingSpot.getSafeLatitude();
        dialogLng = existingSpot.getSafeLongitude();
      }
    } else {
      _nameController.clear();
      _descController.clear();
    }
    _selectedSpotImage = null;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Icon(
                    existingSpot == null ? Icons.add_location_alt : Icons.edit_location_alt,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    existingSpot == null ? 'Daftar Spot Baru' : 'Edit Spot',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nama Tempat (Misal: Perpustakaan Lantai 2)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.place),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Nama tempat wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Deskripsi Singkat / Fasilitas',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.description),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Deskripsi wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      // Image picker row
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              final img = await _imagePicker.pickImage(
                                source: ImageSource.camera,
                                imageQuality: 80,
                              );
                              if (img != null) {
                                setDialogState(() => _selectedSpotImage = img);
                              }
                            },
                            icon: const Icon(Icons.image_outlined, size: 16),
                            label: const Text('Foto Spot', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                          if (_selectedSpotImage != null) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedSpotImage!.name,
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setDialogState(() => _selectedSpotImage = null),
                              child: const Icon(Icons.close, size: 16, color: Colors.grey),
                            ),
                          ] else if ((existingSpot?.imageUrl ?? '').isNotEmpty) ...[
                            const SizedBox(width: 8),
                            const Text('Ada foto sebelumnya', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Koordinat Lokasi:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(
                              'Lat: ${dialogLat.toStringAsFixed(6)}  Lng: ${dialogLng.toStringAsFixed(6)}',
                              style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              '*Otomatis dari klik peta',
                              style: TextStyle(fontSize: 10, color: AppTheme.primaryColor, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: _isUploadingSpot ? null : () async {
                    if (!(_formKey.currentState?.validate() ?? false)) return;

                    setDialogState(() => _isUploadingSpot = true);

                    // Capture context-dependent values before any await
                    final authVm = Provider.of<AuthViewModel>(context, listen: false);
                    final vm = Provider.of<StudySpotViewModel>(context, listen: false);
                    final activeGroupId = authVm.user?.activeGroupId;
                    final creatorUid = FirebaseAuth.instance.currentUser?.uid ?? '';
                    final creatorName = authVm.user?.displayName;

                    String? imageUrl = existingSpot?.imageUrl;
                    if (_selectedSpotImage != null) {
                      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
                      imageUrl = await SupabaseStorageService.instance
                          .uploadSpotImage(tempId, _selectedSpotImage!);
                    }

                    final spot = StudySpot(
                      spotId: existingSpot?.spotId ?? '',
                      groupId: activeGroupId,
                      name: _nameController.text.trim(),
                      description: _descController.text.trim(),
                      location: GeoPoint(dialogLat, dialogLng),
                      createdBy: existingSpot?.createdBy ?? creatorUid,
                      createdByName: existingSpot?.createdByName ?? creatorName,
                      createdAt: existingSpot?.createdAt ?? DateTime.now(),
                      imageUrl: imageUrl,
                    );
                    if (existingSpot == null) {
                      await vm.createStudySpot(spot);
                    } else {
                      await vm.updateStudySpot(spot);
                    }

                    setDialogState(() => _isUploadingSpot = false);

                    if (context.mounted) {
                      final state = vm.studySpotsState;
                      if (state is ResultStateError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text((state as ResultStateError).message), backgroundColor: AppTheme.errorColor),
                        );
                      } else {
                        Navigator.pop(dialogCtx);
                        if (activeGroupId != null && activeGroupId.isNotEmpty) {
                          vm.fetchStudySpots(activeGroupId);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(existingSpot == null ? 'Study Spot berhasil didaftarkan!' : 'Study Spot berhasil diperbarui!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isUploadingSpot
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool?> _showConfirmDialog(BuildContext context, String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor, foregroundColor: Colors.white),
            child: const Text('Hapus'),
          ),
        ],
      ),
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
                title: const Text('Study Spot Explorer', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
              const Text('untuk melihat dan berbagi Study Spot.', style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: widget.isStandalone
          ? AppBar(
              title: const Text('Study Spot Explorer', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              backgroundColor: AppTheme.primaryColor,
              iconTheme: const IconThemeData(color: Colors.white),
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Muat ulang data',
                  onPressed: () {
                    final authVm = Provider.of<AuthViewModel>(context, listen: false);
                    final groupId = authVm.user?.activeGroupId;
                    if (groupId != null && groupId.isNotEmpty) {
                      Provider.of<StudySpotViewModel>(context, listen: false).fetchStudySpots(groupId);
                    }
                  },
                )
              ],
            )
          : null,
      body: Consumer<StudySpotViewModel>(
        builder: (context, vm, child) {
          final state = vm.studySpotsState;
          List<StudySpot> spotsList = [];
          if (state is ResultStateSuccess<List<StudySpot>>) {
            spotsList = state.data;
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              final mapWidget = _buildMapWidget(spotsList, isWide: isWide, constraints: constraints);
              final listWidget = _buildSpotsListWidget(state, vm);

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: constraints.maxWidth * 0.42,
                      child: mapWidget,
                    ),
                    Expanded(child: listWidget),
                  ],
                );
              }
              return Column(
                children: [
                  mapWidget,
                  Expanded(child: listWidget),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: widget.isStandalone ? 16.0 : 90.0),
        child: _selectedLat != null && _selectedLng != null
            ? FloatingActionButton.extended(
                heroTag: 'spot_fab_save',
                onPressed: () async {
                  await _showAddSpotDialog(context, preLat: _selectedLat, preLng: _selectedLng);
                  setState(() {
                    _selectedLat = null;
                    _selectedLng = null;
                  });
                },
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.save),
                label: const Text('Simpan Titik Ini'),
              )
            : FloatingActionButton.extended(
                heroTag: 'spot_fab_add',
                onPressed: () => _showAddSpotDialog(context),
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_location_alt),
                label: const Text('Drop Pin Baru'),
              ),
      ),
    );
  }

  Widget _buildMapWidget(List<StudySpot> spotsList, {required bool isWide, required BoxConstraints constraints}) {
    return Container(
      margin: const EdgeInsets.all(12),
      height: isWide ? null : (constraints.maxHeight * 0.3).clamp(180.0, 300.0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(-7.2824, 112.7949),
              initialZoom: 15.0,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
              onTap: (tapPosition, latLng) {
                setState(() {
                  _selectedLat = latLng.latitude;
                  _selectedLng = latLng.longitude;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ajarin_ya',
              ),
              CurrentLocationLayer(),
              MarkerLayer(
                markers: [
                  ...spotsList.where((spot) => spot.hasValidLocation()).map((spot) {
                    return Marker(
                      point: LatLng(spot.getSafeLatitude(), spot.getSafeLongitude()),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${spot.name}\n${spot.description}')),
                          );
                        },
                        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                      ),
                    );
                  }),
                  if (_selectedLat != null && _selectedLng != null)
                    Marker(
                      point: LatLng(_selectedLat!, _selectedLng!),
                      width: 50,
                      height: 50,
                      alignment: Alignment.topCenter,
                      child: const Icon(Icons.person_pin_circle, color: Colors.blueAccent, size: 50),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: FloatingActionButton.small(
              heroTag: 'myLocationBtn',
              backgroundColor: Colors.white,
              onPressed: () async {
                bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                if (!serviceEnabled) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GPS belum diaktifkan')));
                  }
                  return;
                }
                LocationPermission permission = await Geolocator.checkPermission();
                if (permission == LocationPermission.denied) {
                  permission = await Geolocator.requestPermission();
                  if (permission == LocationPermission.denied) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Izin lokasi ditolak')));
                    }
                    return;
                  }
                }
                if (permission == LocationPermission.deniedForever) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Izin lokasi ditolak permanen. Ubah di pengaturan.')));
                  }
                  return;
                }
                final pos = await Geolocator.getCurrentPosition();
                _mapController.move(LatLng(pos.latitude, pos.longitude), 16.0);
                setState(() {
                  _selectedLat = pos.latitude;
                  _selectedLng = pos.longitude;
                });
              },
              child: Icon(Icons.my_location, color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotsListWidget(ResultState state, StudySpotViewModel vm) {
    if (state is ResultStateLoading) {
      return Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    } else if (state is ResultStateError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: AppTheme.errorColor, size: 48),
              const SizedBox(height: 12),
              const Text('Error Memuat Firestore!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              Text(
                (state as ResultStateError<List<StudySpot>>).message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  final authVm = Provider.of<AuthViewModel>(context, listen: false);
                  final activeGroup = authVm.user?.activeGroupId;
                  if (activeGroup != null && activeGroup.isNotEmpty) {
                    vm.fetchStudySpots(activeGroup);
                  }
                },
                child: const Text('Muat Ulang'),
              ),
            ],
          ),
        ),
      );
    } else if (state is ResultStateSuccess<List<StudySpot>>) {
      final spots = state.data;
      if (spots.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.place_outlined, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text('Belum ada lokasi belajar terdaftar.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 4),
              Text('Klik area pada Peta Blueprint di atas untuk drop pin baru!', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
            ],
          ),
        );
      }

      final currentUserId = Provider.of<AuthViewModel>(context, listen: false).user?.uid;

      return ListView.builder(
        itemCount: spots.length,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemBuilder: (context, index) {
          final spot = spots[index];
          final hasGeo = spot.hasValidLocation();

          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            color: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.softShadow,
                border: Border.all(color: Colors.grey.shade100, width: 1),
              ),
              child: ExpansionTile(
                onExpansionChanged: (expanded) {
                  if (expanded && hasGeo) {
                    _mapController.move(
                      LatLng(spot.getSafeLatitude(), spot.getSafeLongitude()),
                      17.0,
                    );
                  }
                },
                leading: CircleAvatar(
                  backgroundColor: hasGeo ? AppTheme.primaryColor.withValues(alpha: 0.1) : AppTheme.errorColor.withValues(alpha: 0.1),
                  child: Icon(
                    hasGeo ? Icons.place : Icons.place_outlined,
                    color: hasGeo ? AppTheme.primaryColor : AppTheme.errorColor,
                    size: 20,
                  ),
                ),
                title: Text(
                  spot.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  spot.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spot.description,
                          style: TextStyle(color: Colors.grey.shade800, fontSize: 12, height: 1.4),
                        ),
                        if ((spot.imageUrl ?? '').isNotEmpty) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => FullScreenImageViewer(imageUrl: spot.imageUrl!, heroTag: 'spot_${spot.spotId}'),
                                ));
                              },
                              child: Hero(
                                tag: 'spot_${spot.spotId}',
                                child: Image.network(
                                  spot.imageUrl!,
                                  width: double.infinity,
                                  height: 140,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, e, s) => Container(
                                    height: 60,
                                    color: AppTheme.primaryColor.withValues(alpha: 0.05),
                                    alignment: Alignment.center,
                                    child: const Text('Foto tidak dapat dimuat', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dibuat oleh: ${spot.createdByName ?? spot.createdBy}',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                                ),
                                if (spot.createdAt != null)
                                  Text(
                                    '${spot.createdAt!.day.toString().padLeft(2, '0')}/'
                                    '${spot.createdAt!.month.toString().padLeft(2, '0')}/'
                                    '${spot.createdAt!.year}  '
                                    '${spot.createdAt!.hour.toString().padLeft(2, '0')}:'
                                    '${spot.createdAt!.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                                  ),
                              ],
                            ),
                            if (spot.createdBy == currentUserId)
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      _showAddSpotDialog(context, existingSpot: spot);
                                    },
                                    icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor, size: 14),
                                    label: const Text('Edit', style: TextStyle(color: AppTheme.primaryColor, fontSize: 11)),
                                  ),
                                  TextButton.icon(
                                    onPressed: () async {
                                      final activeGroup = Provider.of<AuthViewModel>(context, listen: false).user?.activeGroupId;
                                      final confirm = await _showConfirmDialog(context, 'Hapus', 'Yakin menghapus spot ini?');
                                      if (confirm == true) {
                                        await vm.deleteStudySpot(spot.spotId);
                                        if (activeGroup != null && activeGroup.isNotEmpty) {
                                          vm.fetchStudySpots(activeGroup);
                                        }
                                        if (context.mounted) {
                                          final state = vm.crudActionState;
                                          if (state is ResultStateError) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text((state).message), backgroundColor: AppTheme.errorColor),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Study Spot berhasil dihapus dari Firestore.')),
                                            );
                                          }
                                          vm.resetCrudActionState();
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 14),
                                    label: const Text('Hapus', style: TextStyle(color: AppTheme.errorColor, fontSize: 11)),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        },
      );
    }
    return const Center(child: Text('Menyiapkan data...'));
  }
}
