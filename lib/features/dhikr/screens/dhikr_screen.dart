import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DhikrScreen extends StatefulWidget {
  const DhikrScreen({super.key});

  @override
  State<DhikrScreen> createState() => _DhikrScreenState();
}

class _DhikrScreenState extends State<DhikrScreen>
    with TickerProviderStateMixin {
  int _counter = 0;
  final int _targetCount = 33;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    
    // Load saved counter value
    _loadCounter();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  /// Load counter value from SharedPreferences
  Future<void> _loadCounter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCounter = prefs.getInt('dhikr_count') ?? 0;
      
      if (mounted) {
        setState(() {
          _counter = savedCounter;
        });
      }
    } catch (e) {
      debugPrint('Error loading counter: $e');
    }
  }

  /// Save counter value to SharedPreferences
  Future<void> _saveCounter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('dhikr_count', _counter);
    } catch (e) {
      debugPrint('Error saving counter: $e');
    }
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
    
    // Haptic feedback for user engagement
    HapticFeedback.lightImpact();
    
    // Save the updated counter
    _saveCounter();
    
    // Animation feedback
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
  }

  void _resetCounter() {
    setState(() {
      _counter = 0;
    });
    
    // Save the reset counter
    _saveCounter();
    
    // Haptic feedback for reset action
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Zikirmatik',
          style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _resetCounter),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50, Colors.teal.shade50],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress indicator
              Container(
                margin: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Subhanallahi ve bihamdihi',
                      style: GoogleFonts.ebGaramond(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _counter / _targetCount,
                      backgroundColor: Colors.green.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.green.shade600,
                      ),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_counter / $_targetCount',
                      style: GoogleFonts.ebGaramond(
                        fontSize: 16,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Main counter area
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Counter display
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '$_counter',
                            style: GoogleFonts.ebGaramond(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),

                      // Tap button with animation
                      GestureDetector(
                        onTap: _incrementCounter,
                        child: AnimatedBuilder(
                          animation: _scaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _scaleAnimation.value,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.green.shade400,
                                      Colors.green.shade600,
                                      Colors.green.shade800,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.4),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.touch_app,
                                        size: 48,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'TIKLA',
                                        style: GoogleFonts.ebGaramond(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom info
              Container(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _counter >= _targetCount
                      ? '🎉 Tebrikler! Hedefinizi tamamladınız!'
                      : 'Zikir yapmak için büyük butona dokunun',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 16,
                    color: _counter >= _targetCount
                        ? Colors.green.shade700
                        : Colors.green.shade600,
                    fontWeight: _counter >= _targetCount
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
