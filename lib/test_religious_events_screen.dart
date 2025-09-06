import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/religious_events_service_fixed.dart';
import 'models/religious_event_model.dart';

/// Dini günler veri entegrasyonunu test etmek için ekran
class TestReligiousEventsScreen extends StatefulWidget {
  const TestReligiousEventsScreen({super.key});

  @override
  State<TestReligiousEventsScreen> createState() => _TestReligiousEventsScreenState();
}

class _TestReligiousEventsScreenState extends State<TestReligiousEventsScreen> {
  bool _isLoading = true;
  String? _error;
  List<ReligiousEvent> _events = [];
  List<ReligiousEventDetails> _eventDetails = [];
  List<String> _eventsWithoutDetails = [];

  @override
  void initState() {
    super.initState();
    _loadReligiousEvents();
  }

  Future<void> _loadReligiousEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ReligiousEventsService.loadReligiousEvents();
      
      // Test verileri
      final upcomingEvents = ReligiousEventsService.getUpcomingEvents(days: 365);
      final todaysEvents = ReligiousEventsService.getTodaysEvents();
      
      // Detay testleri
      List<ReligiousEventDetails> details = [];
      List<String> eventsWithoutDetails = [];
      
      final testEvents = upcomingEvents.take(10).toList();
      for (final event in testEvents) {
        final detail = ReligiousEventsService.getEventDetails(event.name);
        if (detail != null) {
          details.add(detail);
        } else {
          eventsWithoutDetails.add(event.name);
        }
      }
      
      setState(() {
        _events = upcomingEvents;
        _eventDetails = details;
        _eventsWithoutDetails = eventsWithoutDetails;
        _isLoading = false;
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
          'Dini Günler Veri Testi',
          style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50, Colors.teal.shade50],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Dini günler verisi yükleniyor...'),
                  ],
                ),
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'Hata',
                          style: GoogleFonts.ebGaramond(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.ebGaramond(fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadReligiousEvents,
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Başarı mesajı
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green.shade700, size: 48),
                              const SizedBox(height: 8),
                              Text(
                                'Yeni Kategorize Edilmiş Dini Günler Verisi Başarıyla Entegre Edildi!',
                                style: GoogleFonts.ebGaramond(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_events.length} dini gün yüklendi, ${_eventDetails.length} detay bulundu',
                                style: GoogleFonts.ebGaramond(
                                  fontSize: 14,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Eksik detaylar uyarısı
                        if (_eventsWithoutDetails.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.shade300),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.warning, color: Colors.orange.shade700, size: 32),
                                const SizedBox(height: 8),
                                Text(
                                  'Detayı Eksik Dini Günler',
                                  style: GoogleFonts.ebGaramond(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...(_eventsWithoutDetails.map((eventName) => 
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Text(
                                      '• $eventName',
                                      style: GoogleFonts.ebGaramond(
                                        fontSize: 14,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  ))),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                        ],
                        
                        // İstatistikler
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Veri İstatistikleri',
                                  style: GoogleFonts.ebGaramond(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        'Toplam Dini Gün',
                                        '${_events.length}',
                                        Icons.calendar_month,
                                        Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildStatCard(
                                        'Detaylı Bilgi',
                                        '${_eventDetails.length}',
                                        Icons.info,
                                        Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Yaklaşan etkinlikler
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Yaklaşan Dini Günler (İlk 10)',
                                  style: GoogleFonts.ebGaramond(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_events.isEmpty)
                                  const Text('Henüz yaklaşan dini gün bulunmuyor')
                                else
                                  ...(_events.take(10).map((event) => 
                                    _buildEventCard(event))),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Detay testleri
                        if (_eventDetails.isNotEmpty) ...[
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Detay Verisi Örnekleri',
                                    style: GoogleFonts.ebGaramond(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ...(_eventDetails.map((detail) => 
                                    _buildDetailCard(detail))),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.ebGaramond(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.ebGaramond(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(ReligiousEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event,
            color: Colors.green.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: GoogleFonts.ebGaramond(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.gregorianDate,
                  style: GoogleFonts.ebGaramond(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${event.daysUntil} gün',
              style: GoogleFonts.ebGaramond(
                fontSize: 10,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(ReligiousEventDetails detail) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.name,
            style: GoogleFonts.ebGaramond(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade800,
            ),
          ),
          const SizedBox(height: 8),
          if (detail.description.isNotEmpty) ...[
            Text(
              'Açıklama: ${detail.description.length} paragraf',
              style: GoogleFonts.ebGaramond(
                fontSize: 12,
                color: Colors.teal.shade700,
              ),
            ),
          ],
          if (detail.worshipsAndPrayers.isNotEmpty) ...[
            Text(
              'İbadetler ve Dualar: ${detail.worshipsAndPrayers.length} madde',
              style: GoogleFonts.ebGaramond(
                fontSize: 12,
                color: Colors.teal.shade700,
              ),
            ),
          ],
          if (detail.versesAndHadiths.isNotEmpty) ...[
            Text(
              'Ayet ve Hadisler: ${detail.versesAndHadiths.length} madde',
              style: GoogleFonts.ebGaramond(
                fontSize: 12,
                color: Colors.teal.shade700,
              ),
            ),
          ],
          if (detail.recommendations.isNotEmpty) ...[
            Text(
              'Tavsiyeler: ${detail.recommendations.length} madde',
              style: GoogleFonts.ebGaramond(
                fontSize: 12,
                color: Colors.teal.shade700,
              ),
            ),
          ],
          if (detail.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              detail.shortDescription,
              style: GoogleFonts.ebGaramond(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
