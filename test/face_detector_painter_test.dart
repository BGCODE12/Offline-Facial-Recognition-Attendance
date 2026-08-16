import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:face_attendance_kiosk/presentation/components/face_detector_painter.dart';

void main() {
  testWidgets('FaceDetectorPainter draws face bounding box on canvas',
      (WidgetTester tester) async {
    // Create a mock face object for testing CustomPainter
    final testFace = Face(
      boundingBox: const Rect.fromLTWH(50, 50, 200, 200),
      landmarks: {},
      contours: {},
      trackingId: 42,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomPaint(
            size: const Size(400, 800),
            painter: FaceDetectorPainter(
              faces: [testFace],
              absoluteImageSize: const Size(720, 1280),
              rotation: InputImageRotation.rotation90deg,
              cameraLensDirection: CameraLensDirection.front,
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
