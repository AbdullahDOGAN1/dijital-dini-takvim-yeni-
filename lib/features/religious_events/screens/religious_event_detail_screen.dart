import 'package:flutter/material.dart';
import '../../../models/religious_event_model.dart';
import '../../../services/religious_events_service_fixed.dart';

class ReligiousEventDetailScreen extends StatefulWidget {
  final ReligiousEvent event;

  const ReligiousEventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  State<ReligiousEventDetailScreen> createState() => _ReligiousEventDetailScreenState();
}

class _ReligiousEventDetailScreenState extends State<ReligiousEventDetailScreen> {
  ReligiousEventDetails? _eventDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEventDetails();
  }

  void _loadEventDetails() {
    setState(() {
      _isLoading = true;
    });

    // Etkinlik detaylarını getir
    _eventDetails = ReligiousEventsService.getEventDetails(widget.event.name);

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryColors = ReligiousEventsService.getCategoryColors();
    final categoryIcons = ReligiousEventsService.getCategoryIcons();
    
    final color = Color(int.parse('0xFF${categoryColors[widget.event.category]?.substring(1) ?? '95A5A6'}'));
    final icon = categoryIcons[widget.event.category] ?? '📖';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.name),
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeaderSection(color, icon),
                  if (_eventDetails != null) ...[
                    _buildDetailSection(),
                  ] else ...[
                    _buildNoDetailSection(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderSection(Color color, String icon) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    icon,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.event.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.event.gregorianDate} • ${widget.event.dayOfWeek}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.mosque, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        widget.event.hijriDate,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                if (widget.event.daysUntil >= 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule, color: color, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          widget.event.isToday
                              ? 'BUGÜN'
                              : widget.event.daysUntil == 1
                                  ? 'YARIN'
                                  : '${widget.event.daysUntil} GÜN KALDI',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_eventDetails!.description.isNotEmpty) ...[
            _buildSectionCard(
              title: 'Açıklama',
              icon: Icons.info_outline,
              content: _eventDetails!.fullDescription,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
          ],
          
          if (_eventDetails!.worshipsAndPrayers.isNotEmpty) ...[
            _buildSectionCard(
              title: 'Yapılan İbadetler ve Dualar',
              icon: Icons.favorite,
              content: _eventDetails!.fullWorshipText,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
          ],
          
          if (_eventDetails!.versesAndHadiths.isNotEmpty) ...[
            _buildSectionCard(
              title: 'İlgili Ayet ve Hadisler',
              icon: Icons.menu_book,
              content: _eventDetails!.fullVersesText,
              color: Colors.purple,
            ),
            const SizedBox(height: 16),
          ],
          
          if (_eventDetails!.recommendations.isNotEmpty) ...[
            _buildSectionCard(
              title: 'Tavsiyeler',
              icon: Icons.tips_and_updates,
              content: _eventDetails!.fullRecommendationsText,
              color: Colors.orange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoDetailSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Bu dini gün için detaylı bilgi\nhenüz mevcut değil',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Genel bilgi veya dış kaynak açabilir
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Detaylı bilgi yakında eklenecek'),
                  ),
                );
              },
              icon: const Icon(Icons.search),
              label: const Text('Daha Fazla Bilgi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required String content,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
