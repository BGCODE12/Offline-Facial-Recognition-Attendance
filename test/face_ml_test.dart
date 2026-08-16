import 'dart:math';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:face_attendance_kiosk/core/ml/face_recognition_service.dart';
import 'package:face_attendance_kiosk/core/ml/face_stability_tracker.dart';

void main() {
  group('FaceRecognitionService ML Tests', () {
    late FaceRecognitionService service;

    setUp(() {
      service = FaceRecognitionService();
    });

    test('L2 Normalization produces unit vectors with magnitude 1.0', () {
      final rawVector = [3.0, 4.0, 0.0];
      final normalized = service.l2Normalize(rawVector);

      expect(normalized[0], closeTo(0.6, 0.0001));
      expect(normalized[1], closeTo(0.8, 0.0001));
      expect(normalized[2], 0.0);

      // Verify magnitude sqrt(sum(x^2)) == 1.0
      final magnitude = sqrt(normalized.fold(0.0, (sum, val) => sum + val * val));
      expect(magnitude, closeTo(1.0, 0.0001));
    });

    test('Cosine similarity correctly identifies identical and orthogonal embeddings', () {
      final v1 = service.l2Normalize([1.0, 2.0, 3.0, 4.0]);
      final v2 = service.l2Normalize([1.0, 2.0, 3.0, 4.0]);
      final v3 = service.l2Normalize([-1.0, -2.0, -3.0, -4.0]);
      final v4 = service.l2Normalize([2.0, -1.0, 4.0, -3.0]); // dot product = 2 - 2 + 12 - 12 = 0

      // Identical vectors -> Cosine Similarity = 1.0
      expect(service.cosineSimilarity(v1, v2), closeTo(1.0, 0.0001));

      // Opposite vectors -> Cosine Similarity = -1.0
      expect(service.cosineSimilarity(v1, v3), closeTo(-1.0, 0.0001));

      // Orthogonal vectors -> Cosine Similarity = 0.0
      expect(service.cosineSimilarity(v1, v4), closeTo(0.0, 0.0001));
    });

    test('Euclidean distance is 0 for identical vectors', () {
      final v1 = [0.5, 0.5, 0.5, 0.5];
      final v2 = [0.5, 0.5, 0.5, 0.5];

      expect(service.euclideanDistance(v1, v2), closeTo(0.0, 0.0001));
    });

    test('Synthetic embedding produces 192-dimensional normalized vector', () {
      final dummyTensor = [
        List.generate(
          112,
          (_) => List.generate(
            112,
            (_) => [0.2, 0.4, 0.6],
          ),
        ),
      ];

      final embedding = service.predict(dummyTensor);
      expect(embedding.length, 192);

      final magnitude = sqrt(embedding.fold(0.0, (sum, val) => sum + val * val));
      expect(magnitude, closeTo(1.0, 0.0001));
    });
  });

  group('FaceStabilityTracker Tests', () {
    test('detects stability after consecutive static frames', () {
      final tracker = FaceStabilityTracker(
        requiredStableFrames: 5,
        maxCenterDrift: 15.0,
        maxSizeDelta: 15.0,
      );

      final staticFace = Face(
        boundingBox: const Rect.fromLTWH(100, 100, 150, 150),
        landmarks: {},
        contours: {},
      );

      expect(tracker.isStable, isFalse);
      expect(tracker.stabilityProgress, 0.0);

      // Frame 1
      tracker.update(staticFace);
      expect(tracker.stableFrameCount, 1);
      expect(tracker.isStable, isFalse);

      // Frames 2 to 4
      for (int i = 2; i <= 4; i++) {
        tracker.update(staticFace);
        expect(tracker.isStable, isFalse);
      }

      // Frame 5 -> Should become stable
      final becameStable = tracker.update(staticFace);
      expect(becameStable, isTrue);
      expect(tracker.isStable, isTrue);
      expect(tracker.stabilityProgress, 1.0);
    });

    test('penalizes and resets when face drifts significantly', () {
      final tracker = FaceStabilityTracker(
        requiredStableFrames: 5,
        maxCenterDrift: 10.0,
        maxSizeDelta: 10.0,
      );

      final face1 = Face(
        boundingBox: const Rect.fromLTWH(100, 100, 150, 150),
        landmarks: {},
        contours: {},
      );

      final jumpingFace = Face(
        boundingBox: const Rect.fromLTWH(300, 400, 150, 150), // Center distance > 200px
        landmarks: {},
        contours: {},
      );

      tracker.update(face1);
      tracker.update(face1);
      tracker.update(face1);
      expect(tracker.stableFrameCount, 3);

      // Drastic movement
      tracker.update(jumpingFace);
      expect(tracker.stableFrameCount, 1);
      expect(tracker.isStable, isFalse);

      // Reset
      tracker.reset();
      expect(tracker.stableFrameCount, 0);
    });
  });
}
