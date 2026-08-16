import 'dart:ui';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Evaluates the temporal stability of detected face bounding boxes across consecutive frames.
///
/// Prevents motion blur, flickering, and partial angle captures by ensuring a face
/// is centered and stationary for at least [requiredStableFrames] before running inference.
class FaceStabilityTracker {
  final int requiredStableFrames;
  final double maxCenterDrift;
  final double maxSizeDelta;

  Rect? _lastBox;
  int _consecutiveStableFrames = 0;

  FaceStabilityTracker({
    this.requiredStableFrames = 4,
    this.maxCenterDrift = 55.0,
    this.maxSizeDelta = 60.0,
  });

  /// Current progress towards stability target (0.0 to 1.0).
  double get stabilityProgress =>
      (_consecutiveStableFrames / requiredStableFrames).clamp(0.0, 1.0);

  /// Number of currently accumulated stable frames.
  int get stableFrameCount => _consecutiveStableFrames;

  /// Returns `true` once the target number of stable frames has been achieved.
  bool get isStable => _consecutiveStableFrames >= requiredStableFrames;

  /// Ingests a new [Face] bounding box and updates stability state.
  ///
  /// Returns `true` if the face is currently considered fully stable.
  bool update(Face? face) {
    if (face == null) {
      reset();
      return false;
    }

    final currentBox = face.boundingBox;

    if (_lastBox == null) {
      _lastBox = currentBox;
      _consecutiveStableFrames = 1;
      return false;
    }

    final lastCenter = _lastBox!.center;
    final currentCenter = currentBox.center;

    final centerDistance = (currentCenter - lastCenter).distance;
    final widthDelta = (currentBox.width - _lastBox!.width).abs();
    final heightDelta = (currentBox.height - _lastBox!.height).abs();

    if (centerDistance <= maxCenterDrift &&
        widthDelta <= maxSizeDelta &&
        heightDelta <= maxSizeDelta) {
      _consecutiveStableFrames++;
    } else {
      // Gentle penalty on minor movement, reset only on large jump
      if (centerDistance > maxCenterDrift * 2.5) {
        _consecutiveStableFrames = 1;
      } else {
        _consecutiveStableFrames =
            (_consecutiveStableFrames - 1).clamp(0, requiredStableFrames);
      }
    }

    _lastBox = currentBox;
    return isStable;
  }

  /// Resets the tracker when the face is lost or after successful capture.
  void reset() {
    _lastBox = null;
    _consecutiveStableFrames = 0;
  }
}
