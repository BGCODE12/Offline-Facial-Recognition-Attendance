import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ml/face_recognition_service.dart';

/// Provider for singleton instance of [FaceRecognitionService].
///
/// The interpreter is pre-warmed once in `main.dart` before `runApp()`.
/// This provider simply exposes the existing singleton for `predict()` and
/// `cosineSimilarity()` calls on the main isolate. It does NOT call `initialize()`.
final faceRecognitionServiceProvider = Provider<FaceRecognitionService>((ref) {
  return FaceRecognitionService();
});
