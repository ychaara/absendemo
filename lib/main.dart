import 'package:absen_wajah/halaman_utama.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Pastikan Flutter binding sudah berjalan
  await initializeDateFormatting('id_ID', null); // Inisialisasi bahasa Indonesia
  runApp(const AbsensiApp());
}

class AbsensiApp extends StatelessWidget {
  const AbsensiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Absensi Wajah (Demo)',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}