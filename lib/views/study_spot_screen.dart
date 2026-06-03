import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ajarin_ya/models/study_spot.dart';
import 'package:ajarin_ya/models/result_state.dart';
import 'package:ajarin_ya/viewmodels/study_spot_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:ajarin_ya/theme/app_theme.dart';
import 'package:ajarin_ya/viewmodels/auth_view_model.dart';

class StudySpotScreen extends StatefulWidget {
  const StudySpotScreen({super.key});

  @override
  State<StudySpotScreen> createState() => _StudySpotScreenState();
}

class _StudySpotScreenState extends State<StudySpotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _mapController = MapController();

  double? _selectedLat;
  double? _selectedLng;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVm = Provider.of<AuthViewModel>(context, listen: false);
      final activeGroupId = authVm.user?.activeGroupId;
      if (activeGroupId != null && activeGroupId.isNotEmpty) {
        Provider.of<StudySpotViewModel>(context, listen: false).fetchStudySpots(activeGroupId);
      }
    });
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
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
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
                      labelText: 'Deskripsi Singkat / Fasilitas (Misal: Ada colokan, AC dingin)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.description),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Deskripsi wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Koordinat Lokasi:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          'Latitude: ${dialogLat.toStringAsFixed(6)}\nLongitude: ${dialogLng.toStringAsFixed(6)}',
                          style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '*Koordinat terdeteksi otomatis dari klik peta Anda',
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
              onPressed: () {
                Navigator.pop(dialogCtx);
              },
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  final authVm = Provider.of<AuthViewModel>(context, listen: false);
                  final activeGroupId = authVm.user?.activeGroupId;

                  final spot = StudySpot(
                    spotId: existingSpot?.spotId ?? '',
                    groupId: activeGroupId,
                    name: _nameController.text,
                    description: _descController.text,
                    location: GeoPoint(dialogLat, dialogLng),
                    createdBy: existingSpot?.createdBy ?? FirebaseAuth.instance.currentUser?.uid ?? '',
                  );

                  final vm = Provider.of<StudySpotViewModel>(context, listen: false);
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menyimpan...'), duration: Duration(seconds: 1)));
                  }

                  if (existingSpot == null) {
                    await vm.createStudySpot(spot);
                  } else {
                    await vm.updateStudySpot(spot);
                  }
                  
                  if (context.mounted) {
                    final state = vm.studySpotsState;
                    if (state is ResultStateError) {
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text((state as ResultStateError).message), backgroundColor: AppTheme.errorColor),
                       );
                    } else {
                       Navigator.pop(dialogCtx);
                       final activeGroupId = Provider.of<AuthViewModel>(context, listen: false).user?.activeGroupId;
                       if (activeGroupId != null && activeGroupId.isNotEmpty) {
                         vm.fetchStudySpots(activeGroupId);
                       }
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text(existingSpot == null ? 'Study Spot berhasil didaftarkan ke Firestore!' : 'Study Spot berhasil diperbarui!'), backgroundColor: Colors.green),
                       );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Simpan'),
            ),
          ],
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
        appBar: AppBar(
          title: const Text('Study Spot Explorer', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: AppTheme.primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
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
      appBar: AppBar(
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
      ),
      body: Consumer<StudySpotViewModel>(
        builder: (context, vm, child) {
          final state = vm.studySpotsState;
          
          List<StudySpot> spotsList = [];
          if (state is ResultStateSuccess<List<StudySpot>>) {
            spotsList = state.data;
          }

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.all(12),
                height: MediaQuery.of(context).size.height * 0.3,
                constraints: const BoxConstraints(minHeight: 180, maxHeight: 300),
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
                        initialCenter: const LatLng(-7.2824, 112.7949), // ITS Campus
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
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GPS belum diaktifkan')));
                            }
                            return;
                          }
                          LocationPermission permission = await Geolocator.checkPermission();
                          if (permission == LocationPermission.denied) {
                            permission = await Geolocator.requestPermission();
                            if (permission == LocationPermission.denied) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Izin lokasi ditolak')));
                              }
                              return;
                            }
                          }
                          if (permission == LocationPermission.deniedForever) {
                            if (context.mounted) {
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
              ),

              Expanded(
                child: _buildSpotsListWidget(state, vm),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _selectedLat != null && _selectedLng != null
          ? Padding(
              padding: const EdgeInsets.only(bottom: 90.0),
              child: FloatingActionButton.extended(
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
              ),
            )
          : Padding(
              padding: const EdgeInsets.only(bottom: 90.0),
              child: FloatingActionButton.extended(
                onPressed: () => _showAddSpotDialog(context),
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_location_alt),
                label: const Text('Drop Pin Baru'),
              ),
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

      return ListView.builder(
        itemCount: spots.length,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
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
                  backgroundColor: hasGeo ? AppTheme.primaryColor.withOpacity(0.1) : AppTheme.errorColor.withOpacity(0.1),
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
                  'Koordinat: ${spot.getSafeLatitude().toStringAsFixed(5)}, ${spot.getSafeLongitude().toStringAsFixed(5)}',
                  style: TextStyle(
                    color: hasGeo ? Colors.grey.shade600 : Colors.red.shade800,
                    fontSize: 11,
                    fontWeight: hasGeo ? FontWeight.normal : FontWeight.bold,
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
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Dibuat oleh: ${spot.createdBy}',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                            ),
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
                                    final confirm = await _showConfirmDialog(context, 'Hapus', 'Yakin menghapus spot ini?');
                                    if (confirm == true) {
                                      vm.deleteStudySpot(spot.spotId);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Study Spot berhasil dihapus dari Firestore.')),
                                        );
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
