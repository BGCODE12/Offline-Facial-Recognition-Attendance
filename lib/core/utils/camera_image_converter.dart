import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Utility class to convert a live [CameraImage] stream frame
/// into a Google ML Kit [InputImage] format.
class CameraImageConverter {
  /// Converts a [CameraImage] frame into an [InputImage].
  ///
  /// Calculates the appropriate [InputImageRotation], stitches image planes,
  /// and attaches [InputImageMetadata] with platform-safe format detection.
  static InputImage? inputImageFromCameraImage({
    required CameraImage image,
    required CameraDescription camera,
    required DeviceOrientation deviceOrientation,
  }) {
    // 1. Calculate rotation
    final rotation = _getImageRotation(
      sensorOrientation: camera.sensorOrientation,
      lensDirection: camera.lensDirection,
      deviceOrientation: deviceOrientation,
    );

    if (rotation == null) return null;

    // 2. Resolve image format: dynamically determine from raw format or platform default
    final format = InputImageFormatValue.fromRawValue(image.format.raw) ??
        (Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888);

    // 3. Staging and concatenating plane bytes
    final allBytes = _concatenatePlanes(image.planes);

    // 4. Construct input image metadata
    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(
      bytes: allBytes,
      metadata: metadata,
    );
  }

  /// Concatenates bytes from all planes into a single [Uint8List].
  static Uint8List _concatenatePlanes(List<Plane> planes) {
    if (planes.length == 1) {
      return planes.first.bytes;
    }
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  /// Calculates the ML Kit [InputImageRotation] from sensor orientation and device orientation.
  static InputImageRotation? _getImageRotation({
    required int sensorOrientation,
    required CameraLensDirection lensDirection,
    required DeviceOrientation deviceOrientation,
  }) {
    final orientations = {
      DeviceOrientation.portraitUp: 0,
      DeviceOrientation.landscapeLeft: 90,
      DeviceOrientation.portraitDown: 180,
      DeviceOrientation.landscapeRight: 270,
    };

    final deviceAngle = orientations[deviceOrientation] ?? 0;
    int rotationCompensation;

    if (lensDirection == CameraLensDirection.front) {
      // Front camera compensation formula
      rotationCompensation = (sensorOrientation + deviceAngle) % 360;
    } else {
      // Back camera compensation formula
      rotationCompensation = (sensorOrientation - deviceAngle + 360) % 360;
    }

    return InputImageRotationValue.fromRawValue(rotationCompensation);
  }
}
