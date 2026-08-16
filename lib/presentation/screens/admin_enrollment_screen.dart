import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../core/ml/face_preprocessor.dart';
import '../../core/ml/face_stability_tracker.dart';
import '../../data/models/employee.dart';
import '../components/live_camera_view.dart';
import '../providers/employee_controller.dart';
import '../providers/face_recognition_provider.dart';

/// Admin Screen for enrolling new employees into the facial recognition database.
///
/// Features real-time face tracking with stability evaluation, background isolate
/// image cropping/normalization, MobileFaceNet embedding generation, and Isar DB persistence.
class AdminEnrollmentScreen extends ConsumerStatefulWidget {
  const AdminEnrollmentScreen({super.key});

  @override
  ConsumerState<AdminEnrollmentScreen> createState() =>
      _AdminEnrollmentScreenState();
}

class _AdminEnrollmentScreenState extends ConsumerState<AdminEnrollmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  // Very relaxed stability tracker for enrollment (throttled to ~8fps means
  // larger inter-frame movement, so we need wider tolerances)
  final FaceStabilityTracker _stabilityTracker = FaceStabilityTracker(
    requiredStableFrames: 3,
    maxCenterDrift: 80.0,
    maxSizeDelta: 80.0,
  );

  bool _isEnrolling = false;
  bool _isProcessingEmbedding = false;
  double _stabilityProgress = 0.0;
  String _statusMessage = 'Position face in the center of the frame';

  Uint8List? _capturedFacePreview;
  List<double>? _extractedEmbedding;

  // Store a snapshot of the latest detected face for manual capture fallback.
  Face? _lastDetectedFace;
  CameraImage? _lastSnapshotImage;
  CameraDescription? _lastCameraDescription;
  bool _hasLiveSnapshot = false;

  @override
  void initState() {
    super.initState();
    // Listen to name field changes to dynamically enable/disable Save button
    _nameController.addListener(_onFormFieldChanged);
    _codeController.addListener(_onFormFieldChanged);
  }

  void _onFormFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFormFieldChanged);
    _codeController.removeListener(_onFormFieldChanged);
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  /// Handles incoming face frame from [LiveCameraView].
  void _onFaceDetected(Face dominantFace, CameraImage rawCameraImage, CameraDescription camera) async {
    // Store latest face + camera description for manual capture fallback
    _lastDetectedFace = dominantFace;
    _lastSnapshotImage = rawCameraImage;
    _lastCameraDescription = camera;
    if (!_hasLiveSnapshot && mounted) {
      setState(() => _hasLiveSnapshot = true);
    }

    // If already locked in with a captured face, ignore further stream frames
    if (_extractedEmbedding != null || _isProcessingEmbedding || _isEnrolling) {
      return;
    }

    final isStable = _stabilityTracker.update(dominantFace);
    final progress = _stabilityTracker.stabilityProgress;

    // Debug Log
    debugPrint(
      '[AdminEnrollment] Face detected '
      'size=${dominantFace.boundingBox.width.toInt()}x${dominantFace.boundingBox.height.toInt()} '
      '| stableCount=${_stabilityTracker.stableFrameCount}/3 '
      '| progress=${(progress * 100).toInt()}% '
      '| isStable=$isStable '
      '| sensorOrientation=${camera.sensorOrientation}',
    );

    setState(() {
      _stabilityProgress = progress;
      if (isStable) {
        _statusMessage = 'Face stable! Extracting biometric embeddings...';
      } else if (_stabilityTracker.stableFrameCount >= 2) {
        _statusMessage =
            'Hold still... Capturing geometry (${(progress * 100).toInt()}%)';
      } else {
        _statusMessage = 'Look straight into the camera to lock face';
      }
    });

    if (isStable && !_isProcessingEmbedding) {
      _isProcessingEmbedding = true;
      _stabilityTracker.reset();
      _processStableFace(dominantFace, rawCameraImage, camera);
    }
  }

  /// Manual capture fallback: force-capture using the CURRENT live frame.
  void _manualCaptureFace() {
    if (_lastDetectedFace == null || _lastSnapshotImage == null || _lastCameraDescription == null) return;
    if (_isProcessingEmbedding || _extractedEmbedding != null) return;

    debugPrint('[AdminEnrollment] Manual capture triggered by user.');
    _isProcessingEmbedding = true;
    _stabilityTracker.reset();
    setState(() {
      _statusMessage = 'Capturing face manually...';
    });
    _processStableFace(_lastDetectedFace!, _lastSnapshotImage!, _lastCameraDescription!);
  }

  /// Crops face in isolate, computes 112x112 normalized tensor, and runs TFLite inference.
  Future<void> _processStableFace(
      Face face, CameraImage rawCameraImage, CameraDescription cameraDescription) async {
    _isProcessingEmbedding = true;
    debugPrint('[AdminEnrollment] _processStableFace: sensorOrientation=${cameraDescription.sensorOrientation}');

    try {
      // 1. Isolate-based YUV->RGB conversion, cropping & 112x112 normalization
      final preprocessResult = await FacePreprocessor.processFaceImage(
        cameraImage: rawCameraImage,
        boundingBox: face.boundingBox,
        cameraDescription: cameraDescription,
      );

      if (preprocessResult == null || !mounted) {
        debugPrint('[AdminEnrollment] Preprocessing returned null or widget unmounted.');
        _stabilityTracker.reset();
        _isProcessingEmbedding = false;
        return;
      }

      debugPrint(
        '[AdminEnrollment] Preprocessed tensor: ${preprocessResult.tensorInput.length}x'
        '${preprocessResult.tensorInput[0].length}x'
        '${preprocessResult.tensorInput[0][0].length}x'
        '${preprocessResult.tensorInput[0][0][0].length}, previewBytes=${preprocessResult.previewJpgBytes.length}',
      );

      // 2. MobileFaceNet TFLite Inference
      final recognitionService = ref.read(faceRecognitionServiceProvider);
      final embedding = recognitionService.predict(preprocessResult.tensorInput);

      debugPrint(
        '[AdminEnrollment] TFLite extraction SUCCEEDED: ${embedding.length}-dimensional vector.',
      );

      if (!mounted) return;

      setState(() {
        _capturedFacePreview = preprocessResult.previewJpgBytes;
        _extractedEmbedding = embedding;
        _statusMessage =
            'Face captured successfully (${embedding.length}-dim vector ready)';
      });
    } catch (e, stack) {
      debugPrint('[AdminEnrollment] Error generating face embedding: $e\n$stack');
      if (mounted) {
        setState(() {
          _statusMessage = 'Failed to extract face embedding. Retrying...';
          _stabilityTracker.reset();
        });
      }
    } finally {
      _isProcessingEmbedding = false;
    }
  }

  /// Resets the current face capture so the user can re-align.
  void _retakeFace() {
    debugPrint('[AdminEnrollment] Retaking face capture...');
    setState(() {
      _capturedFacePreview = null;
      _extractedEmbedding = null;
      _stabilityProgress = 0.0;
      _statusMessage = 'Position face in the center of the frame';
      _stabilityTracker.reset();
    });
  }

  /// Persists the new employee with their biometric embeddings to Isar DB.
  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;
    if (_extractedEmbedding == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please allow the camera to scan a stable face first.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isEnrolling = true);

    try {
      final name = _nameController.text.trim();
      final code = _codeController.text.trim().isEmpty
          ? null
          : _codeController.text.trim();

      debugPrint(
        '[AdminEnrollment] Saving employee "$name" with code "$code" into Isar DB...',
      );

      final newEmployee = Employee(
        name: name,
        employeeCode: code,
        faceFeatures: _extractedEmbedding!,
        createdAt: DateTime.now(),
      );

      // Persist to Isar DB via Riverpod AsyncNotifier
      await ref.read(employeeControllerProvider.notifier).saveEmployee(newEmployee);

      debugPrint('[AdminEnrollment] Employee "$name" enrolled successfully in Isar DB.');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Employee "$name" enrolled successfully!'),
          backgroundColor: const Color(0xFF00E676),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop();
    } catch (e, stack) {
      debugPrint('[AdminEnrollment] Failed to save employee: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save employee: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isEnrolling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasCapturedFace = _extractedEmbedding != null;
    final bool hasEnteredName = _nameController.text.trim().isNotEmpty;
    final bool isSaveButtonEnabled =
        hasCapturedFace && hasEnteredName && !_isEnrolling;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        title: const Text(
          'Enroll New Employee',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Camera / Face Capture Card
                Container(
                  height: 320,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: hasCapturedFace
                          ? const Color(0xFF00E676)
                          : Colors.white.withValues(alpha: 0.1),
                      width: 2,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (!hasCapturedFace)
                        LiveCameraView(
                          initialDirection: CameraLensDirection.front,
                          performanceMode: FaceDetectorMode.accurate,
                          onFaceDetected: _onFaceDetected,
                        )
                      else if (_capturedFacePreview != null)
                        Image.memory(
                          _capturedFacePreview!,
                          fit: BoxFit.cover,
                        ),

                      // Stability Progress Bar Overlay
                      if (!hasCapturedFace && _stabilityProgress > 0)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(
                            value: _stabilityProgress,
                            minHeight: 6,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF00E676),
                            ),
                          ),
                        ),

                      // Manual Capture Button (fallback when auto-stability struggles)
                      if (!hasCapturedFace && !_isProcessingEmbedding && _hasLiveSnapshot)
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: ElevatedButton.icon(
                            onPressed: _manualCaptureFace,
                            icon: const Icon(Icons.camera_alt_rounded, size: 18),
                            label: const Text('Capture'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00B0FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),

                      // Locked Badge
                      if (hasCapturedFace)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, size: 16, color: Colors.black),
                                SizedBox(width: 6),
                                Text(
                                  'Face Biometrics Ready',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 2. Status & Guidance Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasCapturedFace
                            ? Icons.verified_user_rounded
                            : Icons.info_outline_rounded,
                        color: hasCapturedFace
                            ? const Color(0xFF00E676)
                            : const Color(0xFF00B0FF),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                            color: hasCapturedFace
                                ? const Color(0xFF00E676)
                                : Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (hasCapturedFace)
                        TextButton(
                          onPressed: _retakeFace,
                          child: const Text(
                            'Retake',
                            style: TextStyle(
                              color: Color(0xFF00E676),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Employee Profile Form Fields
                const Text(
                  'Employee Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'e.g. Sarah Connor',
                    prefixIcon: const Icon(Icons.person_outline, color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the employee full name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _codeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Employee Code / Badge ID (Optional)',
                    hintText: 'e.g. EMP-1042',
                    prefixIcon: const Icon(Icons.badge_outlined, color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 4. Dynamic Step Guide & Requirements Helper
                _buildRequirementsHelper(hasCapturedFace, hasEnteredName),

                const SizedBox(height: 16),

                // 5. Save / Enroll Button
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSaveButtonEnabled
                          ? const Color(0xFF00E676)
                          : const Color(0xFF334155),
                      foregroundColor: isSaveButtonEnabled
                          ? const Color(0xFF0F172A)
                          : Colors.white38,
                      disabledBackgroundColor: const Color(0xFF1E293B),
                      disabledForegroundColor: Colors.white24,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: isSaveButtonEnabled ? 4 : 0,
                    ),
                    onPressed: isSaveButtonEnabled ? _saveEmployee : null,
                    child: _isEnrolling
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isSaveButtonEnabled
                                    ? Icons.save_rounded
                                    : Icons.lock_outline_rounded,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isSaveButtonEnabled
                                    ? 'Save & Enroll Employee'
                                    : 'Complete Steps Above to Save',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Displays clear visual checklist of what is needed to enable the Save button.
  Widget _buildRequirementsHelper(bool hasCapturedFace, bool hasEnteredName) {
    if (_isProcessingEmbedding) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF00B0FF).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF00B0FF).withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00B0FF)),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Extracting 192-d MobileFaceNet vector...',
                style: TextStyle(color: Color(0xFF00B0FF), fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (!hasCapturedFace) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.camera_alt_outlined, color: Colors.amberAccent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Step 1: Look straight into the camera to capture face (${(_stabilityProgress * 100).toInt()}%)',
                style: const TextStyle(color: Colors.amberAccent, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (!hasEnteredName) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF00B0FF).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF00B0FF).withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: Color(0xFF00B0FF), size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Step 2: Enter employee full name to enable saving',
                style: TextStyle(color: Color(0xFF00B0FF), fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF00E676).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: Color(0xFF00E676), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'All requirements met! Tap below to enroll employee.',
              style: TextStyle(
                color: Color(0xFF00E676),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
