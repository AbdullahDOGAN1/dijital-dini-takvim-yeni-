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
          setState(() {
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
            setState(() {
              _statusMessage = 'Konum izni reddedildi';
              _isLoading = false;
            });
            return;
          }
        } else {
          setState(() {
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
        
        setState(() {
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
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        kaabaLatitude,
        kaabaLongitude,
      ) / 1000; // km cinsinden

      setState(() {
        _currentPosition = position;
        _qiblaDirection = qiblaDirection;
        _distanceToKaaba = distance;
        _hasLocationPermission = true;
        _isLoading = false;
        _statusMessage = 'Kıble yönü hesaplandı';
      });
    } catch (e) {
      setState(() {
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
        title: Text('Konum Servisi Kapalı', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Kıble yönünü hesaplamak için konum servisinin açık olması gerekiyor.'),
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
        content: Text('Kıble yönünü hesaplamak için konum izni gerekiyor. Bu bilgi sadece kıble yönünü belirlemek için kullanılacak.'),
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
        content: Text('Konum izni olmadan kıble yönü hesaplanamaz. Lütfen uygulama ayarlarından izin verin.'),
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
    setState(() {
      _isLoading = true;
      _statusMessage = 'Konum güncelleniyor...';
    });
    await _initializeQiblaFinder();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kıble Pusulası', style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoading)
            IconButton(
              onPressed: _refreshLocation,
              icon: Icon(Icons.refresh),
            ),
        ],
      ),
      body: Container(
        color: Colors.teal.shade50,
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

  /// Yükleme ekranı
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
          ),
          SizedBox(height: 24),
          Text(
            _statusMessage,
            style: GoogleFonts.ebGaramond(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// İzin verilmediğinde gösterilecek ekran
  Widget _buildPermissionDeniedState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 80, color: Colors.red.shade400),
            SizedBox(height: 24),
            Text(
              'Konum İzni Gerekiyor',
              style: GoogleFonts.ebGaramond(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              _statusMessage,
              style: GoogleFonts.ebGaramond(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _refreshLocation,
              icon: Icon(Icons.refresh),
              label: Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pusula görünümü
  Widget _buildCompassView() {
    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Pusula sensörü çalışmıyor',
              style: GoogleFonts.ebGaramond(fontSize: 18),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        double? heading = snapshot.data!.heading;
        if (heading == null) {
          return Center(
            child: Text(
              'Cihazınızda pusula sensörü bulunamadı',
              style: GoogleFonts.ebGaramond(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          );
        }

        // Kıble açısını hesapla
        double relativeQiblaAngle = (_qiblaDirection! - heading) % 360;
        
        return Column(
          children: [
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pusula arka planı
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        painter: CompassPainter(),
                        size: Size(280, 280),
                      ),
                    ),
                    
                    // Kıble oku
                    Transform.rotate(
                      angle: relativeQiblaAngle * pi / 180,
                      child: _buildQiblaArrow(),
                    ),
                    
                    // Merkez nokta
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.teal.shade700,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Alt bilgi kartı
            _buildInfoCard(heading),
          ],
        );
      },
    );
  }
  
  /// Kıble oku widget'ı - daha belirgin ve Kabe'yi net gösteren tasarım
  Widget _buildQiblaArrow() {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ana ok yapısı
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Kabe modeli - daha belirgin
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.amber.shade700, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.6),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    "KABE",
                    style: TextStyle(
                      color: Colors.amber.shade500,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 2),
              
              // Ok gövdesi - daha kalın ve belirgin
              Container(
                width: 12,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.green.shade700,
                      Colors.green.shade600,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 3,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
              
              // Ok başı - daha büyük ve belirgin
              ClipPath(
                clipper: ArrowClipper(),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.green.shade700,
                        Colors.green.shade900,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Parlama efekti
          Positioned(
            top: 36,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Bilgi kartı
  Widget _buildInfoCard(double heading) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Başlık
          Text(
            'Kıble Bilgisi',
            style: GoogleFonts.ebGaramond(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade700,
            ),
          ),
          
          Divider(height: 24),
          
          // Pusula bilgileri
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem('Pusula', '${heading.toInt()}°'),
              _buildInfoItem('Kıble Yönü', '${_qiblaDirection!.toInt()}°'),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Kabe bilgisi
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.straighten, size: 16, color: Colors.green.shade700),
              SizedBox(width: 8),
              Text(
                _distanceToKaaba != null
                    ? 'Kabe\'ye uzaklık: ${_distanceToKaaba!.toInt()} km'
                    : 'Kabe yönü hesaplandı',
                style: GoogleFonts.ebGaramond(fontSize: 16),
              ),
            ],
          ),
          
          if (_currentPosition != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Konum: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                style: GoogleFonts.ebGaramond(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
  
  /// Bilgi öğesi
  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.ebGaramond(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.ebGaramond(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade700,
          ),
        ),
      ],
    );
  }
}

/// Pusula çizici
class CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    
    // Arka plan
    final backgroundPaint = Paint()
      ..color = Colors.white;
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Dış çember
    final outlinePaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 1, outlinePaint);
    
    // Ana yönler
    _drawMainDirections(canvas, center, radius);
    
    // Ara yönler
    _drawSubDirections(canvas, center, radius);
    
    // Derece işaretleri
    _drawDegreeMarks(canvas, center, radius);
  }
  
  void _drawMainDirections(Canvas canvas, Offset center, double radius) {
    final mainDirectionPaint = Paint()
      ..color = Colors.teal.shade700
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
      
    final mainDirections = ['K', 'D', 'G', 'B'];
    final textStyle = TextStyle(
      color: Colors.teal.shade700,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );
    
    for (int i = 0; i < 4; i++) {
      double angle = i * 90 * pi / 180;
      
      // Çizgileri çiz
      Offset start = Offset(
        center.dx + (radius - 30) * cos(angle),
        center.dy + (radius - 30) * sin(angle),
      );
      
      Offset end = Offset(
        center.dx + (radius - 10) * cos(angle),
        center.dy + (radius - 10) * sin(angle),
      );
      
      canvas.drawLine(start, end, mainDirectionPaint);
      
      // Yön harfleri
      TextSpan span = TextSpan(
        text: mainDirections[i],
        style: textStyle,
      );
      
      TextPainter tp = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      
      tp.layout();
      
      Offset textCenter = Offset(
        center.dx + (radius - 50) * cos(angle) - tp.width / 2,
        center.dy + (radius - 50) * sin(angle) - tp.height / 2,
      );
      
      tp.paint(canvas, textCenter);
    }
  }
  
  void _drawSubDirections(Canvas canvas, Offset center, double radius) {
    final subDirectionPaint = Paint()
      ..color = Colors.teal.shade400
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
      
    for (int i = 0; i < 4; i++) {
      double angle = (i * 90 + 45) * pi / 180;
      
      Offset start = Offset(
        center.dx + (radius - 25) * cos(angle),
        center.dy + (radius - 25) * sin(angle),
      );
      
      Offset end = Offset(
        center.dx + (radius - 10) * cos(angle),
        center.dy + (radius - 10) * sin(angle),
      );
      
      canvas.drawLine(start, end, subDirectionPaint);
    }
  }
  
  void _drawDegreeMarks(Canvas canvas, Offset center, double radius) {
    final degreePaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;
      
    // 10 derece aralıklarla çizgi çiz (ana ve ara yönler hariç)
    for (int i = 0; i < 360; i += 10) {
      if (i % 45 != 0) { // Ana ve ara yönleri atla
        double angle = i * pi / 180;
        double length = i % 30 == 0 ? 8 : 5; // 30'un katlarını daha uzun yap
        
        Offset start = Offset(
          center.dx + (radius - length) * cos(angle),
          center.dy + (radius - length) * sin(angle),
        );
        
        Offset end = Offset(
          center.dx + radius * cos(angle),
          center.dy + radius * sin(angle),
        );
        
        canvas.drawLine(start, end, degreePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

/// Ok başı için özel çizim
class ArrowHeadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.green.shade800
      ..style = PaintingStyle.fill
      ..strokeJoin = StrokeJoin.round;
      
    // Daha net ve keskin bir ok başı
    final Path path = Path();
    path.moveTo(size.width / 2, 0); // Üst orta nokta
    path.lineTo(0, size.height); // Sol alt köşe
    path.lineTo(size.width / 2, size.height * 0.7); // Alt orta çentik
    path.lineTo(size.width, size.height); // Sağ alt köşe
    path.close(); // Şekli kapat
    
    // Ok gölgesi
    final Paint shadowPaint = Paint()
      ..color = Colors.black26
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);
    
    final Path shadowPath = Path();
    shadowPath.addPath(path, Offset(2, 2));
    canvas.drawPath(shadowPath, shadowPaint);
    
    // Ana ok şekli
    canvas.drawPath(path, paint);
    
    // Ok vurgusu
    final Paint highlightPaint = Paint()
      ..color = Colors.green.shade500
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    canvas.drawLine(
      Offset(size.width / 4, size.height * 0.5), 
      Offset(size.width * 3 / 4, size.height * 0.5),
      highlightPaint,
    );
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
