import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class QiblaDirectionWidget extends StatefulWidget {
  const QiblaDirectionWidget({super.key});

  @override
  State<QiblaDirectionWidget> createState() => _QiblaDirectionWidgetState();
}

class _QiblaDirectionWidgetState extends State<QiblaDirectionWidget>
    with TickerProviderStateMixin {
  double? _qiblaDirection;
  double _compassHeading = 0;
  bool _hasPermissions = false;
  bool _isLoading = true;
  String _statusMessage = 'İzinler kontrol ediliyor...';
  
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  // Kaaba coordinates
  static const double kaabaLatitude = 21.4225;
  static const double kaabaLongitude = 39.8262;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));
    
    _initializeQibla();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _initializeQibla() async {
    await _checkPermissions();
    if (_hasPermissions) {
      await _calculateQiblaDirection();
      _startCompassListener();
    }
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _statusMessage = 'İzinler kontrol ediliyor...';
    });

    final locationStatus = await Permission.location.status;
    
    if (locationStatus.isDenied) {
      final result = await Permission.location.request();
      if (!result.isGranted) {
        setState(() {
          _hasPermissions = false;
          _isLoading = false;
          _statusMessage = 'Konum izni gerekli';
        });
        return;
      }
    }

    setState(() {
      _hasPermissions = true;
      _statusMessage = 'Kıble yönü hesaplanıyor...';
    });
  }

  Future<void> _calculateQiblaDirection() async {
    try {
      setState(() {
        _statusMessage = 'Konum alınıyor...';
      });

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final qiblaDirection = _calculateBearing(
        position.latitude,
        position.longitude,
        kaabaLatitude,
        kaabaLongitude,
      );

      setState(() {
        _qiblaDirection = qiblaDirection;
        _isLoading = false;
        _statusMessage = 'Kıble yönü bulundu';
      });

      _rotationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Konum alınamadı: ${e.toString()}';
      });
    }
  }

  double _calculateBearing(double startLat, double startLng, double endLat, double endLng) {
    final startLatRad = startLat * (math.pi / 180);
    final startLngRad = startLng * (math.pi / 180);
    final endLatRad = endLat * (math.pi / 180);
    final endLngRad = endLng * (math.pi / 180);

    final dLng = endLngRad - startLngRad;

    final y = math.sin(dLng) * math.cos(endLatRad);
    final x = math.cos(startLatRad) * math.sin(endLatRad) -
        math.sin(startLatRad) * math.cos(endLatRad) * math.cos(dLng);

    final bearing = math.atan2(y, x);
    return (bearing * (180 / math.pi) + 360) % 360;
  }

  void _startCompassListener() {
    FlutterCompass.events?.listen((CompassEvent event) {
      if (mounted && event.heading != null) {
        setState(() {
          _compassHeading = event.heading!;
        });
      }
    });
  }

  double get _qiblaAngle {
    if (_qiblaDirection == null) return 0;
    return (_qiblaDirection! - _compassHeading) * (math.pi / 180);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimationConfiguration.staggeredList(
      position: 3,
      duration: const Duration(milliseconds: 800),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.teal.shade50,
                  Colors.cyan.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.teal.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.2),
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
                          color: Colors.teal.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.explore,
                          color: Colors.teal.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kıble Yönü',
                              style: GoogleFonts.ebGaramond(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade800,
                              ),
                            ),
                            Text(
                              _statusMessage,
                              style: GoogleFonts.ebGaramond(
                                fontSize: 12,
                                color: Colors.teal.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_hasPermissions)
                        TextButton(
                          onPressed: _initializeQibla,
                          child: Text(
                            'İzin Ver',
                            style: GoogleFonts.ebGaramond(
                              fontSize: 12,
                              color: Colors.teal.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Compass
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.teal.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _statusMessage,
                                  style: GoogleFonts.ebGaramond(
                                    fontSize: 12,
                                    color: Colors.teal.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : !_hasPermissions
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.location_off,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Konum izni gerekli',
                                      style: GoogleFonts.ebGaramond(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : AnimatedBuilder(
                                animation: _rotationAnimation,
                                builder: (context, child) {
                                  return Center(
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.8),
                                        border: Border.all(
                                          color: Colors.teal.shade300,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.teal.withOpacity(0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Compass directions
                                          Positioned(
                                            top: 8,
                                            child: Text(
                                              'N',
                                              style: GoogleFonts.ebGaramond(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.teal.shade700,
                                              ),
                                            ),
                                          ),
                                          
                                          // Qibla indicator
                                          Transform.rotate(
                                            angle: _qiblaAngle * _rotationAnimation.value,
                                            child: Container(
                                              width: 4,
                                              height: 50,
                                              margin: const EdgeInsets.only(bottom: 10),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade600,
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            ),
                                          ),
                                          
                                          // Center point
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.teal.shade700,
                                            ),
                                          ),
                                          
                                          // Kaaba icon
                                          Transform.rotate(
                                            angle: _qiblaAngle * _rotationAnimation.value,
                                            child: Transform.translate(
                                              offset: const Offset(0, -35),
                                              child: Icon(
                                                Icons.location_on,
                                                color: Colors.green.shade600,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                  
                  // Direction info
                  if (_qiblaDirection != null && !_isLoading)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_qiblaDirection!.toStringAsFixed(0)}° Kıble yönü',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700,
                        ),
                      ),
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
