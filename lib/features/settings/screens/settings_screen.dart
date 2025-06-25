import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ayarlar',
          style: GoogleFonts.ebGaramond(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.brown.shade50, Colors.amber.shade50],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.settings,
                size: 80,
                color: Colors.brown.shade400,
              ),
              const SizedBox(height: 20),
              Text(
                'Ayarlar Sayfası',
                style: GoogleFonts.ebGaramond(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Bu sayfa geliştirilme aşamasındadır.',
                style: GoogleFonts.ebGaramond(
                  fontSize: 16,
                  color: Colors.brown.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
