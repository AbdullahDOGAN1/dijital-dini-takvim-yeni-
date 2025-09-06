import 'package:flutter/material.dart';

/// A reusable widget that provides the styled page container with paper texture
class PageContentWidget extends StatelessWidget {
  final Widget child;

  const PageContentWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Paper-like background color as fallback
        color: const Color(0xFFF5F5DC), // Beige/cream color
        // Uncomment when paper_texture.jpg is available
        // image: const DecorationImage(
        //   image: AssetImage('assets/images/paper_texture.jpg'),
        //   fit: BoxFit.cover,
        // ),

        // Rounded corners for a book page effect with modern radius
        borderRadius: BorderRadius.circular(16),

        // Enhanced shadows for depth
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],

        // Enhanced border for definition
        border: Border.all(color: Colors.brown.withOpacity(0.25), width: 1.5),
      ),
      child: Padding(padding: const EdgeInsets.all(16.0), child: child),
    );
  }
}
