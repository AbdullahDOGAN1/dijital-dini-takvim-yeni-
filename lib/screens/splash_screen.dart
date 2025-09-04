import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onSplashComplete;
  
  const SplashScreen({
    super.key,
    required this.onSplashComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _fadeController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _fadeOpacity;

  @override
  void initState() {
    super.initState();
    
    // Logo animasyon controller'ı
    _logoController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Text animasyon controller'ı
    _textController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Fade out controller'ı
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    
    // Logo animasyonları
    _logoScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));
    
    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Interval(0.0, 0.6, curve: Curves.easeIn),
    ));
    
    // Text animasyonları
    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ));
    
    _textSlide = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));
    
    // Fade out animasyonu
    _fadeOpacity = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _startAnimations();
  }

  void _startAnimations() async {
    // Logo animasyonunu başlat
    await _logoController.forward();
    
    // Kısa bir bekleme
    await Future.delayed(Duration(milliseconds: 300));
    
    // Text animasyonunu başlat
    await _textController.forward();
    
    // Splash screen'i göster
    await Future.delayed(Duration(milliseconds: 1500));
    
    // Fade out animasyonu
    await _fadeController.forward();
    
    // Ana ekrana geç
    widget.onSplashComplete();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _fadeOpacity,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeOpacity.value,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1a4d2e),
                    Color(0xFF2d4a3e),
                    Color(0xFF1a4d2e),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoScale.value,
                        child: Opacity(
                          opacity: _logoOpacity.value,
                          child: Container(
                            padding: EdgeInsets.all(20),
                            child: AppLogo(
                              size: 160,
                              withAnimation: false,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  SizedBox(height: 40),
                  
                  // App Name & Subtitle
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return SlideTransition(
                        position: _textSlide,
                        child: FadeTransition(
                          opacity: _textOpacity,
                          child: Column(
                            children: [
                              // Ana başlık
                              Text(
                                'Nur Vakti',
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFffd700),
                                  letterSpacing: 1.2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              
                              SizedBox(height: 8),
                              
                              // Alt başlık
                              Text(
                                'Risale-i Nur\'dan Vecizeler',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFFffd700).withOpacity(0.9),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              
                              SizedBox(height: 4),
                              
                              // Açıklama
                              Text(
                                'Dini Günler ve Kandiller',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white.withOpacity(0.7),
                                  letterSpacing: 0.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  SizedBox(height: 60),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
