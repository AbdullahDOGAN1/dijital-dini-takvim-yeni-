import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/religious_day_model.dart';
import '../../../services/religious_days_service.dart';
import 'religious_day_detail_screen.dart';

class ReligiousDaysScreen extends StatefulWidget {
  const ReligiousDaysScreen({super.key});

  @override
  State<ReligiousDaysScreen> createState() => _ReligiousDaysScreenState();
}

class _ReligiousDaysScreenState extends State<ReligiousDaysScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dini Günler ve Kandiller',
          style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Tümü'),
            Tab(text: 'Kandiller'),
            Tab(text: 'Bayramlar'),
            Tab(text: 'Yaklaşan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllDaysList(),
          _buildCategoryList('kandil'),
          _buildCategoryList('bayram'),
          _buildUpcomingDaysList(),
        ],
      ),
    );
  }

  Widget _buildAllDaysList() {
    return FutureBuilder<List<ReligiousDay>>(
      future: ReligiousDaysService.getReligiousDays(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Hata: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          );
        }

        final allDays = snapshot.data ?? [];
        allDays.sort((a, b) => a.date.compareTo(b.date));
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: allDays.length,
          itemBuilder: (context, index) {
            return _buildDayCard(allDays[index]);
          },
        );
      },
    );
  }

  Widget _buildCategoryList(String category) {
    return FutureBuilder<List<ReligiousDay>>(
      future: ReligiousDaysService.getDaysByCategory(category),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Hata: ${snapshot.error}'),
          );
        }

        final days = snapshot.data ?? [];
        days.sort((a, b) => a.date.compareTo(b.date));
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: days.length,
          itemBuilder: (context, index) {
            return _buildDayCard(days[index]);
          },
        );
      },
    );
  }

  Widget _buildUpcomingDaysList() {
    return FutureBuilder<List<ReligiousDay>>(
      future: ReligiousDaysService.getUpcomingDays(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Hata: ${snapshot.error}'),
          );
        }

        final upcomingDays = snapshot.data ?? [];
        
        if (upcomingDays.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Bu yıl için yaklaşan dini gün bulunmuyor',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: upcomingDays.length,
          itemBuilder: (context, index) {
            return _buildDayCard(upcomingDays[index], showCountdown: true);
          },
        );
      },
    );
  }

  Widget _buildDayCard(ReligiousDay day, {bool showCountdown = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReligiousDayDetailScreen(religiousDay: day),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık ve kategori
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: day.categoryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: day.categoryColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      day.categoryDisplayName,
                      style: TextStyle(
                        color: day.categoryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (day.isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.5)),
                      ),
                      child: const Text(
                        'BUGÜN',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // İsim
              Text(
                day.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: day.categoryColor,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Tarihler
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${day.date.day} ${_getMonthName(day.date.month)} ${day.date.year}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.mosque, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    day.hijriDate,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Açıklama
              Text(
                day.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              if (showCountdown && day.isUpcoming) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: day.categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 16, color: day.categoryColor),
                      const SizedBox(width: 8),
                      Text(
                        '${day.daysUntil} gün kaldı',
                        style: TextStyle(
                          color: day.categoryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 8),
              
              // Detay butonu
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReligiousDayDetailScreen(religiousDay: day),
                        ),
                      );
                    },
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Detayları Gör'),
                    style: TextButton.styleFrom(
                      foregroundColor: day.categoryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return months[month - 1];
  }
}
