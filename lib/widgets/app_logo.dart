import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? primaryColor;
  final Color? accentColor;

  const AppLogo({
    super.key,
    this.size = 120,
    this.showText = true,
    this.primaryColor,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? const Color(0xFF003B5C);
    final accent = accentColor ?? const Color(0xFF4A90E2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo Icon
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primary, accent],
            ),
            borderRadius: BorderRadius.circular(size * 0.2),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Quote marks background
              Positioned(
                top: size * 0.15,
                left: size * 0.15,
                child: Icon(
                  Icons.format_quote,
                  size: size * 0.25,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              Positioned(
                bottom: size * 0.15,
                right: size * 0.15,
                child: Transform.rotate(
                  angle: 3.14159, // 180 degrees
                  child: Icon(
                    Icons.format_quote,
                    size: size * 0.25,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
              // Main quote icon
              Icon(
                Icons.auto_stories_outlined,
                size: size * 0.4,
                color: Colors.white,
              ),
            ],
          ),
        ),
        
        if (showText) ...[
          SizedBox(height: size * 0.15),
          Text(
            'Quotable By Amna',
            style: TextStyle(
              fontSize: size * 0.2,
              fontWeight: FontWeight.bold,
              color: primary,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            'Inspire Your Day',
            style: TextStyle(
              fontSize: size * 0.1,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}
