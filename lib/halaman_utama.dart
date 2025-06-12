import 'package:absen_wajah/else/daftar_wajah.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';
import 'package:absen_wajah/absen/sign_in.dart';
import 'package:absen_wajah/absen/sign_out.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String username = "..."; // Ganti dengan username dari database atau state

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade100, Colors.orange.shade300],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Gambar profil/logo
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Image.asset(
                  'assets/absen.png',
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 24),

              // Welcome Text
              Text(
                'Selamat Datang, $username!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),

              const SizedBox(height: 30),

              // Card untuk jam dan tanggal
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: StreamBuilder<DateTime>(
                  stream: _clockStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    final now = snapshot.data!;
                    return Column(
                      children: [
                        Text(
                          DateFormat('HH:mm:ss', 'id_ID').format(now),
                          style: GoogleFonts.robotoMono(
                            fontSize: 48,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 40),

              // Tombol Absen
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMenuBox(
                    context,
                    Icons.login_rounded,
                    'Absen Masuk',
                    Colors.green,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AttendancePage()),
                      );
                    },
                  ),
                  const SizedBox(width: 20),
                  _buildMenuBox(
                    context,
                    Icons.logout_rounded,
                    'Absen Pulang',
                    Colors.redAccent,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GoHomePage()),
                      );
                    },
                  ),
                ],
              ),
              
              SizedBox(height: 20,),

                GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DaftarWajah()),
                );
              },
              child: Text(
                'Daftar Wajah',
                style: TextStyle(
                  color: const Color.fromARGB(255, 243, 68, 33),
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
             ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuBox(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Stream<DateTime> _clockStream() {
    return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
  }
}
