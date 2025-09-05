import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/daily_content_model.dart';
import 'services/daily_content_service.dart';
import 'features/calendar_page/screens/calendar_screen_new.dart';

/// Yeni veri dosyasını test etmek için geçici ekran
class TestNewDataScreen extends StatefulWidget {
  const TestNewDataScreen({super.key});

  @override
  State<TestNewDataScreen> createState() => _TestNewDataScreenState();
}

class _TestNewDataScreenState extends State<TestNewDataScreen> {
  DailyContentModel? _todaysContent;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTodaysContent();
  }

  Future<void> _loadTodaysContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final content = await DailyContentService.getTodaysContent();
      setState(() {
        _todaysContent = content;
        _isLoading = false;
        if (content == null) {
          _error = 'Bugün için içerik bulunamadı';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Hata: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Yeni Takvim Testi',
          style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade50, Colors.green.shade50],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: 64,
                      color: Colors.teal.shade600,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Yeni PageView Takvimi',
                      style: GoogleFonts.ebGaramond(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Yeni PageView tabanlı takvim ekranını test edin',
                      style: GoogleFonts.ebGaramond(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CalendarScreenNew(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.launch),
                      label: const Text('Yeni Takvimi Aç'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _loadTodaysContent,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Veri Testini Gör'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal.shade600,
                        side: BorderSide(color: Colors.teal.shade600),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Veri testi sonuçları
              if (_isLoading) ...[
                const SizedBox(height: 32),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Veri yükleniyor...',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ] else if (_error != null) ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.error, color: Colors.red.shade600, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Hata',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _error!,
                        style: GoogleFonts.ebGaramond(
                          fontSize: 14,
                          color: Colors.red.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ] else if (_todaysContent != null) ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade600, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Veri Başarıyla Yüklendi',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tarih: ${_todaysContent!.tarih}',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 14,
                          color: Colors.green.shade600,
                        ),
                      ),
                      Text(
                        'Gün No: ${_todaysContent!.gunNo}',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 14,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
