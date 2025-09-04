import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modern zikirmatik ekranı
class DhikrScreen extends StatefulWidget {
  const DhikrScreen({super.key});

  @override
  State<DhikrScreen> createState() => _DhikrScreenState();
}

class _DhikrScreenState extends State<DhikrScreen>
    with TickerProviderStateMixin {
  int _counter = 0;
  String _selectedDhikr = 'Subhanallah';
  late AnimationController _scaleController;
  late AnimationController _rippleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;

  // Zikir çeşitleri ve hedef sayıları
  final Map<String, Map<String, dynamic>> _dhikrOptions = {
    'Subhanallah': {
      'text': 'سُبْحَانَ اللَّه',
      'meaning': 'Allah tüm noksanlıklardan uzaktır',
      'target': 33,
      'color': Colors.green,
    },
    'Alhamdulillah': {
      'text': 'الْحَمْدُ لِلَّه',
      'meaning': 'Hamd Allah\'a mahsustur',
      'target': 33,
      'color': Colors.blue,
    },
    'Allahu Akbar': {
      'text': 'اللَّهُ أَكْبَر',
      'meaning': 'Allah en büyüktür',
      'target': 34,
      'color': Colors.purple,
    },
    'La ilahe illallah': {
      'text': 'لَا إِلَٰهَ إِلَّا اللَّهُ',
      'meaning': 'Allah\'tan başka ilah yoktur',
      'target': 100,
      'color': Colors.orange,
    },
    'Astağfirullah': {
      'text': 'أَسْتَغْفِرُ اللَّهَ',
      'meaning': 'Allah\'tan bağışlanma dilerim',
      'target': 100,
      'color': Colors.red,
    },
    'La havle ve la quvvete illa billah': {
      'text': 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
      'meaning': 'Güç ve kuvvet yalnızca Allah\'tandır',
      'target': 100,
      'color': Colors.teal,
    },
  };

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );
    
    // Load saved data
    _loadDhikrData();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  /// Zikir verilerini yükle (sayaç ve seçilen zikir)
  Future<void> _loadDhikrData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDhikr = prefs.getString('selected_dhikr') ?? 'Subhanallah';
      
      setState(() {
        _selectedDhikr = savedDhikr;
      });
      
      final savedCounter = prefs.getInt('dhikr_count_$_selectedDhikr') ?? 0;
      
      if (mounted) {
        setState(() {
          _counter = savedCounter;
        });
      }
    } catch (e) {
      print('Error loading dhikr data: $e');
    }
  }

  /// Sayacı kaydet
  Future<void> _saveCounter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('dhikr_count_$_selectedDhikr', _counter);
      await prefs.setString('selected_dhikr', _selectedDhikr);
    } catch (e) {
      print('Error saving dhikr data: $e');
    }
  }

  /// Sayacı artır
  void _incrementCounter() {
    HapticFeedback.lightImpact();
    
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
    
    _rippleController.forward().then((_) {
      _rippleController.reset();
    });
    
    setState(() {
      _counter++;
    });
    
    _saveCounter();
  }

  /// Sayacı sıfırla
  void _resetCounter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sayacı Sıfırla'),
        content: Text('$_selectedDhikr sayacını sıfırlamak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _counter = 0;
              });
              _saveCounter();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Sıfırla'),
          ),
        ],
      ),
    );
  }

  /// Zikir değiştir
  void _changeDhikr(String newDhikr) async {
    // Önce mevcut sayacı kaydet
    await _saveCounter();
    
    // Yeni zikri yükle
    setState(() {
      _selectedDhikr = newDhikr;
    });
    
    // Yeni zikrin sayacını yükle
    final prefs = await SharedPreferences.getInstance();
    final newCounter = prefs.getInt('dhikr_count_$newDhikr') ?? 0;
    
    setState(() {
      _counter = newCounter;
    });
    
    await _saveCounter();
  }

  /// Zikir seçme bottom sheet
  void _showDhikrSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            
            Text(
              'Zikir Seçin',
              style: GoogleFonts.ebGaramond(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            
            // Zikir listesi
            ...(_dhikrOptions.entries.map((entry) {
              final dhikrName = entry.key;
              final dhikrData = entry.value;
              final isSelected = _selectedDhikr == dhikrName;
              
              return Container(
                margin: EdgeInsets.symmetric(vertical: 4),
                child: Card(
                  color: isSelected ? dhikrData['color'].withOpacity(0.1) : null,
                  child: ListTile(
                    leading: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: dhikrData['color'],
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      dhikrName,
                      style: GoogleFonts.ebGaramond(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      dhikrData['meaning'],
                      style: GoogleFonts.ebGaramond(fontSize: 12),
                    ),
                    trailing: Text(
                      'Hedef: ${dhikrData['target']}',
                      style: GoogleFonts.ebGaramond(
                        fontSize: 12,
                        color: dhikrData['color'],
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _changeDhikr(dhikrName);
                    },
                  ),
                ),
              );
            }).toList()),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentDhikr = _dhikrOptions[_selectedDhikr]!;
    final progress = (_counter / currentDhikr['target']).clamp(0.0, 1.0);
    final isCompleted = _counter >= currentDhikr['target'];
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Zikirmatik', style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold)),
        backgroundColor: currentDhikr['color'],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showDhikrSelector,
            icon: Icon(Icons.tune),
            tooltip: 'Zikir Değiştir',
          ),
          IconButton(
            onPressed: _resetCounter,
            icon: Icon(Icons.refresh),
            tooltip: 'Sıfırla',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              currentDhikr['color'].withOpacity(0.1),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Üst bilgi kartı
              Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      _selectedDhikr,
                      style: GoogleFonts.ebGaramond(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: currentDhikr['color'],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      currentDhikr['text'],
                      style: GoogleFonts.ebGaramond(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      currentDhikr['meaning'],
                      style: GoogleFonts.ebGaramond(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // İlerleme çubuğu
              Container(
                margin: EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$_counter',
                          style: GoogleFonts.ebGaramond(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: currentDhikr['color'],
                          ),
                        ),
                        Text(
                          '${currentDhikr['target']}',
                          style: GoogleFonts.ebGaramond(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(currentDhikr['color']),
                      minHeight: 8,
                    ),
                    SizedBox(height: 8),
                    Text(
                      isCompleted 
                          ? 'Tebrikler! Hedefe ulaştınız 🎉' 
                          : '${currentDhikr['target'] - _counter} kez daha',
                      style: GoogleFonts.ebGaramond(
                        fontSize: 14,
                        color: isCompleted ? Colors.green : Colors.grey.shade600,
                        fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              Spacer(),
              
              // Ana zikir butonu
              Center(
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Ripple efekti
                          AnimatedBuilder(
                            animation: _rippleAnimation,
                            builder: (context, child) {
                              return Container(
                                width: 200 + (_rippleAnimation.value * 50),
                                height: 200 + (_rippleAnimation.value * 50),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: currentDhikr['color'].withOpacity(
                                    0.3 * (1 - _rippleAnimation.value),
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          // Ana buton
                          GestureDetector(
                            onTap: _incrementCounter,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: currentDhikr['color'],
                                boxShadow: [
                                  BoxShadow(
                                    color: currentDhikr['color'].withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$_counter',
                                    style: GoogleFonts.ebGaramond(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (isCompleted)
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              Spacer(),
              
              // Alt butonlar
              Padding(
                padding: EdgeInsets.all(32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.tune,
                      label: 'Zikir Değiştir',
                      onPressed: _showDhikrSelector,
                      color: Colors.blue,
                    ),
                    _buildActionButton(
                      icon: Icons.refresh,
                      label: 'Sıfırla',
                      onPressed: _resetCounter,
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Column(
      children: [
        FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: color,
          heroTag: label,
          child: Icon(icon, color: Colors.white),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.ebGaramond(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
