import 'package:flutter/material.dart';

/// Alttan yukarı sürükleyerek gün geçişi için ana widget.
/// Esneme efekti ve animasyon içerir.
class DragUpWidget extends StatefulWidget {
  final Widget child;
  final Widget nextChild; // Bir üst gün sayfası
  final void Function()? onDragUpComplete;

  const DragUpWidget({
    Key? key,
    required this.child,
    required this.nextChild,
    this.onDragUpComplete,
  }) : super(key: key);

  @override
  State<DragUpWidget> createState() => _DragUpWidgetState();
}

class _DragUpWidgetState extends State<DragUpWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.primaryDelta ?? 0;
      if (_dragOffset < 0) _dragOffset = 0;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    _controller.forward(from: 0).then((_) {
      widget.onDragUpComplete?.call();
      setState(() {
        _dragOffset = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final height = constraints.maxHeight;
      return GestureDetector(
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Sürükleme yüzdesi (0..1)
            final dragPercent = (_dragOffset / height).clamp(0.0, 1.0);
            // Yatay kayma: sürükleme anı ve animasyon tamamlanırken paketin yukarı çıkışı
            final translateY = -_dragOffset * (1 - _controller.value) - height * _controller.value;
            // Y ekseninde hafif esneme (sürükleme anında), animasyon ilerledikçe normale döner
            final scaleY = 1 + dragPercent * 0.2 * (1 - _controller.value);
            return Stack(
              children: [
                // Alt sayfa (yeni gün)
                widget.nextChild,
                // Mevcut sayfa
                Transform.translate(
                  offset: Offset(0, translateY),
                  child: Transform(
                    alignment: Alignment.bottomCenter,
                    transform: Matrix4.diagonal3Values(1, scaleY, 1),
                    child: child,
                  ),
                ),
              ],
            );
          },
          child: widget.child,
        ),
      );
    });
  }
}
