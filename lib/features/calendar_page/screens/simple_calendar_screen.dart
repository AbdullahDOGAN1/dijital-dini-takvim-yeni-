import 'package:flutter/material.dart';
import '../../../models/daily_content_model.dart';
import '../../../models/prayer_times_model.dart';
import '../../../services/daily_content_service.dart';
import '../../../widgets/daily_content_widget.dart';
import '../../daily_content/screens/daily_content_screen.dart';

class SimpleCalendarScreen extends StatefulWidget {
  const SimpleCalendarScreen({super.key});

  @override
  State<SimpleCalendarScreen> createState() => _SimpleCalendarScreenState();
}

class _SimpleCalendarScreenState extends State<SimpleCalendarScreen> {
  List<DailyContentModel> _content = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 0;
  final PageController _pageController = PageController();
  
  // Hijri tarih için
  HijriDate? _currentHijriDate;
  bool _isLoadingHijri = false;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final content = await DailyContentService.loadDailyContent();
      setState(() {
        _content = content;
        _isLoading = false;
        // Bugüne göre sayfa ayarla
        _currentPage = _getTodayIndex();
        if (_content.isNotEmpty) {
          // İlk Hijri tarih güncellemesi
          _updateHijriDate(_content[_currentPage].gunNo);
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _pageController.animateToPage(
              _currentPage,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          });
        }
      });
    } catch (e) {
      setState(() {
        _error = 'İçerik yüklenirken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  int _getTodayIndex() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    return (dayOfYear - 1).clamp(0, _content.length - 1);
  }

  /// AlAdhan API kullanarak doğru Hijri tarihini getir
  Future<void> _updateHijriDate(int dayNumber) async {
    setState(() {
      _isLoadingHijri = true;
    });

    try {
      // Gun numarasından Gregorian tarihi hesapla
      final startOfYear = DateTime(2025, 1, 1);
      final currentDate = startOfYear.add(Duration(days: dayNumber - 1));
      
      // AlAdhan API'den Hijri tarihi al
      final hijriDate = await DailyContentService.getCachedHijriDate(currentDate);
      
      setState(() {
        _currentHijriDate = hijriDate;
        _isLoadingHijri = false;
      });
    } catch (e) {
      print('Hijri tarih güncellenirken hata: $e');
      setState(() {
        _currentHijriDate = null;
        _isLoadingHijri = false;
      });
    }
  }

  String _getHijriDateForDay(int dayNumber) {
    if (_currentHijriDate != null) {
      return _currentHijriDate!.formattedDate;
    }
    
    // Fallback - eski hesaplama
    const hijriMonths = [
      'Muharrem', 'Safer', 'Rebiülevvel', 'Rebiülahir',
      'Cemaziyelevvel', 'Cemaziyelahir', 'Recep', 'Şaban',
      'Ramazan', 'Şevval', 'Zilkade', 'Zilhicce'
    ];
    
    var hijriDay = 2 + (dayNumber - 1);
    var hijriMonth = 6; // Recep (0-11 indeksi)
    var hijriYear = 1446;
    
    const monthDays = [30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29];
    
    while (hijriDay > monthDays[hijriMonth]) {
      hijriDay -= monthDays[hijriMonth];
      hijriMonth++;
      if (hijriMonth >= 12) {
        hijriMonth = 0;
        hijriYear++;
      }
    }
    
    while (hijriDay < 1) {
      hijriMonth--;
      if (hijriMonth < 0) {
        hijriMonth = 11;
        hijriYear--;
      }
      hijriDay += monthDays[hijriMonth];
    }
    
    return '$hijriDay ${hijriMonths[hijriMonth]} $hijriYear';
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Günlük Takvim'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: _goToToday,
            tooltip: 'Bugüne git',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadContent,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : _content.isEmpty
                  ? const Center(child: Text('İçerik bulunamadı'))
                  : Column(
                      children: [
                        // Sayfa göstergesi ve tarih bilgisi
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Ana tarih bilgisi
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    onPressed: _currentPage > 0 ? _previousPage : null,
                                    icon: Icon(
                                      Icons.chevron_left,
                                      color: _currentPage > 0 
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey,
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          _content.isNotEmpty ? _content[_currentPage].tarih : '',
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 4),
                                        _isLoadingHijri 
                                          ? Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  width: 12,
                                                  height: 12,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Hicri tarih yükleniyor...',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Colors.grey[600],
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Text(
                                              _getHijriDateForDay(_currentPage + 1),
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: Colors.grey[600],
                                                fontStyle: FontStyle.italic,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _currentPage < _content.length - 1 
                                        ? _nextPage 
                                        : null,
                                    icon: Icon(
                                      Icons.chevron_right,
                                      color: _currentPage < _content.length - 1
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Sayfa sayısı (daha ince)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Gün ${_currentPage + 1}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // İçerik
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() {
                                _currentPage = index;
                              });
                              // Hijri tarih güncelle
                              _updateHijriDate(_content[index].gunNo);
                            },
                            itemCount: _content.length,
                            itemBuilder: (context, index) {
                              final dayContent = _content[index];
                              return SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: DailyContentWidget(
                                  content: dayContent,
                                  onTap: () => _openDetailScreen(dayContent),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
      bottomNavigationBar: _content.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _goToToday,
                    icon: const Icon(Icons.today),
                    label: const Text('Bugün'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openDetailScreen(_content[_currentPage]),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Detay'),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _content.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToToday() {
    final todayIndex = _getTodayIndex();
    _pageController.animateToPage(
      todayIndex,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _openDetailScreen(DailyContentModel content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DailyContentScreen(dayNumber: content.gunNo),
      ),
    );
  }
}
