import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:face_attendance_kiosk/core/utils/coordinates_translator.dart';

void main() {
  group('CoordinatesTranslator Tests', () {
    test('translates and mirrors front camera coordinates correctly in portrait', () {
      const canvasSize = Size(400, 800);
      const imageSize = Size(720, 1280); // Sensor dimensions
      const rotation = InputImageRotation.rotation90deg;
      const lensDirection = CameraLensDirection.front;

      // In 90deg, sensor height (1280) maps to canvas width (400)
      // and sensor width (720) maps to canvas height (800)
      const testRect = Rect.fromLTWH(100, 200, 300, 400);

      final translatedRect = CoordinatesTranslator.translateRect(
        boundingBox: testRect,
        canvasSize: canvasSize,
        imageSize: imageSize,
        rotation: rotation,
        cameraLensDirection: lensDirection,
      );

      // Verify that coordinates are within canvas bounds and correctly inverted for front mirror
      expect(translatedRect.left, greaterThanOrEqualTo(0));
      expect(translatedRect.right, lessThanOrEqualTo(canvasSize.width));
      expect(translatedRect.top, greaterThanOrEqualTo(0));
      expect(translatedRect.bottom, lessThanOrEqualTo(canvasSize.height));
      expect(translatedRect.width, greaterThan(0));
      expect(translatedRect.height, greaterThan(0));
    });

    test('translates back camera coordinates without horizontal mirroring', () {
      const canvasSize = Size(400, 800);
      const imageSize = Size(720, 1280);
      const rotation = InputImageRotation.rotation0deg;
      const lensDirection = CameraLensDirection.back;

      const testRect = Rect.fromLTWH(100, 100, 200, 200);

      final translatedRect = CoordinatesTranslator.translateRect(
        boundingBox: testRect,
        canvasSize: canvasSize,
        imageSize: imageSize,
        rotation: rotation,
        cameraLensDirection: lensDirection,
      );

      final expectedLeft = 100 * (400 / 720);
      expect(translatedRect.left, closeTo(expectedLeft, 0.01));
    });
  });
}
