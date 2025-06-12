import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:absen_wajah/halaman_utama.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  CameraController? _cameraController;
  late List<CameraDescription> _cameras;
  bool _isFaceDetected = false;
  bool _isProcessing = false;
  String? _attendanceResult;
  bool _showAnimation = false;

  String _getCurrentDateTime() {
    final now = DateTime.now();
    final tanggal =
        "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
    final waktu =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    return "$tanggal | $waktu";
  }

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(enableContours: true, enableLandmarks: true),
  );

  static const String serverUrl =
      'http://192.168.1.14/absendigital/absen/public/verify';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    debugPrint("Disposing face detector and camera...");
    _faceDetector.close();
    if (_cameraController != null) {
      _cameraController!.stopImageStream();
      _cameraController!.dispose();
    }
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      debugPrint('Memulai inisialisasi kamera...');
      _cameras = await availableCameras();
      final frontCamera = _cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front);

      _cameraController = CameraController(
          frontCamera, ResolutionPreset.high,
          enableAudio: false);

      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {});
      debugPrint('Kamera berhasil diinisialisasi.');
      _startFaceDetection();
    } catch (e) {
      debugPrint("Error initializing camera: $e");
      _showError("Error initializing camera: $e");
    }
  }

  Future<void> _startFaceDetection() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showError("Kamera tidak tersedia, Silahkan cek izin kamera");
      return;
    }

    debugPrint("Starting face detection stream...");

    _cameraController!.startImageStream((CameraImage image) async {
      if (_isProcessing) return;
      _isProcessing = true;

      debugPrint("Processing new camera frame...");

      try {
        final InputImage inputImage = _convertToInputImage(image);
        final List<Face> faces = await _faceDetector.processImage(inputImage);

        debugPrint("Faces detected: ${faces.length}");

        setState(() {
          _isFaceDetected = faces.isNotEmpty;
        });

        if (_isFaceDetected) {
          await Future.delayed(const Duration(seconds: 3));
          await _verifyAndRecordAttendance(image); // Hanya ini (tanpa popup awal)
        }
      } catch (e) {
        _showError("Error in face detection: $e");
        debugPrint("Face detection error: $e");
      } finally {
        _isProcessing = false;
      }
    });
  }

  void _showError(String message) {
    debugPrint("ERROR: $message");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  InputImage _convertToInputImage(CameraImage image) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    debugPrint("Converting CameraImage to InputImage...");

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation:
            _rotationFromCamera(_cameraController!.description.lensDirection),
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  InputImageRotation _rotationFromCamera(CameraLensDirection direction) {
    switch (direction) {
      case CameraLensDirection.front:
        return InputImageRotation.rotation270deg;
      case CameraLensDirection.back:
        return InputImageRotation.rotation90deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  Future<void> _verifyAndRecordAttendance(CameraImage image) async {
    debugPrint("Sending face verification to server...");
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();
    String base64Image = base64Encode(bytes);

    try {
      var response = await http.post(
        Uri.parse(serverUrl),
        body: {
          'image': base64Image,
        },
      );
      debugPrint("Face verification response: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          String nama = responseData['nama_pegawai'] ?? 'ica';
          String kode = responseData['kode_pegawai'] ?? '638071272640841';
          debugPrint('Verifikasi sukses: $nama - $kode');
          await _recordAttendance(nama, kode);
          await _closeCameraAndShowPopup(nama);
        } else {
          setState(() {
            _attendanceResult = "Wajah Tidak Dikenali";
          });
          await _closeCameraAndShowFailurePopup();
        }
      } else {
        _showError("Server responded with error: ${response.body}");
      }
    } catch (e) {
      _showError("Error sending data: $e");
      debugPrint("Error during face verification: $e");
    }
  }

  Future<void> _recordAttendance(String nama, String kodePegawai) async {
    if (nama.isEmpty || kodePegawai.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Nama dan kode pegawai tidak boleh kosong")),
      );
      return;
    }

    DateTime now = DateTime.now();
    String tanggal =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    String jam_masuk =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    DateTime batasWaktu = DateTime(now.year, now.month, now.day, 8, 0, 0);
    String status = now.isAfter(batasWaktu) ? "2" : "1";
    String tipe_absen = "masuk";
    String url =
        'http://192.168.1.14/absendigital/absen/public/record_attendance';

    debugPrint('Merekam absensi: $nama - $kodePegawai');

    try {
      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode({
          'nama_pegawai': nama,
          'kode_pegawai': kodePegawai,
          'tgl_absen': tanggal,
          'jam_masuk': jam_masuk,
          'status_pegawai': status,
          'tipe_absen': tipe_absen,
        }),
      );
      debugPrint(
          'Record attendance response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        setState(() {
          _attendanceResult = "Attendance successful: $nama";
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server responded with error: ${response.body}")),
        );
      }
    } catch (e) {
      debugPrint("Error recording attendance: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error sending data: $e")),
      );
    }
  }

  Future<void> _closeCameraAndShowPopup(String nama) async {
    debugPrint("Stopping and disposing camera...");
    setState(() {
      _showAnimation = false;
    });
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() {
      _showAnimation = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    if (_cameraController != null) {
      await _cameraController!.stopImageStream();
      await _cameraController!.dispose();
      Navigator.of(context).pop();

      setState(() {
        _cameraController = null;
      });
    }

    debugPrint("Showing attendance success popup for: $nama");

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: _showAnimation ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                child: const Icon(Icons.check_circle,
                    color: Colors.green, size: 80),
              ),
              const SizedBox(height: 10),
              Text(
                "Absen Berhasil",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const CircleAvatar(
                radius: 35,
                backgroundImage:
                    AssetImage('assets/profile_placeholder.png'),
              ),
              const SizedBox(height: 8),
              Text(
                _getCurrentDateTime(),
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              const Text("Selamat datang, semangat bekerja! 💪"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                );
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _closeCameraAndShowFailurePopup() async {
    debugPrint("Stopping and disposing camera for failure case...");
    if (_cameraController != null) {
      await _cameraController!.stopImageStream();
      await _cameraController!.dispose();
      setState(() {
        _cameraController = null;
      });
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.error, color: Colors.red, size: 80),
              SizedBox(height: 10),
              Text(
                "Absen Gagal",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "Wajah tidak dikenali atau tidak cocok.\nSilakan coba lagi.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                );
              },
              child: Text("Kembali"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Attendance Check-In',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange, Colors.deepOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: _cameraController != null &&
                      _cameraController!.value.isInitialized
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: CameraPreview(_cameraController!),
                      ),
                    )
                  : Center(
                      child: Text(
                        "Camera is not opened",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: _isFaceDetected
                    ? Colors.green.shade100
                    : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isFaceDetected ? Colors.green : Colors.orange,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isFaceDetected ? Icons.check_circle : Icons.face,
                    color: _isFaceDetected ? Colors.green : Colors.orange,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isFaceDetected
                        ? "Face detected!"
                        : "Point your face to the camera for detection",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _isFaceDetected
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_attendanceResult != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info, color: Colors.blue, size: 28),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        _attendanceResult!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
