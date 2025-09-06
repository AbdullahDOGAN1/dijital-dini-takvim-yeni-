import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TasbihCounterWidget extends StatefulWidget {
  const TasbihCounterWidget({super.key});

  @override
  State<TasbihCounterWidget> createState() => _TasbihCounterWidgetState();
}

class _TasbihCounterWidgetState extends State<TasbihCounterWidget>
    with TickerProviderStateMixin {
  int _count = 0;
  int _target = 33;
  bool _isCompact = true;
  
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  final List<int> _targetOptions = [33, 99, 100, 1000];
  
  // Default dhikr phrases
  final List<String> _dhikrPhrases = [
    'سُبْحَانَ اللهِ',
    'الْحَمْدُ لِلَّهِ',
    'اللهُ أَكْبَرُ',
    'لاَ إِلَهَ إِلاَّ اللهُ',
    'أَسْتَغْفِرُ اللهَ',
    'لاَ حَوْلَ وَلاَ قُوَّةَ إِلاَّ بِاللهِ',
  ];
  
  int _selectedPhraseIndex = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.elasticOut,
    ));
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    
    _loadSavedData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _count = prefs.getInt('tasbih_count') ?? 0;
      _target = prefs.getInt('tasbih_target') ?? 33;
      _selectedPhraseIndex = prefs.getInt('tasbih_phrase') ?? 0;
    });
    _updateProgress();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tasbih_count', _count);
    await prefs.setInt('tasbih_target', _target);
    await prefs.setInt('tasbih_phrase', _selectedPhraseIndex);
  }

  void _increment() {
    setState(() {
      _count++;
    });
    
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    // Pulse animation
    _pulseController.forward().then((_) {
      _pulseController.reverse();
    });
    
    _updateProgress();
    _saveData();
    
    // Check if target reached
    if (_count % _target == 0) {
      _showCompletionDialog();
      HapticFeedback.heavyImpact();
    }
  }

  void _updateProgress() {
    final progress = (_count % _target) / _target;
    _progressController.animateTo(progress);
  }

  void _reset() {
    setState(() {
      _count = 0;
    });
    _progressController.reset();
    _saveData();
    HapticFeedback.mediumImpact();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.celebration, color: Colors.green.shade600),
            const SizedBox(width: 8),
            Text(
              'Tebrikler!',
              style: GoogleFonts.ebGaramond(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          '$_target kez ${_dhikrPhrases[_selectedPhraseIndex]} çekmeyi tamamladınız!',
          style: GoogleFonts.ebGaramond(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Devam Et',
              style: GoogleFonts.ebGaramond(
                color: Colors.green.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const SizedBox(height: 20),
              
              Text(
                'Tesbih Ayarları',
                style: GoogleFonts.ebGaramond(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Target selection
              Text(
                'Hedef Sayı',
                style: GoogleFonts.ebGaramond(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _targetOptions.map((target) {
                  return ChoiceChip(
                    label: Text('$target'),
                    selected: _target == target,
                    onSelected: (selected) {
                      if (selected) {
                        setModalState(() {
                          _target = target;
                        });
                        setState(() {
                          _target = target;
                        });
                        _updateProgress();
                        _saveData();
                      }
                    },
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 20),
              
              // Phrase selection
              Text(
                'Zikir Seçimi',
                style: GoogleFonts.ebGaramond(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                child: ListView.builder(
                  itemCount: _dhikrPhrases.length,
                  itemBuilder: (context, index) {
                    return RadioListTile<int>(
                      title: Text(
                        _dhikrPhrases[index],
                        style: GoogleFonts.amiri(fontSize: 18),
                      ),
                      value: index,
                      groupValue: _selectedPhraseIndex,
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() {
                            _selectedPhraseIndex = value;
                          });
                          setState(() {
                            _selectedPhraseIndex = value;
                          });
                          _saveData();
                        }
                      },
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 20),
              
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Tamam',
                  style: GoogleFonts.ebGaramond(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (_count % _target) / _target;

    return AnimationConfiguration.staggeredList(
      position: 5,
      duration: const Duration(milliseconds: 800),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.brown.shade50,
                  Colors.orange.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.brown.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.brown.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.spa,
                          color: Colors.brown.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tesbih Sayacı',
                              style: GoogleFonts.ebGaramond(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown.shade800,
                              ),
                            ),
                            Text(
                              '${_count % _target}/$_target',
                              style: GoogleFonts.ebGaramond(
                                fontSize: 14,
                                color: Colors.brown.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _showSettings,
                        icon: Icon(
                          Icons.settings,
                          color: Colors.brown.shade600,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Current dhikr phrase
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.brown.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _dhikrPhrases[_selectedPhraseIndex],
                      style: GoogleFonts.amiri(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Counter and progress
                  Row(
                    children: [
                      // Progress circle
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return CircularPercentIndicator(
                            radius: 50,
                            lineWidth: 6,
                            percent: _progressAnimation.value,
                            center: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${_count % _target}',
                                  style: GoogleFonts.ebGaramond(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.brown.shade700,
                                  ),
                                ),
                                Text(
                                  '$_target',
                                  style: GoogleFonts.ebGaramond(
                                    fontSize: 12,
                                    color: Colors.brown.shade500,
                                  ),
                                ),
                              ],
                            ),
                            progressColor: Colors.brown.shade600,
                            backgroundColor: Colors.brown.shade200,
                            circularStrokeCap: CircularStrokeCap.round,
                          );
                        },
                      ),
                      
                      const SizedBox(width: 20),
                      
                      // Counter button and total
                      Expanded(
                        child: Column(
                          children: [
                            // Total count
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.brown.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Toplam: $_count',
                                style: GoogleFonts.ebGaramond(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown.shade700,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Count button
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: GestureDetector(
                                    onTap: _increment,
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.brown.shade400,
                                            Colors.brown.shade600,
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.brown.withOpacity(0.4),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Reset button
                            TextButton.icon(
                              onPressed: _reset,
                              icon: Icon(
                                Icons.refresh,
                                size: 16,
                                color: Colors.brown.shade600,
                              ),
                              label: Text(
                                'Sıfırla',
                                style: GoogleFonts.ebGaramond(
                                  fontSize: 12,
                                  color: Colors.brown.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
