import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math';

Map<String, List<double>> faceDatabase = {};

class DaftarWajah extends StatefulWidget {
  @override
  _DaftarWajahState createState() => _DaftarWajahState();
}

class _DaftarWajahState extends State<DaftarWajah> {
  File? _image;
  final _kodePegawaiController = TextEditingController();
  final picker = ImagePicker();

  Future<void> _getImageAndRegisterFace() async {
    final kodePegawai = _kodePegawaiController.text.trim();

    if (kodePegawai.isEmpty) {
      _showSnackbar("Kode pegawai harus diisi.");
      return;
    }

    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    final inputImage = InputImage.fromFilePath(pickedFile.path);
    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(enableContours: true, enableClassification: true),
    );

    final faces = await faceDetector.processImage(inputImage);

    if (faces.isEmpty) {
      _showSnackbar("Wajah tidak terdeteksi.");
      return;
    }

    // Simulasi hasil embedding (harus diganti nanti dengan real embedding dari TFLite)
    final fakeEmbedding = List<double>.generate(128, (index) => Random().nextDouble());

    // Simpan ke penyimpanan lokal (sementara)
    faceDatabase[kodePegawai] = fakeEmbedding;

    setState(() => _image = File(pickedFile.path));

    _showSnackbar("✅ Wajah berhasil didaftarkan untuk kode: $kodePegawai");

    // navigasi kembali ke halaman sebelumnya (jika perlu)
    // Navigator.pop(context);
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _kodePegawaiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Daftar Wajah Pegawai')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _image != null
                    ? Image.file(_image!, height: 200)
                    : Icon(Icons.face, size: 100, color: Colors.grey),
                SizedBox(height: 20),
                TextField(
                  controller: _kodePegawaiController,
                  decoration: InputDecoration(
                    labelText: 'Kode Pegawai',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _getImageAndRegisterFace,
                  child: Text("Ambil Gambar & Daftarkan Wajah"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
