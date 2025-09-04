import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                    // Pusula arka planı - gönderilen görsele benzer yeşil çerçeveli tasarım
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.green,
                          width: 10,
                        ),
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
  
  /// Kıble oku widget'ı - gönderilen görsele benzer kırmızı ok tasarımı
  Widget _buildQiblaArrow() {
    // Görseldeki gibi kırmızı üçgen ok
    return SizedBox(
      width: 240,
      height: 240,
      child: CustomPaint(
        size: const Size(240, 240),
        painter: QiblaArrowPainter(),
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
              _buildInfoItem('Pusula', '${heading.toInt()}°', icon: Icons.explore),
              _buildInfoItem('Kıble Yönü', '${_qiblaDirection!.toInt()}°', icon: Icons.navigation),
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
  Widget _buildInfoItem(String label, String value, {IconData? icon}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: Colors.teal.shade600,
              ),
              SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.ebGaramond(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
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

/// Pusula çizici - daha modern yeşil renkli tasarım
class CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    
    // Yeşil dış çerçeve (gönderilen görseldeki gibi)
    final outerRingPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 6, outerRingPaint);
    
    // Beyaz arka plan
    final backgroundPaint = Paint()
      ..color = Colors.white;
    canvas.drawCircle(center, radius - 12, backgroundPaint);
    
    // Dış çember (ince gri çizgi)
    final outlinePaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 13, outlinePaint);
    
    // Kabe simgesini çiz (siyah kare, üst tarafta)
    _drawKaabaSymbol(canvas, center, radius);
    
    // Ana yönler
    _drawMainDirections(canvas, center, radius);
    
    // Ara yönler
    _drawSubDirections(canvas, center, radius);
    
    // Derece işaretleri
    _drawDegreeMarks(canvas, center, radius);
  }
  
  // Kabe simgesi çizimi (görseldeki gibi üst kısımda)
  void _drawKaabaSymbol(Canvas canvas, Offset center, double radius) {
    final kaabaPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    
    // Görseldeki gibi üst kısma yerleştir
    final rect = Rect.fromCenter(
      center: Offset(center.dx, center.dy - radius + 24), 
      width: 16, 
      height: 16
    );
    
    // Kabe'nin içindeki altın renkli detay
    canvas.drawRect(rect, kaabaPaint);
    
    // Kabe'nin altın kenarı
    final borderPaint = Paint()
      ..color = Colors.amber.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawRect(rect, borderPaint);
  }
  
  void _drawMainDirections(Canvas canvas, Offset center, double radius) {
    // Not: Pusula yönleri, 0 derece = kuzey, 90 derece = doğu, 180 derece = güney, 270 derece = batı
    // Ama cos ve sin fonksiyonları için 0 derece = sağ, 90 derece = aşağı olduğundan bir düzeltme yapıyoruz
    
    // Kuzey (yukarı) - kırmızı renkle vurgulanır
    _drawDirectionMark(canvas, center, radius, 'K', -90, Colors.red.shade700);
    
    // Doğu (sağ)
    _drawDirectionMark(canvas, center, radius, 'D', 0, Colors.teal.shade700);
    
    // Güney (aşağı)
    _drawDirectionMark(canvas, center, radius, 'G', 90, Colors.teal.shade700);
    
    // Batı (sol)
    _drawDirectionMark(canvas, center, radius, 'B', 180, Colors.teal.shade700);
  }
  
  // Yön işareti çizimi için yardımcı metot
  void _drawDirectionMark(Canvas canvas, Offset center, double radius, String text, double angleDegrees, Color color) {
    final directionPaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
      
    double angleRadians = angleDegrees * pi / 180;
    
    // Çizgiyi çiz
    Offset start = Offset(
      center.dx + (radius - 30) * cos(angleRadians),
      center.dy + (radius - 30) * sin(angleRadians),
    );
    
    Offset end = Offset(
      center.dx + (radius - 10) * cos(angleRadians),
      center.dy + (radius - 10) * sin(angleRadians),
    );
    
    canvas.drawLine(start, end, directionPaint);
    
    // Yön harfini çiz
    final textStyle = TextStyle(
      color: color,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );
    
    final textSpan = TextSpan(
      text: text,
      style: textStyle,
    );
    
    final tp = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    
    tp.layout();
    
    final textPosition = Offset(
      center.dx + (radius - 50) * cos(angleRadians) - tp.width / 2,
      center.dy + (radius - 50) * sin(angleRadians) - tp.height / 2,
    );
    
    tp.paint(canvas, textPosition);
  }
  
  void _drawSubDirections(Canvas canvas, Offset center, double radius) {
    
    // Kuzeydoğu (sağ üst)
    _drawSubDirectionMark(canvas, center, radius, -45);
    
    // Güneydoğu (sağ alt)
    _drawSubDirectionMark(canvas, center, radius, 45);
    
    // Güneybatı (sol alt)
    _drawSubDirectionMark(canvas, center, radius, 135);
    
    // Kuzeybatı (sol üst)
    _drawSubDirectionMark(canvas, center, radius, -135);
  }
  
  // Ara yön işareti çizimi için yardımcı metot
  void _drawSubDirectionMark(Canvas canvas, Offset center, double radius, double angleDegrees) {
    final subDirectionPaint = Paint()
      ..color = Colors.teal.shade400
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
      
    double angleRadians = angleDegrees * pi / 180;
    
    Offset start = Offset(
      center.dx + (radius - 25) * cos(angleRadians),
      center.dy + (radius - 25) * sin(angleRadians),
    );
    
    Offset end = Offset(
      center.dx + (radius - 10) * cos(angleRadians),
      center.dy + (radius - 10) * sin(angleRadians),
    );
    
    canvas.drawLine(start, end, subDirectionPaint);
  }
  
  void _drawDegreeMarks(Canvas canvas, Offset center, double radius) {
    final degreePaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;
      
    // 10 derece aralıklarla çizgi çiz (ana ve ara yönler hariç)
    // Not: Pusula açılarını çizerken, 0 derece = kuzey (yukarı) olmalı
    // Koordinat sisteminde yukarı -90 derece, sağ 0 derece olduğu için bir dönüşüm yapıyoruz
    for (int i = 0; i < 360; i += 10) {
      // Ana yönler (0, 90, 180, 270) ve ara yönleri (45, 135, 225, 315) atla
      if (i % 45 != 0) { 
        // Pusula açısından matematiksel açıya dönüşüm: 
        // 0 -> -90, 90 -> 0, 180 -> 90, 270 -> 180, 360 -> 270
        double mathAngle = (i - 90) * pi / 180;
        
        // 30 derece aralıklarla biraz daha uzun işaretler
        double length = i % 30 == 0 ? 8 : 5;
        
        Offset start = Offset(
          center.dx + (radius - length) * cos(mathAngle),
          center.dy + (radius - length) * sin(mathAngle),
        );
        
        Offset end = Offset(
          center.dx + radius * cos(mathAngle),
          center.dy + radius * sin(mathAngle),
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

/// Ok şekli için clipper
class ArrowClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Kabe desenlerini çizmek için özel painter
class KaabaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    
    // Altın rengi desenler
    final designPaint = Paint()
      ..color = Colors.amber.shade700.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // Yatay çizgiler
    for (int i = 1; i < 4; i++) {
      double y = height * i / 4;
      canvas.drawLine(
        Offset(0, y),
        Offset(width, y),
        designPaint,
      );
    }
    
    // Dikey çizgiler
    for (int i = 1; i < 4; i++) {
      double x = width * i / 4;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, height),
        designPaint,
      );
    }
    
    // Kabe örtüsü üzerindeki karakteristik desenler
    final decorPaint = Paint()
      ..color = Colors.amber.shade600.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    // Üst orta desen
    final centerDesign = Path();
    centerDesign.addOval(Rect.fromCenter(
      center: Offset(width / 2, height / 4),
      width: width / 4,
      height: width / 4,
    ));
    canvas.drawPath(centerDesign, decorPaint);
    
    // Kenar süslemeleri
    final borderPaint = Paint()
      ..color = Colors.amber.shade500.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawRect(
      Rect.fromLTRB(2, 2, width - 2, height - 2),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Kıble oku çizici - görseldeki gibi kırmızı ok + Kabe ikonu
class QiblaArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Ok gövdesi - ince ve uzun
    final bodyPaint = Paint()
      ..color = Colors.red.shade600
      ..style = PaintingStyle.fill
      ..strokeWidth = 6;
    
    // Gövde çizgisi
    canvas.drawLine(
      Offset(center.dx, center.dy + 70),
      Offset(center.dx, center.dy - 80),
      bodyPaint,
    );
    
    // Ok başı - üçgen (daha büyük ve belirgin)
    final arrowPaint = Paint()
      ..color = Colors.red.shade700
      ..style = PaintingStyle.fill;
    
    final arrowPath = Path();
    arrowPath.moveTo(center.dx, center.dy - 110);  // Üst nokta (daha uzun)
    arrowPath.lineTo(center.dx - 18, center.dy - 80);  // Sol alt
    arrowPath.lineTo(center.dx + 18, center.dy - 80);  // Sağ alt
    arrowPath.close();
    
    canvas.drawPath(arrowPath, arrowPaint);
    
    // Kabe ikonu - okun en ucunda
    _drawKaabaIcon(canvas, center);
    
    // Ok gövdesinin alt kısmı - beyaz çizgi
    final bottomPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    
    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(center.dx, center.dy + 70),
      bottomPaint,
    );
    
    // Merkez nokta
    final centerDotPaint = Paint()
      ..color = Colors.red.shade700
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 6, centerDotPaint);
  }
  
  /// Kabe ikonu çizimi - okun ucunda
  void _drawKaabaIcon(Canvas canvas, Offset center) {
    final kaabaPosition = Offset(center.dx, center.dy - 120);
    
    // Kabe ana yapısı (siyah küp) - daha büyük
    final kaabaPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    
    final kaabaRect = Rect.fromCenter(
      center: kaabaPosition,
      width: 24, // Artırıldı
      height: 24, // Artırıldı
    );
    
    canvas.drawRect(kaabaRect, kaabaPaint);
    
    // Altın kapı ve süsleme - daha kalın çizgiler
    final goldPaint = Paint()
      ..color = Colors.amber.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3; // Artırıldı
    
    // Kabe etrafına altın çerçeve
    canvas.drawRect(kaabaRect, goldPaint);
    
    // Kapı detayı (altın dikey çizgi)
    canvas.drawLine(
      Offset(kaabaPosition.dx, kaabaPosition.dy - 10),
      Offset(kaabaPosition.dx, kaabaPosition.dy + 10),
      goldPaint,
    );
    
    // Üst süsleme (yatay altın çizgi)
    canvas.drawLine(
      Offset(kaabaPosition.dx - 10, kaabaPosition.dy - 6),
      Offset(kaabaPosition.dx + 10, kaabaPosition.dy - 6),
      goldPaint,
    );
    
    // Alt süsleme (yatay altın çizgi)
    canvas.drawLine(
      Offset(kaabaPosition.dx - 8, kaabaPosition.dy + 4),
      Offset(kaabaPosition.dx + 8, kaabaPosition.dy + 4),
      goldPaint,
    );
    
    // Kabe örtüsü detayları (köşelerde büyük altın noktalar)
    final dotPaint = Paint()
      ..color = Colors.amber.shade500
      ..style = PaintingStyle.fill;
    
    // Köşe süslemeleri - daha büyük
    canvas.drawCircle(Offset(kaabaPosition.dx - 8, kaabaPosition.dy - 8), 2.5, dotPaint);
    canvas.drawCircle(Offset(kaabaPosition.dx + 8, kaabaPosition.dy - 8), 2.5, dotPaint);
    canvas.drawCircle(Offset(kaabaPosition.dx - 8, kaabaPosition.dy + 8), 2.5, dotPaint);
    canvas.drawCircle(Offset(kaabaPosition.dx + 8, kaabaPosition.dy + 8), 2.5, dotPaint);
    
    // Kabe'nin etrafında daha belirgin ışık efekti
    final glowPaint = Paint()
      ..color = Colors.amber.shade200.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(kaabaPosition, 18, glowPaint);
    
    // İç ışık efekti
    final innerGlowPaint = Paint()
      ..color = Colors.yellow.shade100.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(kaabaPosition, 12, innerGlowPaint);
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
