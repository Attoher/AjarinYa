import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ajarin_ya/models/study_spot.dart';
import 'package:ajarin_ya/models/result_state.dart';
import 'package:ajarin_ya/viewmodels/study_spot_view_model.dart';

class StudySpotScreen extends StatefulWidget {
  const StudySpotScreen({super.key});

  @override
  State<StudySpotScreen> createState() => _StudySpotScreenState();
}

class _StudySpotScreenState extends State<StudySpotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  // Koordinat terpilih secara visual (default: Kampus ITS)
  double _selectedLat = -7.2824;
  double _selectedLng = 112.7949;
  
  // Detil spot terpilih yang sedang aktif di-klik pada peta
  StudySpot? _hoveredSpot;

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

  // Translasi Koordinat Lat/Lng Kampus ITS ke Piksel Kanvas Peta (Neon Blueprint)
  // Rentang Lat: -7.2800 (Atas/Utara) s.d -7.2860 (Bawah/Selatan)
  // Rentang Lng: 112.7930 (Kiri/Barat) s.d 112.7970 (Kanan/Timur)
  double _getX(double lng, double width) {
    double factor = (lng - 112.7930) / (112.7970 - 112.7930);
    return factor.clamp(0.0, 1.0) * width;
  }

  double _getY(double lat, double height) {
    double factor = (lat - (-7.2800)) / ((-7.2860) - (-7.2800));
    return factor.clamp(0.0, 1.0) * height;
  }

  // Sebaliknya, translasi Piksel Kanvas ke Koordinat Lat/Lng
  double _getLat(double y, double height) {
    double factor = y / height;
    return -7.2800 + factor * (-7.2860 - (-7.2800));
  }

  double _getLng(double x, double width) {
    double factor = x / width;
    return 112.7930 + factor * (112.7970 - 112.7930);
  }

  void _showAddSpotDialog(BuildContext context, {double? preLat, double? preLng}) {
    if (preLat != null && preLng != null) {
      _selectedLat = preLat;
      _selectedLng = preLng;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(Icons.add_location_alt_rounded, color: Colors.deepPurple.shade700),
              const SizedBox(width: 8),
              const Text('Daftarkan Study Spot', style: TextStyle(fontWeight: FontWeight.bold)),
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
                          style: TextStyle(fontSize: 10, color: Colors.deepPurple, fontStyle: FontStyle.italic),
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
                    name: _nameController.text,
                    description: _descController.text,
                    location: GeoPoint(_selectedLat, _selectedLng),
                    createdBy: 'User_Mahasiswa_1',
                  );

                  final vm = context.read<StudySpotViewModel>();
                  await vm.createStudySpot(spot);

                  _nameController.clear();
                  _descController.clear();
                  if (context.mounted) {
                    Navigator.pop(dialogCtx);
                    vm.fetchStudySpots();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Study Spot baru berhasil didaftarkan ke Firestore!')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade700,
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

  // Trigger Simulator untuk Integritas (Sesuai anti-cheat dan null safety Jingga)
  void _triggerIntegritySimulator(BuildContext context, String mode) async {
    final vm = context.read<StudySpotViewModel>();
    StudySpot corruptedSpot;

    if (mode == 'NULL') {
      corruptedSpot = StudySpot(
        name: '🔥 Spot Lokasi Null (Integrity Simulation)',
        description: 'Membuktikan aplikasi tidak crash walau GeoPoint disengajakan null.',
        createdBy: 'SIMULATOR_USER',
      )..location = null;
    } else {
      corruptedSpot = StudySpot(
        name: '💥 Spot Lokasi Rusak (Integrity Simulation)',
        description: 'Membuktikan asersi repository menangkap batas koordinat di luar Kampus ITS (Lat -1.0, Lng 118.0).',
        location: const GeoPoint(-1.0, 118.0),
        createdBy: 'SIMULATOR_USER',
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.amber.shade900,
        content: Text('Simulasi dipicu: Mengirim data $mode ke Firestore. Perhatikan Debug Console!'),
      ),
    );

    await vm.createStudySpot(corruptedSpot);
    vm.fetchStudySpots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Study Spot Explorer', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.deepPurple.shade700,
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
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A), // Premium Dark Slate Navy
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.deepPurple.shade300, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double width = constraints.maxWidth;
                      final double height = constraints.maxHeight;

                      return GestureDetector(
                        onTapDown: (TapDownDetails details) {
                          // Deteksi koordinat letak ketukan pada peta
                          final double localX = details.localPosition.dx;
                          final double localY = details.localPosition.dy;
                          
                          // Konversi ke koordinat Lat/Lng ITS Kampus
                          final double lat = _getLat(localY, height);
                          final double lng = _getLng(localX, width);

                          setState(() {
                            _selectedLat = lat;
                            _selectedLng = lng;
                            _hoveredSpot = null; // reset hovered spot
                          });

                          // Tanya user untuk daftarkan lokasi baru ini
                          _showAddSpotDialog(context, preLat: lat, preLng: lng);
                        },
                        child: Stack(
                          children: [
                            // 1. Gambar Gambar Vektor Jalur Kampus & Sungai (Neon Blueprint)
                            CustomPaint(
                              size: Size(width, height),
                              painter: CampusMapPainter(),
                            ),

                            // 2. Plotting Pins Spot Belajar yang Terdaftar di Firestore secara Dinamis
                            ...spotsList.map((spot) {
                              if (!spot.hasValidLocation()) return const SizedBox.shrink();
                              
                              final double x = _getX(spot.getSafeLongitude(), width);
                              final double y = _getY(spot.getSafeLatitude(), height);

                              final bool isHovered = _hoveredSpot?.spotId == spot.spotId;

                              return Positioned(
                                left: x - 14,
                                top: y - 28,
                                child: GestureDetector(
                                  onTapDown: (details) {
                                    // Cegah event bubbling ketukan ke peta utama
                                  },
                                  onTap: () {
                                    setState(() {
                                      _hoveredSpot = spot;
                                      _selectedLat = spot.getSafeLatitude();
                                      _selectedLng = spot.getSafeLongitude();
                                    });
                                  },
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Icon(
                                      Icons.location_on_sharp,
                                      color: isHovered ? Colors.orangeAccent : Colors.cyanAccent,
                                      size: isHovered ? 34 : 26,
                                    ),
                                  ),
                                ),
                              );
                            }),

                            // 3. Pin Drop Simulator Sementara (Hijau Neon) saat diketuk
                            Positioned(
                              left: _getX(_selectedLng, width) - 14,
                              top: _getY(_selectedLat, height) - 28,
                              child: const IgnorePointer(
                                child: Icon(
                                  Icons.add_location_alt_sharp,
                                  color: Colors.greenAccent,
                                  size: 28,
                                ),
                              ),
                            ),

                            // 4. Panel Bantuan / Status di Kanan Atas Peta
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Klik Peta untuk Drop Pin Baru',
                                  style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),

                            // 5. HUD POPUP CARD: Info Spot yang Sedang Dipilih pada Peta
                            if (_hoveredSpot != null)
                              Positioned(
                                bottom: 12,
                                left: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xEE1E293B), // Navy semi transparan
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                                  ),
                                  child: Row(
                                    children: [
                                      const CircleAvatar(
                                        backgroundColor: Colors.cyan,
                                        radius: 16,
                                        child: Icon(Icons.place, color: Colors.white, size: 16),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _hoveredSpot!.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            Text(
                                              _hoveredSpot!.description,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.white60, size: 18),
                                        onPressed: () {
                                          setState(() {
                                            _hoveredSpot = null;
                                          });
                                        },
                                      )
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // LIST DETAIL & CRUD LIST DI BAWAH PETA
              Expanded(
                child: _buildSpotsListWidget(state, vm),
              ),

              // BOX SIMULASI SANDBOX INTEGRITAS (Dapat Dihubungkan / Di-expand)
              ExpansionTile(
                title: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.amber, size: 16),
                    SizedBox(width: 8),
                    Text('Sandbox Diagnostik Integritas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber)),
                  ],
                ),
                backgroundColor: Colors.amber.shade50.withOpacity(0.3),
                collapsedBackgroundColor: Colors.amber.shade50.withOpacity(0.1),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _triggerIntegritySimulator(context, 'NULL'),
                            icon: const Icon(Icons.warning_amber_rounded, size: 14),
                            label: const Text('Uji Null Safety', style: TextStyle(fontSize: 10)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _triggerIntegritySimulator(context, 'CORRUPT'),
                            icon: const Icon(Icons.explore_outlined, size: 14),
                            label: const Text('Uji Batas Koordinat', style: TextStyle(fontSize: 10)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade800,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSpotDialog(context),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Daftar Spot Baru'),
      ),
    );
  }

  Widget _buildSpotsListWidget(ResultState state, StudySpotViewModel vm) {
    if (state is ResultStateLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.deepPurple));
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
                backgroundColor: hasGeo ? Colors.deepPurple.shade50 : Colors.red.shade50,
                child: Icon(
                  hasGeo ? Icons.place : Icons.place_outlined,
                  color: hasGeo ? Colors.deepPurple.shade700 : Colors.red.shade700,
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

// Custom Painter untuk Menggambar Peta Vektor Kampus ITS (Stunning Navy Blueprint)
class CampusMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // 1. Cat Background (Navy Gelap)
    final bgPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);

    // 2. Gambar Garis-garis Grid Blueprint (Sci-fi feel)
    final gridPaint = Paint()
      ..color = Colors.deepPurple.shade900.withOpacity(0.3)
      ..strokeWidth = 1.0;
    
    double step = 30.0;
    for (double i = 0; i < width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, height), gridPaint);
    }
    for (double j = 0; j < height; j += step) {
      canvas.drawLine(Offset(0, j), Offset(width, j), gridPaint);
    }

    // 3. Gambar Area Danau Kampus ITS (Neon Blue Shape)
    final lakePaint = Paint()
      ..color = Colors.blue.shade900.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    
    final Path lakePath = Path()
      ..moveTo(width * 0.4, height * 0.45)
      ..quadraticBezierTo(width * 0.5, height * 0.35, width * 0.65, height * 0.5)
      ..quadraticBezierTo(width * 0.55, height * 0.65, width * 0.4, height * 0.45)
      ..close();
    canvas.drawPath(lakePath, lakePaint);

    // Border Danau
    final lakeBorder = Paint()
      ..color = Colors.cyan.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(lakePath, lakeBorder);

    // 4. Gambar Jalan Utama Kampus (Cyan Lines)
    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Lingkaran Bundaran ITS
    canvas.drawCircle(Offset(width * 0.5, height * 0.5), 35.0, roadPaint);
    
    // Jalan Menyilang Utama
    canvas.drawLine(Offset(width * 0.1, height * 0.2), Offset(width * 0.9, height * 0.8), roadPaint);
    canvas.drawLine(Offset(width * 0.1, height * 0.8), Offset(width * 0.9, height * 0.2), roadPaint);

    // 5. Gambar Landmark / Gedung-Gedung Fakultas Outline (Neon Outline Boxes)
    final buildingPaint = Paint()
      ..color = Colors.deepPurple.shade400.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    
    final buildingBorder = Paint()
      ..color = Colors.deepPurple.shade300
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Landmark 1: Rektorat ITS
    final rect1 = Rect.fromLTWH(width * 0.45, height * 0.15, 36, 20);
    canvas.drawRect(rect1, buildingPaint);
    canvas.drawRect(rect1, buildingBorder);
    _drawText(canvas, Offset(width * 0.45, height * 0.10), 'Rektorat');

    // Landmark 2: Perpustakaan ITS
    final rect2 = Rect.fromLTWH(width * 0.18, height * 0.38, 40, 24);
    canvas.drawRect(rect2, buildingPaint);
    canvas.drawRect(rect2, buildingBorder);
    _drawText(canvas, Offset(width * 0.18, height * 0.32), 'Perpustakaan');

    // Landmark 3: Gedung PPB (Pusat Bahasa)
    final rect3 = Rect.fromLTWH(width * 0.72, height * 0.38, 38, 24);
    canvas.drawRect(rect3, buildingPaint);
    canvas.drawRect(rect3, buildingBorder);
    _drawText(canvas, Offset(width * 0.72, height * 0.32), 'Gedung PPB');

    // Landmark 4: Kantin Pusat
    final rect4 = Rect.fromLTWH(width * 0.42, height * 0.75, 45, 20);
    canvas.drawRect(rect4, buildingPaint);
    canvas.drawRect(rect4, buildingBorder);
    _drawText(canvas, Offset(width * 0.42, height * 0.70), 'Kantin Pusat');
  }

  void _drawText(Canvas canvas, Offset offset, String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 8, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
