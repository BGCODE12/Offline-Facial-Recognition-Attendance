import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Translates points and bounding boxes from camera sensor coordinate space
/// to the Flutter widget canvas coordinate space with high precision.
class CoordinatesTranslator {
  /// Translates an X coordinate from camera sensor space to canvas space.
  static double translateX(
    double x,
    Size canvasSize,
    Size imageSize,
    InputImageRotation rotation,
    CameraLensDirection cameraLensDirection,
  ) {
    if (imageSize.width == 0 || imageSize.height == 0) return x;

    final double effectiveSensorWidth;
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        // In 90/270 deg rotation, sensor dimensions are transposed
        effectiveSensorWidth = imageSize.width > imageSize.height
            ? imageSize.height
            : imageSize.width;
        break;
      case InputImageRotation.rotation0deg:
      case InputImageRotation.rotation180deg:
        effectiveSensorWidth = imageSize.width;
        break;
    }

    final double scaleX =
        canvasSize.width / (effectiveSensorWidth == 0 ? 1.0 : effectiveSensorWidth);
    final double mappedX = x * scaleX;

    if (cameraLensDirection == CameraLensDirection.front) {
      // Mirror horizontally for front-facing camera so user movement is intuitive
      return canvasSize.width - mappedX;
    }
    return mappedX;
  }

  /// Translates a Y coordinate from camera sensor space to canvas space.
  static double translateY(
    double y,
    Size canvasSize,
    Size imageSize,
    InputImageRotation rotation,
    CameraLensDirection cameraLensDirection,
  ) {
    if (imageSize.width == 0 || imageSize.height == 0) return y;

    final double effectiveSensorHeight;
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        // In 90/270 deg rotation, sensor dimensions are transposed
        effectiveSensorHeight = imageSize.width > imageSize.height
            ? imageSize.width
            : imageSize.height;
        break;
      case InputImageRotation.rotation0deg:
      case InputImageRotation.rotation180deg:
        effectiveSensorHeight = imageSize.height;
        break;
    }

    final double scaleY =
        canvasSize.height / (effectiveSensorHeight == 0 ? 1.0 : effectiveSensorHeight);
    return y * scaleY;
  }

  /// Translates a ML Kit [Rect] bounding box to a scaled and mirrored [Rect] on the canvas.
  static Rect translateRect({
    required Rect boundingBox,
    required Size canvasSize,
    required Size imageSize,
    required InputImageRotation rotation,
    required CameraLensDirection cameraLensDirection,
  }) {
    final left = translateX(
      boundingBox.left,
      canvasSize,
      imageSize,
      rotation,
      cameraLensDirection,
    );
    final top = translateY(
      boundingBox.top,
      canvasSize,
      imageSize,
      rotation,
      cameraLensDirection,
    );
    final right = translateX(
      boundingBox.right,
      canvasSize,
      imageSize,
      rotation,
      cameraLensDirection,
    );
    final bottom = translateY(
      boundingBox.bottom,
      canvasSize,
      imageSize,
      rotation,
      cameraLensDirection,
    );

    // Ensure left < right and top < bottom after mirroring
    return Rect.fromLTRB(
      left < right ? left : right,
      top < bottom ? top : bottom,
      left < right ? right : left,
      top < bottom ? bottom : top,
    );
  }
}
