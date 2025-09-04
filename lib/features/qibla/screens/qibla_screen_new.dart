import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';

/// Kıble pusulası ekranı
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({Key? key}) : super(key: key);

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> with SingleTickerProviderStateMixin {
  // Kabe koordinatları
  static const double kaabaLatitude = 21.4225;
  static const double kaabaLongitude = 39.8262;
  
  // Durum değişkenleri
  bool _isLoading = true;
  bool _hasLocationPermission = false;
  double? _qiblaDirection;
  String _statusMessage = 'Konum bilgisi alınıyor...';
  Position? _currentPosition;
  
  // Animasyon kontrolcüsü (ok animasyonları için)
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    
    // Animasyon kontrolcüsünü ayarla
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    // Kıble bulucuyu başlat
    _initializeQiblaFinder();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Kıble bulucuyu başlat: izinleri kontrol et ve konumu al
  Future<void> _initializeQiblaFinder() async {
    try {
      // 1. Konum servisi açık mı kontrol et
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Konum servisini açma seçeneği göster
        bool? openLocationService = await _showLocationServiceDialog();
        
        if (openLocationService == true) {
          await Geolocator.openLocationSettings();
          // Ayarların açılmasını bekleyelim
          await Future.delayed(const Duration(seconds: 2));
          serviceEnabled = await Geolocator.isLocationServiceEnabled();
        }
        
        if (!serviceEnabled) {
          setState(() {
            _statusMessage = 'Kıble yönü için konum servislerini açmanız gerekiyor.';
            _isLoading = false;
          });
          return;
        }
      }

      // 2. Konum iznini kontrol et
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        // İzin istemeden önce açıklama diyalogu göster
        bool? shouldRequest = await _showPermissionExplanationDialog();
        
        if (shouldRequest == true) {
          permission = await Geolocator.requestPermission();
          
          if (permission == LocationPermission.denied) {
            setState(() {
              _statusMessage = 'Kıble yönünü gösterebilmek için konum izni gerekli.';
              _isLoading = false;
            });
            return;
          }
        } else {
          setState(() {
            _statusMessage = 'Konum izni olmadan kıble yönü hesaplanamaz.';
            _isLoading = false;
          });
          return;
        }
      }

      // 3. İzin kalıcı olarak reddedilmiş mi kontrol et
      if (permission == LocationPermission.deniedForever) {
        // Uygulama ayarlarına gitme seçeneği göster
        bool? openSettings = await _showAppSettingsDialog();
        
        if (openSettings == true) {
          await Geolocator.openAppSettings();
        }
        
        setState(() {
          _statusMessage = 'Ayarlardan konum iznini etkinleştirin.';
          _isLoading = false;
        });
        return;
      }

      // 4. Son bilinen konum var mı kontrol et (hızlı sonuç için)
      try {
        Position? lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          // Geçici olarak son konum ile kıble yönü hesapla
          double tempQiblaDirection = _calculateQiblaDirection(lastPosition);
          setState(() {
            _currentPosition = lastPosition;
            _qiblaDirection = tempQiblaDirection;
          });
        }
      } catch (e) {
        print('Son konum kontrolünde hata: $e');
      }

      // 5. Güncel konum al
      setState(() {
        _statusMessage = 'Konum hesaplanıyor...';
      });
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 8),
      );

      // 6. Kıble yönünü hesapla
      double qiblaDirection = _calculateQiblaDirection(position);

      // 7. UI'yi güncelle
      setState(() {
        _currentPosition = position;
        _qiblaDirection = qiblaDirection;
        _hasLocationPermission = true;
        _isLoading = false;
        _statusMessage = 'Kıble yönü bulundu';
      });
      
      // Başarılı konumu kutlamak için animasyonu başlat
      _animationController.forward();

    } catch (e) {
      setState(() {
        _statusMessage = 'Hata oluştu: Konum alınamadı.';
        _isLoading = false;
      });
      print('Hata: $e');
    }
  }
  
  /// Kıble yönünü hesapla
  double _calculateQiblaDirection(Position position) {
    return Geolocator.bearingBetween(
      position.latitude,
      position.longitude,
      kaabaLatitude,
      kaabaLongitude,
    );
  }
  
  /// Kabe'ye olan mesafeyi hesapla (km)
  double _calculateDistanceToKaaba(Position position) {
    return Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      kaabaLatitude,
      kaabaLongitude,
    ) / 1000; // metre -> km çevir
  }
  
  /// Konum servisi diyalogu
  Future<bool?> _showLocationServiceDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Konum Servisi Gerekli',
          style: GoogleFonts.ebGaramond(
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade800,
          ),
        ),
        content: Text(
          'Kıble yönünü hesaplamak için konum servisini açmanız gerekmektedir.',
          style: GoogleFonts.ebGaramond(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'İptal',
              style: GoogleFonts.ebGaramond(color: Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
            ),
            child: Text(
              'Ayarları Aç',
              style: GoogleFonts.ebGaramond(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
  
  /// İzin açıklama diyalogu
  Future<bool?> _showPermissionExplanationDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Kıble Yönü İçin İzin',
          style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Kıble yönünü doğru hesaplayabilmek için konum bilginize ihtiyaç var. Bu bilgi sadece kıble yönünü bulmak için kullanılır ve paylaşılmaz.',
              style: GoogleFonts.ebGaramond(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'İzin penceresinde "İzin Ver" seçeneğini işaretleyin.',
                      style: GoogleFonts.ebGaramond(
                        fontSize: 14,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'İptal',
              style: GoogleFonts.ebGaramond(color: Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
            ),
            child: Text(
              'İzin Ver',
              style: GoogleFonts.ebGaramond(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Uygulama ayarları diyalogu
  Future<bool?> _showAppSettingsDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Konum İzni Gerekli',
          style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Kıble yönünü göstermek için uygulama ayarlarından konum iznini etkinleştirin.',
          style: GoogleFonts.ebGaramond(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'İptal',
              style: GoogleFonts.ebGaramond(color: Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
            ),
            child: Text(
              'Ayarları Aç',
              style: GoogleFonts.ebGaramond(color: Colors.white),
            ),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                // Başlık
                _buildHeader(),
                
                const SizedBox(height: 20),
                
                // Ana içerik
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState()
                      : _hasLocationPermission
                          ? _buildCompassView()
                          : _buildPermissionDeniedState(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Başlık bölümü
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade600, Colors.teal.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade300.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.explore, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kıble Pusulası',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Mekke-i Mükerreme Yönü',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          if (!_isLoading)
            IconButton(
              onPressed: _refreshLocation,
              icon: const Icon(
                Icons.refresh,
                color: Colors.white,
                size: 24,
              ),
            ),
        ],
      ),
    );
  }

  /// Yükleme durumu
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade600),
          ),
          const SizedBox(height: 16),
          Text(
            _statusMessage,
            style: GoogleFonts.ebGaramond(
              fontSize: 16,
              color: Colors.teal.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// İzin reddedildi durumu
  Widget _buildPermissionDeniedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 48,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Konum İzni Gerekli',
            style: GoogleFonts.ebGaramond(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Text(
              _statusMessage,
              style: GoogleFonts.ebGaramond(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _refreshLocation,
                icon: const Icon(Icons.refresh),
                label: Text(
                  'Tekrar Dene',
                  style: GoogleFonts.ebGaramond(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  await Geolocator.openAppSettings();
                },
                icon: const Icon(Icons.settings),
                label: Text(
                  'Ayarları Aç',
                  style: GoogleFonts.ebGaramond(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
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
              'Pusula sensörü kullanılamıyor.',
              style: GoogleFonts.ebGaramond(
                fontSize: 16,
                color: Colors.red.shade700,
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        double? direction = snapshot.data!.heading;
        
        // Cihazın pusula sensörü devre dışıysa
        if (direction == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.compass_calibration,
                  size: 48,
                  color: Colors.amber,
                ),
                const SizedBox(height: 16),
                Text(
                  'Pusula kalibre edilemiyor',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Cihazınızı sekiz hareketi çizerek kalibre edin',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Statik pusula göster
                _buildStaticCompass(),
              ],
            ),
          );
        }

        // Pusula başarılı şekilde çalışıyorsa
        return _buildActiveCompass(direction);
      },
    );
  }
  
  /// Statik pusula (sensör çalışmadığında)
  Widget _buildStaticCompass() {
    return Column(
      children: [
        _buildCompassWithArrow(0),
        const SizedBox(height: 16),
        _buildInfoPanel(0),
      ],
    );
  }
  
  /// Aktif pusula (sensörle çalışan)
  Widget _buildActiveCompass(double direction) {
    // Kıble açısını hesapla
    double qiblaAngle = (_qiblaDirection! - direction) * (pi / 180);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCompassWithArrow(direction),
        const SizedBox(height: 16),
        _buildInfoPanel(direction),
      ],
    );
  }
  
  /// Oklu pusula bileşeni
  Widget _buildCompassWithArrow(double direction) {
    // Kıble açısını hesapla
    double qiblaAngle = 0;
    if (_qiblaDirection != null) {
      qiblaAngle = (_qiblaDirection! - direction) * (pi / 180);
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade200.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pusula kadranı
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade50,
                border: Border.all(
                  color: Colors.teal.shade200,
                  width: 1,
                ),
              ),
              child: CustomPaint(
                painter: SimpleCompassPainter(),
                size: const Size(220, 220),
              ),
            ),
            
            // Kıble yönü oku
            Transform.rotate(
              angle: qiblaAngle,
              child: _buildQiblaArrow(),
            ),
            
            // Orta nokta
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.teal.shade700,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Kıble oku
  Widget _buildQiblaArrow() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -0.1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      )),
      child: Container(
        width: 200,
        height: 200,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Kabe ikonu
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.mosque,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(height: 2),
            // Ok başlığı
            ClipPath(
              clipper: ArrowHeadClipper(),
              child: Container(
                width: 20,
                height: 20,
                color: Colors.green.shade600,
              ),
            ),
            // Ok gövdesi
            Container(
              width: 4,
              height: 85,
              color: Colors.green.shade600,
            ),
          ],
        ),
      ),
    );
  }
  
  /// Bilgi paneli
  Widget _buildInfoPanel(double heading) {
    // Konum yoksa boş dön
    if (_currentPosition == null) {
      return const SizedBox.shrink();
    }
    
    double qiblaAngle = _qiblaDirection ?? 0;
    if (qiblaAngle < 0) qiblaAngle += 360;
    
    // Kabe'ye olan mesafe
    double distanceToKaaba = _calculateDistanceToKaaba(_currentPosition!);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade100.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Column(
        children: [
          // Pusula ve kıble bilgisi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem('Pusula', '${heading.toInt()}°', Icons.explore),
              _buildInfoItem('Kıble', '${qiblaAngle.toInt()}°', Icons.navigation),
            ],
          ),
          
          const Divider(height: 24),
          
          // Kabe mesafesi
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mosque,
                color: Colors.green.shade700,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Kabe\'ye Mesafe: ',
                style: GoogleFonts.ebGaramond(
                  fontSize: 16,
                  color: Colors.green.shade800,
                ),
              ),
              Text(
                '${distanceToKaaba.toInt()} km',
                style: GoogleFonts.ebGaramond(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Konum bilgisi
          Text(
            'Konum: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
            style: GoogleFonts.ebGaramond(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// Bilgi öğesi
  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.teal.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.ebGaramond(
                fontSize: 14,
                color: Colors.teal.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.ebGaramond(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade800,
          ),
        ),
      ],
    );
  }
}

