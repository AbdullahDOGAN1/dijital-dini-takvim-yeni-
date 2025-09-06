import 'package:flutter/material.dart';
import '../../../models/religious_event_model.dart';
import '../../../services/religious_events_service.dart';
import 'religious_event_detail_screen.dart';

class ReligiousEventsScreen extends StatefulWidget {
  const ReligiousEventsScreen({super.key});

  @override
  State<ReligiousEventsScreen> createState() => _ReligiousEventsScreenState();
}

class _ReligiousEventsScreenState extends State<ReligiousEventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  
  List<ReligiousEvent> _currentYearEvents = [];
  List<ReligiousEvent> _upcomingEvents = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReligiousEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReligiousEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ReligiousEventsService.loadReligiousEvents();
      
      if (mounted) {
        setState(() {
          _currentYearEvents = ReligiousEventsService.getCurrentYearEvents();
          _upcomingEvents = ReligiousEventsService.getUpcomingEvents(days: 60);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dini Günler ve Kandiller',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: _isLoading || _error != null
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_month),
                        const SizedBox(width: 8),
                        Text('${DateTime.now().year} Yılı (${_currentYearEvents.length})'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time),
                        const SizedBox(width: 8),
                        Text('Yaklaşan (${_upcomingEvents.length})'),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Dini günler yükleniyor...'),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Hata: $_error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadReligiousEvents,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCurrentYearTab(),
                    _buildUpcomingTab(),
                  ],
                ),
    );
  }

  Widget _buildCurrentYearTab() {
    if (_currentYearEvents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Bu yıl için dini gün bulunamadı',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Kategorilere göre grupla
    final groupedEvents = _groupEventsByCategory(_currentYearEvents);

    return RefreshIndicator(
      onRefresh: _loadReligiousEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groupedEvents.length,
        itemBuilder: (context, index) {
          final category = groupedEvents.keys.elementAt(index);
          final events = groupedEvents[category]!;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategoryHeader(category, events.length),
              const SizedBox(height: 8),
              ...events.map((event) => _buildEventCard(event)),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUpcomingTab() {
    if (_upcomingEvents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Yaklaşan dini gün bulunmuyor',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Önümüzdeki 60 günde dini gün yok',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReligiousEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _upcomingEvents.length,
        itemBuilder: (context, index) {
          final event = _upcomingEvents[index];
          return _buildEventCard(event, showCountdown: true);
        },
      ),
    );
  }

  Map<String, List<ReligiousEvent>> _groupEventsByCategory(List<ReligiousEvent> events) {
    final grouped = <String, List<ReligiousEvent>>{};
    
    for (final event in events) {
      final category = event.category ?? 'Özel';
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(event);
    }

    // Kategorileri sırala
    final sortedKeys = grouped.keys.toList()..sort();
    final sortedGrouped = <String, List<ReligiousEvent>>{};
    for (final key in sortedKeys) {
      grouped[key]!.sort((a, b) => a.parsedDate.compareTo(b.parsedDate));
      sortedGrouped[key] = grouped[key]!;
    }

    return sortedGrouped;
  }

  Widget _buildCategoryHeader(String category, int count) {
    final colors = _getCategoryColors(category);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors['primary']!, colors['secondary']!],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(_getCategoryIcon(category), color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            _getCategoryDisplayName(category),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(ReligiousEvent event, {bool showCountdown = false}) {
    final category = event.category ?? 'Özel';
    final colors = _getCategoryColors(category);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToDetail(event),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                colors['primary']!.withOpacity(0.1),
                colors['secondary']!.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors['primary']!, colors['secondary']!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(category),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${event.day} ${event.month} ${event.year}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (showCountdown) ...[
                        const SizedBox(height: 4),
                        Text(
                          event.isToday
                              ? 'BUGÜN'
                              : '${event.daysUntil} gün sonra',
                          style: TextStyle(
                            color: event.isToday ? Colors.red : colors['primary'],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: colors['primary'],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, Color> _getCategoryColors(String category) {
    switch (category.toLowerCase()) {
      case 'kandil':
        return {'primary': Colors.deepPurple, 'secondary': Colors.purple};
      case 'bayram':
        return {'primary': Colors.green, 'secondary': Colors.lightGreen};
      case 'arefe':
        return {'primary': Colors.orange, 'secondary': Colors.deepOrange};
      default:
        return {'primary': Colors.blue, 'secondary': Colors.lightBlue};
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'kandil':
        return Icons.nights_stay;
      case 'bayram':
        return Icons.celebration;
      case 'arefe':
        return Icons.event_available;
      default:
        return Icons.event;
    }
  }

  String _getCategoryDisplayName(String category) {
    switch (category.toLowerCase()) {
      case 'kandil':
        return 'Kandil Geceleri';
      case 'bayram':
        return 'Dini Bayramlar';
      case 'arefe':
        return 'Arefe Günleri';
      default:
        return 'Özel Günler';
    }
  }

  void _navigateToDetail(ReligiousEvent event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReligiousEventDetailScreen(event: event),
      ),
    );
  }
}
