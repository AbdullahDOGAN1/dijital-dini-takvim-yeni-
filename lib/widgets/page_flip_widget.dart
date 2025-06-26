import 'package:flutter/material.dart';
import 'dart:math';

/// Sağ alt köşeden tutup çevirme animasyonu için ana widget.
/// Bezier eğrisi, CustomPainter, gölge ve arka yüz içerir.
class PageFlipWidget extends StatefulWidget {
  final Widget front;
  final Widget back;
  final void Function()? onFlipComplete;

  const PageFlipWidget({
    Key? key,
    required this.front,
    required this.back,
    this.onFlipComplete,
  }) : super(key: key);

  @override
  State<PageFlipWidget> createState() => _PageFlipWidgetState();
}

class _PageFlipWidgetState extends State<PageFlipWidget>
    with SingleTickerProviderStateMixin {
  // Animasyon ve gesture state değişkenleri burada olacak
  late AnimationController _controller;
  Offset? _dragStart;
  Offset? _dragCurrent;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _dragStart = details.localPosition;
      _dragCurrent = details.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragCurrent = details.localPosition;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    // Animasyonu başlat
    _controller.forward(from: 0).then((_) {
      widget.onFlipComplete?.call();
      setState(() {
        _dragStart = null;
        _dragCurrent = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Stack(
        children: [
          widget.back,
          // Sayfa flip efekti burada çizilecek
          if (_dragStart != null && _dragCurrent != null)
            CustomPaint(
              painter: PageFlipPainter(
                dragStart: _dragStart!,
                dragCurrent: _dragCurrent!,
                progress: _controller.value,
              ),
              child: widget.front,
            )
          else
            widget.front,
        ],
      ),
    );
  }
}

/// Sayfa flip efektini çizen CustomPainter (Bezier, gölge, arka yüz)
class PageFlipPainter extends CustomPainter {
  final Offset dragStart;
  final Offset dragCurrent;
  final double progress;

  PageFlipPainter({
    required this.dragStart,
    required this.dragCurrent,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Sağ alt köşe referans noktası
    final bottomRight = Offset(size.width, size.height);
    // Drag noktası ile bottomRight arasındaki vektör
    final drag = Offset.lerp(bottomRight, dragCurrent, progress)!;

    // Sayfa kıvrımının kontrol noktası (Bezier için)
    final control = Offset(
      (bottomRight.dx + drag.dx) / 2,
      (bottomRight.dy + drag.dy) / 2 - 0.2 * size.height * (1 - progress),
    );

    // Sayfa ön yüzü (kıvrılmamış kısım)
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(drag.dx, drag.dy)
      ..quadraticBezierTo(control.dx, control.dy, 0, size.height)
      ..close();

    // Sayfa arka yüzü (kıvrılan kısım)
    final backPath = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(drag.dx, drag.dy)
      ..quadraticBezierTo(control.dx, control.dy, size.width, 0)
      ..close();

    // Ön yüzü çiz
    canvas.save();
    canvas.clipPath(path);
    canvas.drawColor(Colors.white, BlendMode.src);
    canvas.restore();

    // Arka yüzü çiz (hafif gri ve gradient ile)
    canvas.save();
    canvas.clipPath(backPath);
    final backGradient = LinearGradient(
      begin: Alignment.bottomRight,
      end: Alignment.topLeft,
      colors: [Colors.grey.shade200, Colors.grey.shade400],
    );
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, Paint()..shader = backGradient.createShader(rect));
    canvas.restore();

    // Gölge efekti (kıvrım kenarında)
    final shadowPath = Path()
      ..moveTo(drag.dx, drag.dy)
      ..quadraticBezierTo(control.dx, control.dy, size.width, 0);
    canvas.drawShadow(shadowPath, Colors.black.withOpacity(0.3), 16, false);
  }

  @override
  bool shouldRepaint(covariant PageFlipPainter oldDelegate) {
    return dragStart != oldDelegate.dragStart ||
        dragCurrent != oldDelegate.dragCurrent ||
        progress != oldDelegate.progress;
  }
}
