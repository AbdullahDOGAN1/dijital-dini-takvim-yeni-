// ignore_for_file: avoid_print

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';

/// Kıble pusulası ekranı
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  // Kabe koordinatları (Mekke, Suudi Arabistan)
  static const double kaabaLatitude = 21.4225;
  static const double kaabaLongitude = 39.8262;

  // Durum değişkenleri
  bool _isLoading = true;
  bool _hasLocationPermission = false;
  double? _qiblaDirection;
  String _statusMessage = 'Konum bilgisi alınıyor...';
  Position? _currentPosition;
  double? _distanceToKaaba;

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _initializeQiblaFinder();
  }

  /// Kıble bulucu başlat
  Future<void> _initializeQiblaFinder() async {
    try {
      // 1. Konum servisini kontrol et
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        bool? openLocationService = await _showLocationServiceDialog();
        if (openLocationService == true) {
          await Geolocator.openLocationSettings();
          await Future.delayed(const Duration(seconds: 3));
          serviceEnabled = await Geolocator.isLocationServiceEnabled();
        }

        if (!serviceEnabled) {
          _safeSetState(() {
            _statusMessage = 'Konum servisi kapalı';
            _isLoading = false;
          });
          return;
        }
      }

      // 2. İzinleri kontrol et
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // Açıklama diyaloğu göster
        bool? shouldRequest = await _showPermissionExplanationDialog();

        if (shouldRequest == true) {
          permission = await Geolocator.requestPermission();

          if (permission == LocationPermission.denied) {
            _safeSetState(() {
              _statusMessage = 'Konum izni reddedildi';
              _isLoading = false;
            });
            return;
          }
        } else {
          _safeSetState(() {
            _statusMessage = 'Konum izni verilmedi';
            _isLoading = false;
          });
          return;
        }
      }

      // 3. İzin kalıcı olarak reddedilmişse
      if (permission == LocationPermission.deniedForever) {
        bool? openSettings = await _showAppSettingsDialog();
        if (openSettings == true) {
          await Geolocator.openAppSettings();
        }

        _safeSetState(() {
          _statusMessage = 'Konum izni kalıcı olarak reddedildi';
          _isLoading = false;
        });
        return;
      }

      // 4. Konumu al
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      );

      // 5. Kıble açısını hesapla
      double qiblaDirection = Geolocator.bearingBetween(
        position.latitude,
        position.longitude,
        kaabaLatitude,
        kaabaLongitude,
      );

      // 6. Mesafeyi hesapla
      double distance =
          Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            kaabaLatitude,
            kaabaLongitude,
          ) /
          1000; // km cinsinden

      _safeSetState(() {
        _currentPosition = position;
        _qiblaDirection = qiblaDirection;
        _distanceToKaaba = distance;
        _hasLocationPermission = true;
        _isLoading = false;
        _statusMessage = 'Kıble yönü hesaplandı';
      });
    } catch (e) {
      _safeSetState(() {
        _statusMessage = 'Hata oluştu: Konum alınamadı';
        _isLoading = false;
      });
      print('Kıble bulucuda hata: $e');
    }
  }

  /// Konum servisi kapalıysa gösterilecek diyalog
  Future<bool?> _showLocationServiceDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Konum Servisi Kapalı',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Kıble yönünü hesaplamak için konum servisinin açık olması gerekiyor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Ayarları Aç'),
          ),
        ],
      ),
    );
  }

  /// İzin açıklaması diyaloğu
  Future<bool?> _showPermissionExplanationDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Konum İzni Gerekiyor'),
        content: Text(
          'Kıble yönünü hesaplamak için konum izni gerekiyor. Bu bilgi sadece kıble yönünü belirlemek için kullanılacak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('İzin Ver'),
          ),
        ],
      ),
    );
  }

  /// Uygulama ayarları diyaloğu
  Future<bool?> _showAppSettingsDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konum İzni Verilmedi'),
        content: Text(
          'Konum izni olmadan kıble yönü hesaplanamaz. Lütfen uygulama ayarlarından izin verin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Ayarları Aç'),
          ),
        ],
      ),
    );
  }

  /// Konumu yenile
  Future<void> _refreshLocation() async {
    _safeSetState(() {
      _isLoading = true;
      _statusMessage = 'Konum güncelleniyor...';
    });
    await _initializeQiblaFinder();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Kıble Pusulası',
          style: GoogleFonts.ebGaramond(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isLoading)
            IconButton(
              onPressed: _refreshLocation,
              icon: const Icon(Icons.refresh, color: Colors.white),
            ),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal.shade900,
              const Color(0xFF003D33), // Koyu İslami Yeşil
              Colors.black87,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? _buildLoadingState()
              : _hasLocationPermission
              ? _buildCompassView()
              : _buildPermissionDeniedState(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
          ),
          const SizedBox(height: 24),
          Text(
            _statusMessage,
            style: GoogleFonts.ebGaramond(fontSize: 18, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDeniedState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off, size: 80, color: Colors.amber.shade400),
              const SizedBox(height: 24),
              Text(
                'Konum İzni Gerekiyor',
                style: GoogleFonts.ebGaramond(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _statusMessage,
                style: GoogleFonts.ebGaramond(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _refreshLocation,
                icon: const Icon(Icons.refresh, color: Colors.teal),
                label: const Text(
                  'Tekrar Dene',
                  style: TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompassView() {
    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Pusula sensörü çalışmıyor',
              style: GoogleFonts.ebGaramond(
                fontSize: 18,
                color: Colors.red.shade300,
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.amber),
          );
        }

        double? heading = snapshot.data!.heading;
        if (heading == null) {
          return Center(
            child: Text(
              'Cihazınızda pusula sensörü bulunamadı',
              style: GoogleFonts.ebGaramond(fontSize: 18, color: Colors.amber),
              textAlign: TextAlign.center,
            ),
          );
        }

        double relativeQiblaAngle = (_qiblaDirection! - heading) % 360;
        bool isFacingQibla =
            relativeQiblaAngle < 5 ||
            relativeQiblaAngle > 355 ||
            relativeQiblaAngle < -355;

        return Column(
          children: [
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Dış parlamalı gölge
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isFacingQibla
                                ? Colors.amber.withOpacity(0.6)
                                : Colors.teal.withOpacity(0.2),
                            blurRadius: isFacingQibla ? 40 : 20,
                            spreadRadius: isFacingQibla ? 10 : 5,
                          ),
                        ],
                      ),
                    ),

                    // Pusula Arka Planı (Kuzey referanslı)
                    Transform.rotate(
                      angle: -heading * pi / 180,
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0A1A17), // Koyu Arka Plan
                          border: Border.all(
                            color: Colors.amber.shade700,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 15,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: CustomPaint(painter: ModernCompassPainter()),
                      ),
                    ),

                    // Kıble Oku
                    Transform.rotate(
                      angle: relativeQiblaAngle * pi / 180,
                      child: _buildMaccahArrow(),
                    ),

                    // Merkez Noktası
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.amber.shade500,
                        border: Border.all(color: Colors.black87, width: 4),
                        boxShadow: const [
                          BoxShadow(color: Colors.black54, blurRadius: 4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bilgi Kartı
            _buildInfoCard(heading, isFacingQibla),
          ],
        );
      },
    );
  }

  Widget _buildMaccahArrow() {
    return SizedBox(
      width: 240,
      height: 240,
      child: CustomPaint(painter: ModernQiblaArrowPainter()),
    );
  }

  Widget _buildInfoCard(double heading, bool isFacingQibla) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isFacingQibla ? Colors.amber.shade500 : Colors.white24,
          width: isFacingQibla ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoItem('Pusula', '°', icon: Icons.explore),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildInfoItem('Kıble', '°', icon: Icons.navigation),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on,
                size: 20,
                color: isFacingQibla ? Colors.amber : Colors.teal.shade200,
              ),
              const SizedBox(width: 8),
              Text(
                _distanceToKaaba != null
                    ? 'Kabe\'ye uzaklık:  km'
                    : 'Hesaplanıyor...',
                style: GoogleFonts.ebGaramond(
                  fontSize: 18,
                  color: isFacingQibla ? Colors.amber : Colors.white,
                  fontWeight: isFacingQibla
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {required IconData icon}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.teal.shade200),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.ebGaramond(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.ebGaramond(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class ModernCompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final tickPaint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 1.5;

    final boldTickPaint = Paint()
      ..color = Colors.amber.shade300
      ..strokeWidth = 3;

    final textStyle = const TextStyle(
      color: Colors.white70,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );

    for (int i = 0; i < 360; i += 5) {
      bool isMainDirection = i % 90 == 0;
      bool isSubDirection = i % 30 == 0;

      double tickRadiusTop =
          radius - (isMainDirection ? 0 : (isSubDirection ? 5 : 10));
      double tickRadiusBottom = radius - (isMainDirection ? 18 : 14);

      double angle = (i - 90) * pi / 180;
      Offset p1 = Offset(
        center.dx + tickRadiusTop * cos(angle),
        center.dy + tickRadiusTop * sin(angle),
      );
      Offset p2 = Offset(
        center.dx + tickRadiusBottom * cos(angle),
        center.dy + tickRadiusBottom * sin(angle),
      );

      canvas.drawLine(p1, p2, isMainDirection ? boldTickPaint : tickPaint);

      // Ana Yönler
      if (isMainDirection) {
        String dirText = i == 0
            ? 'K'
            : i == 90
            ? 'D'
            : i == 180
            ? 'G'
            : 'B';

        TextSpan span = TextSpan(
          text: dirText,
          style: isMainDirection && i == 0
              ? textStyle.copyWith(color: Colors.redAccent, fontSize: 22)
              : textStyle.copyWith(color: Colors.amber.shade200),
        );
        TextPainter tp = TextPainter(
          text: span,
          textDirection: TextDirection.ltr,
        );
        tp.layout();

        double textOffset = radius - 35;
        Offset tPos = Offset(
          center.dx + textOffset * cos(angle) - tp.width / 2,
          center.dy + textOffset * sin(angle) - tp.height / 2,
        );
        tp.paint(canvas, tPos);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ModernQiblaArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.amber.shade300, Colors.amber.shade700],
      ).createShader(Rect.fromCenter(center: center, width: 8, height: 160))
      ..style = PaintingStyle.fill
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    // Uzun ince gövde
    canvas.drawLine(
      Offset(center.dx, center.dy + 35),
      Offset(center.dx, center.dy - 100),
      bodyPaint,
    );

    // Ok Başı
    final headPaint = Paint()
      ..color = Colors.amber.shade400
      ..style = PaintingStyle.fill;

    final headPath = Path();
    headPath.moveTo(center.dx, center.dy - 125);
    headPath.lineTo(center.dx - 18, center.dy - 90);
    headPath.lineTo(center.dx, center.dy - 100);
    headPath.lineTo(center.dx + 18, center.dy - 90);
    headPath.close();

    canvas.drawShadow(headPath, Colors.black, 4, true);
    canvas.drawPath(headPath, headPaint);

    // Kabe
    _drawModernKaaba(canvas, Offset(center.dx, center.dy - 135));
  }

  void _drawModernKaaba(Canvas canvas, Offset position) {
    final kaabaRect = Rect.fromCenter(center: position, width: 26, height: 26);
    final kaabaPaint = Paint()..color = const Color(0xFF111111);

    canvas.drawShadow(Path()..addRect(kaabaRect), Colors.black, 6, true);
    canvas.drawRRect(
      RRect.fromRectAndRadius(kaabaRect, const Radius.circular(3)),
      kaabaPaint,
    );

    final goldPaint = Paint()
      ..color = Colors.amber.shade500
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(kaabaRect, const Radius.circular(3)),
      goldPaint,
    );
    canvas.drawLine(
      Offset(position.dx - 12, position.dy - 5),
      Offset(position.dx + 12, position.dy - 5),
      goldPaint,
    );

    final doorPaint = Paint()
      ..color = Colors.amber.shade500
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(
        position.dx - 3,
        position.dy + 2,
        position.dx + 3,
        position.dy + 12,
      ),
      doorPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
