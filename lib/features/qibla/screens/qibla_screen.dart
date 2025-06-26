import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  // Kaaba coordinates (Mecca, Saudi Arabia)
  static const double kaabaLatitude = 21.4225;
  static const double kaabaLongitude = 39.8262;
  
  // State variables
  bool _isLoading = true;
  bool _hasLocationPermission = false;
  double? _qiblaDirection;
  String _statusMessage = 'Konum bilgisi alınıyor...';
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initializeQiblaFinder();
  }

  /// Initialize the Qibla finder by checking permissions and getting location
  Future<void> _initializeQiblaFinder() async {
    try {
      // Check location service
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _statusMessage = 'Konum servisi kapalı. Lütfen açınız.';
          _isLoading = false;
        });
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _statusMessage = 'Konum izni reddedildi. Ayarlardan izin veriniz.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _statusMessage = 'Konum izni kalıcı olarak reddedildi. Ayarlardan izin veriniz.';
          _isLoading = false;
        });
        return;
      }

      // Get current position
      setState(() {
        _statusMessage = 'Konum hesaplanıyor...';
      });

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Calculate Qibla direction
      double qiblaDirection = Geolocator.bearingBetween(
        position.latitude,
        position.longitude,
        kaabaLatitude,
        kaabaLongitude,
      );

      setState(() {
        _currentPosition = position;
        _qiblaDirection = qiblaDirection;
        _hasLocationPermission = true;
        _isLoading = false;
        _statusMessage = 'Kıble yönü hesaplandı';
      });

    } catch (e) {
      setState(() {
        _statusMessage = 'Hata: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// Open app settings
  Future<void> _openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Refresh location and recalculate Qibla
  Future<void> _refreshLocation() async {
    setState(() {
      _isLoading = true;
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
              Colors.cyan.shade50,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Header
                _buildHeader(),
                
                const SizedBox(height: 24),
                
                // Main content
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState()
                      : _hasLocationPermission
                          ? _buildCompassView()
                          : _buildPermissionDeniedState(),
                ),
                
                // Location info
                if (_currentPosition != null) _buildLocationInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build header with title and refresh button
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade600, Colors.teal.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade300.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.explore,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kıble Pusulası',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 24,
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
              icon: Icon(
                Icons.refresh,
                color: Colors.white,
                size: 28,
              ),
            ),
        ],
      ),
    );
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.shade200.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade600),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 20),
                Text(
                  _statusMessage,
                  style: GoogleFonts.ebGaramond(
                    fontSize: 16,
                    color: Colors.teal.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build permission denied state
  Widget _buildPermissionDeniedState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.red.shade200.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              'Konum İzni Gerekli',
              style: GoogleFonts.ebGaramond(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _statusMessage,
              style: GoogleFonts.ebGaramond(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _openAppSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Ayarları Aç',
                style: GoogleFonts.ebGaramond(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build compass view with real-time direction
  Widget _buildCompassView() {
    if (_qiblaDirection == null) {
      return Center(
        child: Text(
          'Kıble yönü hesaplanamadı',
          style: GoogleFonts.ebGaramond(fontSize: 16),
        ),
      );
    }

    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  'Pusula hatası',
                  style: GoogleFonts.ebGaramond(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Emülatörde pusula çalışmayabilir',
                  style: GoogleFonts.ebGaramond(fontSize: 14, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildStaticCompass(), // Show static compass as fallback
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade600),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pusula hazırlanıyor...',
                  style: GoogleFonts.ebGaramond(fontSize: 16),
                ),
              ],
            ),
          );
        }

        double? heading = snapshot.data!.heading;
        if (heading == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.compass_calibration, size: 64, color: Colors.orange.shade400),
                const SizedBox(height: 16),
                Text(
                  'Pusula kalibre edilemiyor',
                  style: GoogleFonts.ebGaramond(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Fiziksel cihazda daha iyi çalışır',
                  style: GoogleFonts.ebGaramond(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                _buildStaticCompass(), // Show static compass as fallback
              ],
            ),
          );
        }

        return _buildCompass(heading);
      },
    );
  }

  /// Build static compass as fallback for emulator
  Widget _buildStaticCompass() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Compass container
        Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.teal.shade300.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Compass background
              _buildCompassBackground(),
              
              // Static Qibla arrow pointing to calculated direction
              Transform.rotate(
                angle: (_qiblaDirection! * pi / 180), // Convert to radians
                child: _buildQiblaArrow(),
              ),
              
              // Center dot
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.teal.shade700,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Direction info
        _buildDirectionInfo(0), // Static info for emulator
      ],
    );
  }

  /// Build location information
  Widget _buildLocationInfo() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: Colors.teal.shade600,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Konum: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
              style: GoogleFonts.ebGaramond(
                fontSize: 12,
                color: Colors.teal.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the actual compass widget
  Widget _buildCompass(double heading) {
    // Calculate the angle to rotate the needle
    // The needle should point to Qibla direction relative to current heading
    double qiblaAngle = (_qiblaDirection! - heading) * (pi / 180);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Compass container
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.shade300.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Compass background
                _buildCompassBackground(),
                
                // Qibla needle
                Transform.rotate(
                  angle: qiblaAngle,
                  child: _buildQiblaArrow(),
                ),
                
                // Center dot
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.teal.shade700,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Direction info
          _buildDirectionInfo(heading),
        ],
      ),
    );
  }

  /// Build compass background with directions
  Widget _buildCompassBackground() {
    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.teal.shade50,
            Colors.teal.shade100,
            Colors.teal.shade200,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Cardinal directions
          _buildDirectionMarker('N', 0),
          _buildDirectionMarker('E', 90),
          _buildDirectionMarker('S', 180),
          _buildDirectionMarker('W', 270),
          
          // Degree markings
          ..._buildDegreeMarkings(),
        ],
      ),
    );
  }

  /// Build direction marker (N, S, E, W)
  Widget _buildDirectionMarker(String direction, double angle) {
    return Transform.rotate(
      angle: angle * (pi / 180),
      child: Container(
        width: 260,
        height: 260,
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: direction == 'N' ? Colors.red.shade600 : Colors.teal.shade700,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              direction,
              style: GoogleFonts.ebGaramond(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build degree markings around the compass
  List<Widget> _buildDegreeMarkings() {
    List<Widget> markings = [];
    for (int i = 0; i < 360; i += 30) {
      markings.add(
        Transform.rotate(
          angle: i * (pi / 180),
          child: Container(
            width: 260,
            height: 260,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 26),
                width: 2,
                height: 12,
                color: Colors.teal.shade600,
              ),
            ),
          ),
        ),
      );
    }
    return markings;
  }

  /// Build Qibla arrow
  Widget _buildQiblaArrow() {
    return Container(
      width: 4,
      height: 100,
      child: Column(
        children: [
          // Arrow head
          Container(
            width: 0,
            height: 0,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(width: 8, color: Colors.transparent),
                right: BorderSide(width: 8, color: Colors.transparent),
                bottom: BorderSide(width: 16, color: Colors.green.shade600),
              ),
            ),
          ),
          // Arrow body
          Container(
            width: 4,
            height: 70,
            color: Colors.green.shade600,
          ),
          // Arrow tail
          Container(
            width: 12,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  /// Build direction information
  Widget _buildDirectionInfo(double heading) {
    double qiblaDirection = _qiblaDirection!;
    if (qiblaDirection < 0) qiblaDirection += 360;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade200.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem('Pusula', '${heading.toInt()}°'),
              _buildInfoItem('Kıble', '${qiblaDirection.toInt()}°'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.place,
                  color: Colors.green.shade600,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Yeşil ok Kıble yönünü gösterir',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 14,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build info item (direction, degrees)
  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.ebGaramond(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.ebGaramond(
            fontSize: 20,
            color: Colors.teal.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
