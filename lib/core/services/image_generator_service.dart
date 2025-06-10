import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';
import '../../../models/quote_model.dart';

class ImageGeneratorService {
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), we need different permissions
      if (await Permission.photos.request().isGranted) {
        return true;
      }
      // Fallback for older Android versions
      return await Permission.storage.request().isGranted;
    } else if (Platform.isIOS) {
      return await Permission.photos.request().isGranted;
    }
    return false;
  }

  static Future<bool> downloadQuoteImage(QuoteModel quote, BuildContext context) async {
    try {
      // Request permission
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        _showMessage(context, 'Storage permission denied');
        return false;
      }

      // Generate image
      final imageBytes = await _generateQuoteImage(quote);
      if (imageBytes == null) {
        _showMessage(context, 'Failed to generate image');
        return false;
      }

      // Save to temporary file first
      final tempDir = await getTemporaryDirectory();
      final fileName = 'quote_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);

      // Save to gallery using Gal package
      await Gal.putImage(file.path, album: 'Quoteable');
      
      // Clean up temporary file
      await file.delete();

      _showMessage(context, 'Quote saved to gallery!');
      return true;
    } catch (e) {
      print('Error downloading quote image: $e');
      _showMessage(context, 'Error: ${e.toString()}');
      return false;
    }
  }

  static Future<Uint8List?> _generateQuoteImage(QuoteModel quote) async {
    try {
      // Create a custom painter for the quote
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(800, 600);

      // Background gradient
      final backgroundPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF003B5C),
            Color(0xFF1E5F7A),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

      // Add decorative elements
      final decorPaint = Paint()
        ..color = Colors.white.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      // Draw decorative border
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(40, 40, size.width - 80, size.height - 80),
          const Radius.circular(20),
        ),
        decorPaint,
      );

      // Quote marks decoration
      final quotePaint = Paint()..color = Colors.white.withOpacity(0.2);
      _drawQuoteMark(canvas, const Offset(80, 120), quotePaint, 40);
      _drawQuoteMark(canvas, Offset(size.width - 120, size.height - 160), quotePaint, 40, isClosing: true);

      // Quote text
      final quoteTextPainter = TextPainter(
        text: TextSpan(
          text: quote.text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w400,
            height: 1.5,
            letterSpacing: 0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      quoteTextPainter.layout(maxWidth: size.width - 140);
      
      final quoteY = (size.height - quoteTextPainter.height - 80) / 2;
      quoteTextPainter.paint(
        canvas,
        Offset((size.width - quoteTextPainter.width) / 2, quoteY),
      );

      // Author text
      final authorTextPainter = TextPainter(
        text: TextSpan(
          text: '— ${quote.author}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.3,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      authorTextPainter.layout(maxWidth: size.width - 120);
      authorTextPainter.paint(
        canvas,
        Offset(
          (size.width - authorTextPainter.width) / 2,
          quoteY + quoteTextPainter.height + 40,
        ),
      );

      // App branding
      final brandTextPainter = TextPainter(
        text: const TextSpan(
          text: 'Quoteable App',
          style: TextStyle(
            color: Colors.white30,
            fontSize: 12,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      brandTextPainter.layout();
      brandTextPainter.paint(
        canvas,
        Offset(
          (size.width - brandTextPainter.width) / 2,
          size.height - 50,
        ),
      );

      // Convert to image
      final picture = recorder.endRecording();
      final img = await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error generating quote image: $e');
      return null;
    }
  }

  static void _drawQuoteMark(Canvas canvas, Offset position, Paint paint, double size, {bool isClosing = false}) {
    final path = Path();
    
    if (isClosing) {
      // Closing quote mark (")
      path.moveTo(position.dx, position.dy);
      path.quadraticBezierTo(
        position.dx + size * 0.3, position.dy - size * 0.2,
        position.dx + size * 0.5, position.dy,
      );
      path.quadraticBezierTo(
        position.dx + size * 0.3, position.dy + size * 0.2,
        position.dx, position.dy + size * 0.4,
      );
      
      path.moveTo(position.dx + size * 0.3, position.dy);
      path.quadraticBezierTo(
        position.dx + size * 0.6, position.dy - size * 0.2,
        position.dx + size * 0.8, position.dy,
      );
      path.quadraticBezierTo(
        position.dx + size * 0.6, position.dy + size * 0.2,
        position.dx + size * 0.3, position.dy + size * 0.4,
      );
    } else {
      // Opening quote mark (")
      path.moveTo(position.dx + size * 0.8, position.dy);
      path.quadraticBezierTo(
        position.dx + size * 0.5, position.dy - size * 0.2,
        position.dx + size * 0.3, position.dy,
      );
      path.quadraticBezierTo(
        position.dx + size * 0.5, position.dy + size * 0.2,
        position.dx + size * 0.8, position.dy + size * 0.4,
      );
      
      path.moveTo(position.dx + size * 0.5, position.dy);
      path.quadraticBezierTo(
        position.dx + size * 0.2, position.dy - size * 0.2,
        position.dx, position.dy,
      );
      path.quadraticBezierTo(
        position.dx + size * 0.2, position.dy + size * 0.2,
        position.dx + size * 0.5, position.dy + size * 0.4,
      );
    }
    
    canvas.drawPath(path, paint);
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
