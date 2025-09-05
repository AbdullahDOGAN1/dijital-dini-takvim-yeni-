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
  late PageController _pageController;
  
  // Hijri tarih için
  HijriDate? _currentHijriDate;
  bool _isLoadingHijri = false;
  
  // Navigation kontrolü için
  bool _isNavigating = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    final todayIndex = _getTodayIndex();
    _currentPage = todayIndex;
    _pageController = PageController(initialPage: todayIndex);
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final content = await DailyContentService.loadDailyContent();
      if (mounted) {
        setState(() {
          _content = content;
          _isLoading = false;
          _isInitialized = true;
        });
        
        // İlk Hijri tarih güncellemesi
        if (_content.isNotEmpty) {
          _updateHijriDate(_content[_currentPage].gunNo);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'İçerik yüklenirken hata oluştu: $e';
          _isLoading = false;
        });
      }
    }
  }

  int _getTodayIndex() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    return (dayOfYear - 1).clamp(0, 364); // 365 gün max
  }

  /// AlAdhan API kullanarak doğru Hijri tarihini getir
  Future<void> _updateHijriDate(int dayNumber) async {
    if (_isLoadingHijri) return; // Zaten yükleniyorsa bekle
    
    setState(() {
      _isLoadingHijri = true;
    });

    try {
      // Gun numarasından Gregorian tarihi hesapla
      final startOfYear = DateTime(2025, 1, 1);
      final currentDate = startOfYear.add(Duration(days: dayNumber - 1));
      
      // AlAdhan API'den Hijri tarihi al
      final hijriDate = await DailyContentService.getCachedHijriDate(currentDate);
      
      if (mounted) {
        setState(() {
          _currentHijriDate = hijriDate;
          _isLoadingHijri = false;
        });
      }
    } catch (e) {
      print('Hijri tarih güncellenirken hata: $e');
      if (mounted) {
        setState(() {
          _currentHijriDate = null;
          _isLoadingHijri = false;
        });
      }
    }
  }

  String _getHijriDateForDay(int dayNumber) {
    if (_currentHijriDate != null) {
      // API'den gelen tarihi Türkçe formatla
      final originalDate = _currentHijriDate!.formattedDate;
      
      // Tarihten gün ve yıl numarasını çıkar
      final regex = RegExp(r'^(\d+)\s+(.+?)\s+(\d+)$');
      final match = regex.firstMatch(originalDate);
      
      if (match != null) {
        final day = match.group(1)!;
        final monthEng = match.group(2)!;
        final year = match.group(3)!;
        
        // İngilizce ay isimlerini Türkçe'ye çevir
        final monthTr = _convertEnglishMonthToTurkish(monthEng);
        return '$day $monthTr $year';
      }
      
      return originalDate;
    }
    
    // Fallback - Türkçe ay isimleri ile doğru hesaplama
    const hijriMonths = [
      'Muharrem', 'Safer', 'Rebiülevvel', 'Rebiülahir',
      'Cemayizelevvel', 'Cemayizelahir', 'Recep', 'Şaban',
      'Ramazan', 'Şevval', 'Zilkade', 'Zilhicce'
    ];
    
    // 2025 için doğru başlangıç tarihi (1 Ocak 2025 = 21 Cemayizelahir 1446)
    var hijriDay = 21 + (dayNumber - 1);
    var hijriMonth = 5; // Cemayizelahir (0-11 indeksi)
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

  String _convertEnglishMonthToTurkish(String englishMonth) {
    // Tüm Hicri ayları için kapsamlı mapping - 12 ay
    final Map<String, String> monthMap = {
      // Muharrem - 1. ay
      'Muharram': 'Muharrem',
      'Muḥarram': 'Muharrem',
      'Moharram': 'Muharrem',
      
      // Safer - 2. ay
      'Safar': 'Safer', 
      'Ṣafar': 'Safer',
      'Saffar': 'Safer',
      
      // Rebiülevvel - 3. ay
      "Rabi' al-awwal": 'Rebiülevvel',
      'Rabi al-awwal': 'Rebiülevvel',
      'Rabīʿ al-awwal': 'Rebiülevvel',
      'Rabi-ul-awwal': 'Rebiülevvel',
      'Rabiulewwel': 'Rebiülevvel',
      'Rabi I': 'Rebiülevvel',
      'Rabi 1': 'Rebiülevvel',
      
      // Rebiülahir - 4. ay
      "Rabi' al-thani": 'Rebiülahir',
      'Rabi al-thani': 'Rebiülahir', 
      'Rabīʿ al-thānī': 'Rebiülahir',
      'Rabi-ul-thani': 'Rebiülahir',
      'Rabiulahir': 'Rebiülahir',
      "Rabi' al-akhir": 'Rebiülahir',
      'Rabi al-akhir': 'Rebiülahir',
      'Rabi II': 'Rebiülahir',
      'Rabi 2': 'Rebiülahir',
      
      // Cemayizelevvel - 5. ay
      'Jumada al-awwal': 'Cemayizelevvel',
      'Jumādā al-awwal': 'Cemayizelevvel',
      'Jumada al-ula': 'Cemayizelevvel',
      'Jumada I': 'Cemayizelevvel',
      'Jumada 1': 'Cemayizelevvel',
      'Jumada-ul-awwal': 'Cemayizelevvel',
      
      // Cemayizelahir - 6. ay
      'Jumada al-thani': 'Cemayizelahir',
      'Jumādā al-thānī': 'Cemayizelahir',
      'Jumada al-akhir': 'Cemayizelahir',
      'Jumada II': 'Cemayizelahir',
      'Jumada 2': 'Cemayizelahir',
      'Jumada-ul-thani': 'Cemayizelahir',
      
      // Recep - 7. ay
      'Rajab': 'Recep',
      'Rajjab': 'Recep',
      'Rajab al-murajjab': 'Recep',
      
      // Şaban - 8. ay
      "Sha'ban": 'Şaban',
      'Shaban': 'Şaban',
      "Sha'aban": 'Şaban',
      'Shaʿbān': 'Şaban',
      'Sha-ban': 'Şaban',
      
      // Ramazan - 9. ay
      'Ramadan': 'Ramazan',
      'Ramaḍān': 'Ramazan',
      'Ramzan': 'Ramazan',
      'Ramadhan': 'Ramazan',
      
      // Şevval - 10. ay
      'Shawwal': 'Şevval',
      'Shawwāl': 'Şevval',
      'Shawal': 'Şevval',
      'Shauwal': 'Şevval',
      
      // Zilkade - 11. ay
      "Dhu al-Qi'dah": 'Zilkade',
      'Dhu al-Qadah': 'Zilkade',
      'Dhū al-Qiʿdah': 'Zilkade',
      "Dhul-Qa'dah": 'Zilkade',
      'Zilqade': 'Zilkade',
      'Zul-Qadah': 'Zilkade',
      'Zil-Qadah': 'Zilkade',
      
      // Zilhicce - 12. ay
      'Dhu al-Hijjah': 'Zilhicce',
      'Dhu al-Hijja': 'Zilhicce',
      'Dhū al-Ḥijjah': 'Zilhicce',
      'Dhul-Hijjah': 'Zilhicce',
      'Zilhijje': 'Zilhicce',
      'Zul-Hijjah': 'Zilhicce',
      'Zil-Hijjah': 'Zilhicce',
    };
    
    // Önce exact match kontrol et
    if (monthMap.containsKey(englishMonth)) {
      print('🗓️ Month converted: "$englishMonth" → "${monthMap[englishMonth]}"');
      return monthMap[englishMonth]!;
    }
    
    // Case-insensitive kontrol
    final cleanMonth = englishMonth.trim().toLowerCase();
    for (final entry in monthMap.entries) {
      if (entry.key.toLowerCase() == cleanMonth) {
        print('🗓️ Month converted (case insensitive): "$englishMonth" → "${entry.value}"');
        return entry.value;
      }
    }

    // Unicode karakterleri normalize et ve tekrar dene
    final normalizedInput = englishMonth
        .replaceAll('ʿ', '\'')
        .replaceAll('ā', 'a')
        .replaceAll('ī', 'i')
        .replaceAll('ū', 'u')
        .replaceAll('ḥ', 'h')
        .replaceAll('ḍ', 'd')
        .replaceAll('ṣ', 's')
        .replaceAll('ḥ', 'h')
        .toLowerCase();
        
    for (final entry in monthMap.entries) {
      final normalizedKey = entry.key
          .replaceAll('ʿ', '\'')
          .replaceAll('ā', 'a')
          .replaceAll('ī', 'i')
          .replaceAll('ū', 'u')
          .replaceAll('ḥ', 'h')
          .replaceAll('ḍ', 'd')
          .replaceAll('ṣ', 's')
          .replaceAll('ḥ', 'h')
          .toLowerCase();
          
      if (normalizedKey == normalizedInput) {
        print('🗓️ Month converted (normalized): "$englishMonth" → "${entry.value}"');
        return entry.value;
      }
    }
    
    // Partial match - contains kontrolü
    for (final entry in monthMap.entries) {
      final key = entry.key.toLowerCase();
      if (key.contains(cleanMonth) || cleanMonth.contains(key)) {
        print('🗓️ Month converted (partial): "$englishMonth" → "${entry.value}"');
        return entry.value;
      }
    }
    
    // Debugging için
    print('🗓️ WARNING - Month not found: "$englishMonth"');
    print('🗓️   Sample mappings: Muharram→Muharrem, Safar→Safer, Ramadan→Ramazan');
    
    return englishMonth; // Bulunamazsa orijinal döndür
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
                          child: _isInitialized ? PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) {
                              if (!_isNavigating && mounted) {
                                setState(() {
                                  _currentPage = index;
                                });
                                // Hijri tarih güncelleme - daha uzun debounce
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  if (_currentPage == index && mounted && !_isLoadingHijri) {
                                    _updateHijriDate(_content[index].gunNo);
                                  }
                                });
                              }
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
                          ) : const Center(child: CircularProgressIndicator()),
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
    if (_currentPage > 0 && !_isNavigating && _isInitialized) {
      _isNavigating = true;
      final targetPage = _currentPage - 1;
      _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ).then((_) {
        if (mounted) {
          setState(() {
            _currentPage = targetPage;
            _isNavigating = false;
          });
          // Önceki güne gittikten sonra Hijri tarihi güncelle
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && !_isLoadingHijri) {
              _updateHijriDate(_content[targetPage].gunNo);
            }
          });
        }
      });
    }
  }

  void _nextPage() {
    if (_currentPage < _content.length - 1 && !_isNavigating && _isInitialized) {
      _isNavigating = true;
      final targetPage = _currentPage + 1;
      _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ).then((_) {
        if (mounted) {
          setState(() {
            _currentPage = targetPage;
            _isNavigating = false;
          });
          // Sonraki güne gittikten sonra Hijri tarihi güncelle
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && !_isLoadingHijri) {
              _updateHijriDate(_content[targetPage].gunNo);
            }
          });
        }
      });
    }
  }

  void _goToToday() {
    if (!_isNavigating && _isInitialized) {
      _isNavigating = true;
      final todayIndex = _getTodayIndex().clamp(0, _content.length - 1);
      _pageController.animateToPage(
        todayIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      ).then((_) {
        if (mounted) {
          setState(() {
            _currentPage = todayIndex;
            _isNavigating = false;
          });
          // Bugüne gittikten sonra Hijri tarihi güncelle
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && !_isLoadingHijri) {
              _updateHijriDate(_content[todayIndex].gunNo);
            }
          });
        }
      });
    }
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
