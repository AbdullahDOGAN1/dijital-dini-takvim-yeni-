import 'package:flutter/material.dart';
import 'dart:math';

/// Sol üstten geri çevirme veya aşağıdan yukarıya kaydırma için ana widget.
class BackPageFlipWidget extends StatefulWidget {
  final Widget front;
  final Widget back;
  final void Function()? onFlipBackComplete;

  const BackPageFlipWidget({
    Key? key,
    required this.front,
    required this.back,
    this.onFlipBackComplete,
  }) : super(key: key);

  @override
  State<BackPageFlipWidget> createState() => _BackPageFlipWidgetState();
}

class _BackPageFlipWidgetState extends State<BackPageFlipWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

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

  void startFlipBack() {
    _controller.forward(from: 0).then((_) => widget.onFlipBackComplete?.call());
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Sayfa geri çevirme animasyonu (sol üstten) beamer dönüşü
        final angle = _controller.value * pi;
        final isFront = angle <= pi / 2;
        // 3D perspektif ayarı
        final perspective = Matrix4.identity()..setEntry(3, 2, 0.001);
        return Stack(
          children: [
            // Arka yüz: animasyon ilerledikçe göster
            if (!isFront)
              Transform(
                transform: perspective..rotateY(angle - pi),
                alignment: Alignment.topLeft,
                origin: Offset(0, 0),
                child: widget.back,
              ),
            // Ön yüz: animasyonun ilk yarısında göster
            if (isFront)
              Transform(
                transform: perspective..rotateY(angle),
                alignment: Alignment.topLeft,
                origin: Offset(0, 0),
                child: widget.front,
              ),
          ],
        );
      },
    );
  }
}
