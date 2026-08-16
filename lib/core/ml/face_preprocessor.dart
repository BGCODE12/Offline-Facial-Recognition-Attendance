import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Structured data payload passed into background isolate.
class _PreprocessPayload {
  final List<Uint8List> planeBuffers;
  final List<int> planeRowStrides;
  final List<int> planePixelStrides;
  final int width;
  final int height;
  final ImageFormatGroup formatGroup;
  final int sensorOrientation;
  final bool isFrontCamera;
  final double cropLeft;
  final double cropTop;
  final double cropWidth;
  final double cropHeight;

  _PreprocessPayload({
    required this.planeBuffers,
    required this.planeRowStrides,
    required this.planePixelStrides,
    required this.width,
    required this.height,
    required this.formatGroup,
    required this.sensorOrientation,
    required this.isFrontCamera,
    required this.cropLeft,
    required this.cropTop,
    required this.cropWidth,
    required this.cropHeight,
  });
}

/// Result returned from background isolate containing normalized tensor and preview bytes.
class FacePreprocessResult {
  /// 4D tensor formatted as [1, 112, 112, 3] with values normalized in range [-1.0, 1.0].
  final List<List<List<List<double>>>> tensorInput;

  /// High-resolution cropped face image bytes (JPEG) for UI preview.
  final Uint8List previewJpgBytes;

  FacePreprocessResult({
    required this.tensorInput,
    required this.previewJpgBytes,
  });
}

/// Isolate-backed image pre-processing engine for MobileFaceNet.
///
/// Converts [CameraImage] streams (YUV420 / NV21 / BGRA) to RGB, crops to face bounds with padding,
/// aligns rotation, resizes to 112x112, and normalizes pixel intensities to [-1, 1].
class FacePreprocessor {
  static const int targetInputSize = 112; // MobileFaceNet standard input dimension

  /// Processes a [CameraImage] frame and cropped [Rect] in a background isolate.
  static Future<FacePreprocessResult?> processFaceImage({
    required CameraImage cameraImage,
    required Rect boundingBox,
    required CameraDescription cameraDescription,
  }) async {
    // Deep-copy plane byte buffers immediately before passing to compute()
    final copiedBuffers = cameraImage.planes
        .map((p) => Uint8List.fromList(p.bytes))
        .toList();

    final payload = _PreprocessPayload(
      planeBuffers: copiedBuffers,
      planeRowStrides: cameraImage.planes.map((p) => p.bytesPerRow).toList(),
      planePixelStrides:
          cameraImage.planes.map((p) => p.bytesPerPixel ?? 1).toList(),
      width: cameraImage.width,
      height: cameraImage.height,
      formatGroup: cameraImage.format.group,
      sensorOrientation: cameraDescription.sensorOrientation,
      isFrontCamera:
          cameraDescription.lensDirection == CameraLensDirection.front,
      cropLeft: boundingBox.left,
      cropTop: boundingBox.top,
      cropWidth: boundingBox.width,
      cropHeight: boundingBox.height,
    );

    return await compute(_isolateConvertAndCrop, payload);
  }

  /// Top-level isolate execution function.
  static FacePreprocessResult? _isolateConvertAndCrop(_PreprocessPayload payload) {
    try {
      // 1. Decode raw stream frame to RGB image (handles 1, 2, or 3 plane YUV/NV21/BGRA)
      img.Image rgbImage;

      if (payload.formatGroup == ImageFormatGroup.bgra8888) {
        rgbImage = _convertBGRA8888ToImage(payload);
      } else {
        // Universal YUV420 / NV21 converter
        rgbImage = _convertYUV420OrNV21ToImage(payload);
      }

      // 2. Adjust orientation to match portrait upright coordinate system
      if (payload.sensorOrientation != 0) {
        rgbImage = img.copyRotate(rgbImage, angle: payload.sensorOrientation);
      }

      // 3. Crop face directly using ML Kit bounding box + 12% padding for full facial structure
      final paddingX = payload.cropWidth * 0.12;
      final paddingY = payload.cropHeight * 0.12;

      int cropX = (payload.cropLeft - paddingX).toInt();
      int cropY = (payload.cropTop - paddingY).toInt();
      int cropW = (payload.cropWidth + paddingX * 2).toInt();
      int cropH = (payload.cropHeight + paddingY * 2).toInt();

      // Ensure valid boundary clamp within image dimensions
      cropX = cropX.clamp(0, rgbImage.width - 1);
      cropY = cropY.clamp(0, rgbImage.height - 1);
      cropW = cropW.clamp(1, rgbImage.width - cropX);
      cropH = cropH.clamp(1, rgbImage.height - cropY);

      img.Image croppedFace = img.copyCrop(
        rgbImage,
        x: cropX,
        y: cropY,
        width: cropW,
        height: cropH,
      );

      // 4. Front camera mirror alignment applied directly to the cropped face
      if (payload.isFrontCamera) {
        croppedFace = img.copyFlip(croppedFace, direction: img.FlipDirection.horizontal);
      }

      // 5. Resize strictly to 112x112 for MobileFaceNet
      final resizedFace = img.copyResize(
        croppedFace,
        width: targetInputSize,
        height: targetInputSize,
        interpolation: img.Interpolation.linear,
      );

      // 5. Normalize pixel values to [-1.0, 1.0]: (v - 127.5) / 127.5
      // Format 4D tensor: [1, 112, 112, 3]
      final List<List<List<double>>> imageMatrix = List.generate(
        targetInputSize,
        (y) => List.generate(
          targetInputSize,
          (x) {
            final pixel = resizedFace.getPixel(x, y);
            final r = (pixel.r - 127.5) / 127.5;
            final g = (pixel.g - 127.5) / 127.5;
            final b = (pixel.b - 127.5) / 127.5;
            return [r, g, b];
          },
        ),
      );

      final tensorInput = [imageMatrix]; // Shape: [1, 112, 112, 3]

      // 6. Encode preview image bytes (JPEG, 92% quality)
      final previewBytes =
          Uint8List.fromList(img.encodeJpg(resizedFace, quality: 92));

      return FacePreprocessResult(
        tensorInput: tensorInput,
        previewJpgBytes: previewBytes,
      );
    } catch (e) {
      debugPrint('Error in isolate face pre-processing: $e');
      return null;
    }
  }

