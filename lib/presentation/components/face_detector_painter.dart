import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../core/utils/coordinates_translator.dart';

/// CustomPainter rendering real-time face bounding boxes, corner brackets,
/// and detection indicators on top of the live camera stream.
class FaceDetectorPainter extends CustomPainter {
  final List<Face> faces;
  final Size absoluteImageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;

  FaceDetectorPainter({
    required this.faces,
    required this.absoluteImageSize,
    required this.rotation,
    required this.cameraLensDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (faces.isEmpty || absoluteImageSize.width == 0 || absoluteImageSize.height == 0) {
      return;
    }

    final boxPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFF00E676).withValues(alpha: 0.7); // Bright Emerald Green

    final cornerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF00E676);

    final bgTintPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF00E676).withValues(alpha: 0.08);

    for (final face in faces) {
      // 1. Translate sensor bounding box to screen canvas coordinates
      final rect = CoordinatesTranslator.translateRect(
        boundingBox: face.boundingBox,
        canvasSize: size,
        imageSize: absoluteImageSize,
        rotation: rotation,
        cameraLensDirection: cameraLensDirection,
      );

      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

      // 2. Draw subtle translucent fill
      canvas.drawRRect(rrect, bgTintPaint);

      // 3. Draw bounding border
      canvas.drawRRect(rrect, boxPaint);

      // 4. Draw high-tech corner brackets scaled proportionally to face size
      final cornerLength =
          (rect.width * 0.2).clamp(12.0, 32.0);
      _drawCornerBrackets(canvas, rect, cornerPaint, cornerLength: cornerLength);

      // 5. Draw status badge
      _drawTrackingBadge(canvas, rect, face);
    }
  }

  /// Draws 4 corner brackets around the bounding box for a sleek kiosk UI.
  void _drawCornerBrackets(
    Canvas canvas,
    Rect rect,
    Paint paint, {
    required double cornerLength,
  }) {
    final path = Path();

    // Top-Left
    path.moveTo(rect.left, rect.top + cornerLength);
    path.lineTo(rect.left, rect.top);
    path.lineTo(rect.left + cornerLength, rect.top);

    // Top-Right
    path.moveTo(rect.right - cornerLength, rect.top);
    path.lineTo(rect.right, rect.top);
    path.lineTo(rect.right, rect.top + cornerLength);

    // Bottom-Right
    path.moveTo(rect.right, rect.bottom - cornerLength);
    path.lineTo(rect.right, rect.bottom);
    path.lineTo(rect.right - cornerLength, rect.bottom);

    // Bottom-Left
    path.moveTo(rect.left + cornerLength, rect.bottom);
    path.lineTo(rect.left, rect.bottom);
    path.lineTo(rect.left, rect.bottom - cornerLength);

    canvas.drawPath(path, paint);
  }

  /// Draws a small badge above the face indicating face detection status or tracking ID.
  void _drawTrackingBadge(Canvas canvas, Rect rect, Face face) {
    final textSpan = TextSpan(
      text: face.trackingId != null ? 'ID: #${face.trackingId}' : 'Face Detected',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final badgePadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
    final badgeWidth = textPainter.width + badgePadding.horizontal;
    final badgeHeight = textPainter.height + badgePadding.vertical;

    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        rect.left,
        rect.top - badgeHeight - 6 < 0 ? rect.top + 8 : rect.top - badgeHeight - 6,
        badgeWidth,
        badgeHeight,
      ),
      const Radius.circular(6),
    );

    final badgeBgPaint = Paint()..color = const Color(0xFF00C853);
    canvas.drawRRect(badgeRect, badgeBgPaint);

    textPainter.paint(
      canvas,
      Offset(
        badgeRect.left + badgePadding.left,
        badgeRect.top + badgePadding.top,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant FaceDetectorPainter oldDelegate) {
    return oldDelegate.faces != faces ||
        oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.rotation != rotation;
  }
}