/// Basit pusula çizici
class SimpleCompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Ana yön çizgileri çiz (K, D, G, B)
    final Paint directionLinePaint = Paint()
      ..color = Colors.teal.shade700
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i < 360; i += 90) {
      final double angle = i * pi / 180;
      final Offset start = Offset(
        center.dx + (radius - 70) * cos(angle),
        center.dy + (radius - 70) * sin(angle),
      );
      final Offset end = Offset(
        center.dx + (radius - 20) * cos(angle),
        center.dy + (radius - 20) * sin(angle),
      );
      canvas.drawLine(start, end, directionLinePaint);
    }
    
    // Ara yön çizgileri çiz (KD, GD, GB, KB)
    final Paint subDirectionLinePaint = Paint()
      ..color = Colors.teal.shade400
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i < 360; i += 45) {
      if (i % 90 != 0) { // Ana yönleri atla
        final double angle = i * pi / 180;
        final Offset start = Offset(
          center.dx + (radius - 50) * cos(angle),
          center.dy + (radius - 50) * sin(angle),
        );
        final Offset end = Offset(
          center.dx + (radius - 20) * cos(angle),
          center.dy + (radius - 20) * sin(angle),
        );
        canvas.drawLine(start, end, subDirectionLinePaint);
      }
    }
    
    // Yön etiketlerini çiz
    _drawDirectionText(canvas, center, radius, 'K', 0);
    _drawDirectionText(canvas, center, radius, 'D', 90);
    _drawDirectionText(canvas, center, radius, 'G', 180);
    _drawDirectionText(canvas, center, radius, 'B', 270);
    
    // İç çember çiz
    final Paint innerCirclePaint = Paint()
      ..color = Colors.teal.shade200
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 70, innerCirclePaint);
  }
  
  void _drawDirectionText(Canvas canvas, Offset center, double radius, String text, double angleDegrees) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: text == 'K' ? Colors.red.shade700 : Colors.teal.shade700,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    
    final double angle = angleDegrees * pi / 180;
    final double x = center.dx + (radius - 15) * cos(angle) - (textPainter.width / 2);
    final double y = center.dy + (radius - 15) * sin(angle) - (textPainter.height / 2);
    
    textPainter.paint(canvas, Offset(x, y));
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Ok başlığı için kesici
class ArrowHeadClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }
  
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
