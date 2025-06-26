import 'package:flutter/material.dart';
import 'dart:math';

/// Üstten yırtılma animasyonu için ana widget.
/// Dalgalı path, fade-out ve particle effect içerir.
class TearEffectWidget extends StatefulWidget {
  final Widget child;
  final void Function()? onTearComplete;

  const TearEffectWidget({Key? key, required this.child, this.onTearComplete})
    : super(key: key);

  @override
  State<TearEffectWidget> createState() => _TearEffectWidgetState();
}

class _TearEffectWidgetState extends State<TearEffectWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    // Yırtma animasyonunu otomatik başlat
    _controller.forward(from: 0).then((_) => widget.onTearComplete?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: TearEffectPainter(progress: _controller.value),
          child: widget.child,
        );
      },
    );
  }
}

/// Dalgalı yırtılma path ve fade-out çizen CustomPainter
class TearEffectPainter extends CustomPainter {
  final double progress;
  TearEffectPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final waveAmplitude = 16.0;
    final waveFrequency = 2 * pi / size.width;
    // Yırtılma çizgisi Y konumu (0 -> alt kenar)
    final y = progress * size.height;

    // Dalgalı yırtılma path
    final tearPath = Path()
      ..moveTo(0, 0)
      ..lineTo(0, y);
    for (double x = 0; x <= size.width; x += 1) {
      final dy = sin(x * waveFrequency + progress * pi * 2) * waveAmplitude;
      tearPath.lineTo(x, y + dy);
    }
    tearPath.lineTo(size.width, 0);
    tearPath.close();

    // Altındaki yeni gün sayfasını görünür kılmak için tornan parça kaldırılıyor
    canvas.save();
    canvas.clipPath(tearPath);
    canvas.drawColor(Colors.transparent, BlendMode.clear);
    canvas.restore();

    // Üstten kopan parçanın yukarı doğru uçuşu ve fade-out
    final piecePath = Path.from(tearPath);
    canvas.save();
    // Yukarı taşıma efektini uyguluyoruz
    final offsetY = -progress * 0.5 * size.height;
    canvas.translate(0, offsetY);
    canvas.clipPath(piecePath);
    // Parçanın şeffaflığı progress arttıkça artıyor (1-progress ile fade)
    canvas.drawColor(Colors.white.withOpacity(1 - progress), BlendMode.srcOver);
    canvas.restore();

    // TODO: Küçük kağıt parçacıkları (particle effect) eklenecek
  }

  @override
  bool shouldRepaint(covariant TearEffectPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
