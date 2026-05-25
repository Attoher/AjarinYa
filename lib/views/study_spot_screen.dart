import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ajarin_ya/models/study_spot.dart';
import 'package:ajarin_ya/models/result_state.dart';
import 'package:ajarin_ya/viewmodels/study_spot_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudySpotScreen extends StatefulWidget {
  const StudySpotScreen({super.key});

  @override
  State<StudySpotScreen> createState() => _StudySpotScreenState();
}

class _StudySpotScreenState extends State<StudySpotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  // Koordinat terpilih secara visual (default: null)
  double? _selectedLat;
  double? _selectedLng;
  
  // Map Controller
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    final studySpotViewModel = context.read<StudySpotViewModel>();
    Future.microtask(() {
      studySpotViewModel.fetchStudySpots();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }



  void _showAddSpotDialog(BuildContext context, {double? preLat, double? preLng, StudySpot? existingSpot}) {
    if (existingSpot != null) {
      _nameController.text = existingSpot.name;
      _descController.text = existingSpot.description;
      if (existingSpot.hasValidLocation()) {
        _selectedLat = existingSpot.getSafeLatitude();
        _selectedLng = existingSpot.getSafeLongitude();
      }
    } else {
      _nameController.clear();
      _descController.clear();
      if (preLat != null && preLng != null) {
        _selectedLat = preLat;
        _selectedLng = preLng;
      }
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(existingSpot == null ? Icons.add_location_alt_rounded : Icons.edit_location_alt_rounded, color: const Color(0xFF0D47A1)),
              const SizedBox(width: 8),
              Text(existingSpot == null ? 'Daftarkan Study Spot' : 'Edit Study Spot', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                      labelText: 'Nama Tempat Belajar',
                      hintText: 'Contoh: Perpustakaan Lantai 2',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      prefixIcon: const Icon(Icons.place_outlined),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi / Fasilitas',
                      hintText: 'Contoh: Ada AC, Wi-Fi kencang, colokan aman.',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      prefixIcon: const Icon(Icons.description_outlined),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Deskripsi wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Detail Koordinat
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Koordinat Lokasi:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          'Latitude: ${_selectedLat.toStringAsFixed(6)}\nLongitude: ${_selectedLng.toStringAsFixed(6)}',
                          style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '*Koordinat terdeteksi otomatis dari klik peta Anda',
                          style: TextStyle(fontSize: 10, color: Color(0xFF0D47A1), fontStyle: FontStyle.italic),
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
                  final spot = StudySpot(
                    spotId: existingSpot?.spotId ?? '',
                    name: _nameController.text,
                    description: _descController.text,
                    location: GeoPoint(_selectedLat, _selectedLng),
                    createdBy: existingSpot?.createdBy ?? FirebaseAuth.instance.currentUser?.uid ?? '',
                  );

                  final vm = Provider.of<StudySpotViewModel>(context, listen: false);
                  if (existingSpot == null) {
                    await vm.createStudySpot(spot);
                  } else {
                    await vm.updateStudySpot(spot);
                  }
                  
                  if (context.mounted) {
                    Navigator.pop(dialogCtx);
                    vm.fetchStudySpots();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(existingSpot == null ? 'Study Spot berhasil didaftarkan ke Firestore!' : 'Study Spot berhasil diperbarui!')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Study Spot Explorer', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF0D47A1),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<StudySpotViewModel>().fetchStudySpots(),
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
              // PETA INTERAKTIF BLUEPRINT ITS KAMPUS (NEON STYLE)
              Container(
                margin: const EdgeInsets.all(12),
                height: MediaQuery.of(context).size.height * 0.3,
                constraints: const BoxConstraints(minHeight: 180, maxHeight: 300),
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF1565C0), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: const LatLng(-7.2824, 112.7949), // ITS Campus
                      initialZoom: 15.0,
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
                ),
              ),

              // LIST DETAIL & CRUD LIST DI BAWAH PETA
              Expanded(
                child: _buildSpotsListWidget(state, vm),
              ),


            ],
          );
        },
      ),
      floatingActionButton: _selectedLat != null && _selectedLng != null
          ? FloatingActionButton.extended(
              onPressed: () {
                _showAddSpotDialog(context, preLat: _selectedLat, preLng: _selectedLng);
                setState(() {
                  _selectedLat = null;
                  _selectedLng = null;
                });
              },
              backgroundColor: Colors.blueAccent.shade700,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.save),
              label: const Text('Simpan Titik Ini'),
            )
          : FloatingActionButton.extended(
              onPressed: () => _showAddSpotDialog(context),
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Daftar Spot Baru'),
            ),
    );
  }

  Widget _buildSpotsListWidget(ResultState state, StudySpotViewModel vm) {
    if (state is ResultStateLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0D47A1)));
    } else if (state is ResultStateError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700, size: 48),
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
                onPressed: () => vm.fetchStudySpots(),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemBuilder: (context, index) {
          final spot = spots[index];
          final hasGeo = spot.hasValidLocation();

          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1.5,
            margin: const EdgeInsets.only(bottom: 10),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: hasGeo ? const Color(0xFFE3F2FD) : Colors.red.shade50,
                child: Icon(
                  hasGeo ? Icons.place : Icons.place_outlined,
                  color: hasGeo ? const Color(0xFF0D47A1) : Colors.red.shade700,
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
                                icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 14),
                                label: const Text('Edit', style: TextStyle(color: Colors.blue, fontSize: 11)),
                              ),
                              TextButton.icon(
                                onPressed: () async {
                                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                                  await vm.deleteStudySpot(spot.spotId);
                                  vm.fetchStudySpots();
                                  scaffoldMessenger.showSnackBar(
                                    const SnackBar(content: Text('Study Spot berhasil dihapus dari Firestore.')),
                                  );
                                },
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 14),
                                label: const Text('Hapus', style: TextStyle(color: Colors.red, fontSize: 11)),
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
          );
        },
      );
    }
    return const Center(child: Text('Menyiapkan data...'));
  }
}


