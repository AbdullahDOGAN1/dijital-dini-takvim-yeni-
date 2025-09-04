import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/daily_content_model.dart';
import 'services/daily_content_service.dart';

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
          'Yeni Veri Testi',
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: GoogleFonts.ebGaramond(fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadTodaysContent,
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  )
                : _todaysContent != null
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Başlık
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.teal.shade600, Colors.green.shade600],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Bugünün İçeriği',
                                    style: GoogleFonts.ebGaramond(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _todaysContent!.tarih,
                                    style: GoogleFonts.ebGaramond(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Gün No: ${_todaysContent!.gunNo}',
                                    style: GoogleFonts.ebGaramond(
                                      fontSize: 16,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Ayet/Hadis
                            _buildContentCard(
                              'Ayet/Hadis',
                              _todaysContent!.ayetHadis.metin,
                              _todaysContent!.ayetHadis.kaynak,
                              Colors.blue,
                              Icons.menu_book,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Risale-i Nur
                            _buildContentCard(
                              'Risale-i Nur',
                              _todaysContent!.risaleINur.vecize,
                              _todaysContent!.risaleINur.kaynak,
                              Colors.amber,
                              Icons.auto_stories,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Tarihte Bugün
                            _buildSimpleCard(
                              'Tarihte Bugün',
                              _todaysContent!.tariheBugun,
                              Colors.purple,
                              Icons.history,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Akşam Yemeği
                            _buildSimpleCard(
                              'Akşam Yemeği Önerisi',
                              _todaysContent!.aksamYemegi,
                              Colors.orange,
                              Icons.restaurant,
                            ),
                          ],
                        ),
                      )
                    : const Center(
                        child: Text('İçerik bulunamadı'),
                      ),
      ),
    );
  }
  
  Widget _buildContentCard(String title, String content, String source, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.ebGaramond(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.ebGaramond(
              fontSize: 16,
              height: 1.4,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              source,
              style: GoogleFonts.ebGaramond(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSimpleCard(String title, String content, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.ebGaramond(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.ebGaramond(
              fontSize: 16,
              height: 1.4,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
