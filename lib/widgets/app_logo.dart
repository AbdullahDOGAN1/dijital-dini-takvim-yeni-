import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool withAnimation;
  
  const AppLogo({
    super.key,
    this.size = 120,
    this.withAnimation = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget logo = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.asset(
          'assets/images/nurvakti_logo.jpg',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to custom designed logo if image fails
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFF2d4a3e),
                    Color(0xFF1a2e23),
                  ],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Moon Crescent
                  Positioned(
                    left: size * 0.15,
                    child: Container(
                      width: size * 0.4,
                      height: size * 0.53,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFf4d03f),
                            Color(0xFFd4ac0d),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(size * 0.2),
                          bottomLeft: Radius.circular(size * 0.2),
                          topRight: Radius.circular(size * 0.05),
                          bottomRight: Radius.circular(size * 0.05),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Book
                  Container(
                    width: size * 0.47,
                    height: size * 0.31,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFf7dc6f),
                          Color(0xFFf1c40f),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(size * 0.03),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Book spine
                        Positioned(
                          left: size * 0.23,
                          child: Container(
                            width: size * 0.008,
                            height: size * 0.31,
                            decoration: BoxDecoration(
                              color: Color(0xFFd4ac0d),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                        
                        // Book pages
                        Positioned(
                          left: size * 0.02,
                          top: size * 0.02,
                          child: Container(
                            width: size * 0.43,
                            height: size * 0.27,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(size * 0.015),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(size * 0.03),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Text lines
                                  for (int i = 0; i < 6; i++)
                                    Padding(
                                      padding: EdgeInsets.only(bottom: size * 0.01),
                                      child: Container(
                                        height: size * 0.008,
                                        width: size * (0.15 + (i % 3) * 0.02),
                                        decoration: BoxDecoration(
                                          color: Color(0xFF2c3e50).withOpacity(0.6),
                                          borderRadius: BorderRadius.circular(1),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Light rays around the book
                  ...List.generate(8, (index) {
                    final angle = (index * 45.0) * (3.14159 / 180);
                    return Positioned(
                      top: size * 0.25 + (size * 0.15) * (1 - 0.8) * (1 + 0.3 * (index % 2)),
                      left: size * 0.5 - size * 0.004,
                      child: Transform.rotate(
                        angle: angle,
                        child: Container(
                          width: size * 0.008,
                          height: size * (0.08 + 0.02 * (index % 2)),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFf4d03f).withOpacity(0.8),
                                Color(0xFFf4d03f).withOpacity(0.0),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(size * 0.004),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );

    if (withAnimation) {
      return TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 1000),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Opacity(
              opacity: value,
              child: logo,
            ),
          );
        },
      );
    }

    return logo;
  }
}