  /// Robust conversion supporting 1-plane, 2-plane (NV21), and 3-plane (YUV420) buffers.
  static img.Image _convertYUV420OrNV21ToImage(_PreprocessPayload payload) {
    final width = payload.width;
    final height = payload.height;
    final planes = payload.planeBuffers;

    final image = img.Image(width: width, height: height);

    if (planes.isEmpty) return image;

    final yBuffer = planes[0];
    final yRowStride =
        payload.planeRowStrides.isNotEmpty ? payload.planeRowStrides[0] : width;

    // Case A: 3 Planes (Standard YUV420 / YUV_420_888)
    if (planes.length >= 3) {
      final uBuffer = planes[1];
      final vBuffer = planes[2];
      final uvRowStride = payload.planeRowStrides.length > 1
          ? payload.planeRowStrides[1]
          : (width ~/ 2);
      final uvPixelStride = payload.planePixelStrides.length > 1
          ? payload.planePixelStrides[1]
          : 1;

      for (int y = 0; y < height; y++) {
        final int yOffset = y * yRowStride;
        final int uvYOffset = (y ~/ 2) * uvRowStride;

        for (int x = 0; x < width; x++) {
          final int yIndex = yOffset + x;
          final int uvIndex = uvYOffset + (x ~/ 2) * uvPixelStride;

          if (yIndex >= yBuffer.length) continue;
          final int yp = yBuffer[yIndex];
          final int up = (uvIndex < uBuffer.length) ? uBuffer[uvIndex] : 128;
          final int vp = (uvIndex < vBuffer.length) ? vBuffer[uvIndex] : 128;

          int r = (yp + 1.402 * (vp - 128)).round().clamp(0, 255);
          int g = (yp - 0.344136 * (up - 128) - 0.714136 * (vp - 128))
              .round()
              .clamp(0, 255);
          int b = (yp + 1.772 * (up - 128)).round().clamp(0, 255);

          image.setPixelRgb(x, y, r, g, b);
        }
      }
      return image;
    }

    // Case B: 2 Planes (Semi-planar NV21: Plane 0 is Y, Plane 1 is VU interleaved)
    if (planes.length == 2) {
      final vuBuffer = planes[1];
      final vuRowStride = payload.planeRowStrides.length > 1
          ? payload.planeRowStrides[1]
          : width;
      final vuPixelStride = payload.planePixelStrides.length > 1
          ? payload.planePixelStrides[1]
          : 2;

      for (int y = 0; y < height; y++) {
        final int yOffset = y * yRowStride;
        final int uvYOffset = (y ~/ 2) * vuRowStride;

        for (int x = 0; x < width; x++) {
          final int yIndex = yOffset + x;
          final int uvIndex = uvYOffset + (x ~/ 2) * vuPixelStride;

          if (yIndex >= yBuffer.length) continue;
          final int yp = yBuffer[yIndex];
          final int vp = (uvIndex < vuBuffer.length) ? vuBuffer[uvIndex] : 128;
          final int up =
              (uvIndex + 1 < vuBuffer.length) ? vuBuffer[uvIndex + 1] : 128;

          int r = (yp + 1.402 * (vp - 128)).round().clamp(0, 255);
          int g = (yp - 0.344136 * (up - 128) - 0.714136 * (vp - 128))
              .round()
              .clamp(0, 255);
          int b = (yp + 1.772 * (up - 128)).round().clamp(0, 255);

          image.setPixelRgb(x, y, r, g, b);
        }
      }
      return image;
    }

    // Case C: 1 Plane (Contiguous NV21 buffer)
    if (planes.length == 1) {
      final buffer = planes[0];
      final int uvStart = width * height;

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int yIndex = y * width + x;
          final int uvIndex = uvStart + (y ~/ 2) * width + (x & ~1);

          if (yIndex >= buffer.length) continue;
          final int yp = buffer[yIndex];
          final int vp = (uvIndex < buffer.length) ? buffer[uvIndex] : 128;
          final int up =
              (uvIndex + 1 < buffer.length) ? buffer[uvIndex + 1] : 128;

          int r = (yp + 1.402 * (vp - 128)).round().clamp(0, 255);
          int g = (yp - 0.344136 * (up - 128) - 0.714136 * (vp - 128))
              .round()
              .clamp(0, 255);
          int b = (yp + 1.772 * (up - 128)).round().clamp(0, 255);

          image.setPixelRgb(x, y, r, g, b);
        }
      }
      return image;
    }

    return image;
  }

  /// Converts BGRA8888 plane buffer (iOS standard) to [img.Image].
  static img.Image _convertBGRA8888ToImage(_PreprocessPayload payload) {
    final width = payload.width;
    final height = payload.height;
    final buffer = payload.planeBuffers[0];

    return img.Image.fromBytes(
      width: width,
      height: height,
      bytes: buffer.buffer,
      order: img.ChannelOrder.bgra,
    );
  }
}
