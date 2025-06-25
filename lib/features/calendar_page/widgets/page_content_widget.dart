import 'package:flutter/material.dart';

/// A reusable widget that provides the styled page container with paper texture
class PageContentWidget extends StatelessWidget {
  final Widget child;

  const PageContentWidget({
    Key? key,
    required this.child,
  }) : super(key: key);

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
        
        // Rounded corners for a book page effect
        borderRadius: BorderRadius.circular(10),
        
        // Subtle shadow for depth
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
        ],
        
        // Subtle border for definition
        border: Border.all(
          color: Colors.brown.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: child,
      ),
    );
  }
}
