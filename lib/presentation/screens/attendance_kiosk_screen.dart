import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:intl/intl.dart';
import '../../core/ml/face_preprocessor.dart';
import '../../core/ml/face_stability_tracker.dart';
import '../../data/models/attendance_type.dart';
import '../components/live_camera_view.dart';
import '../components/verification_overlay_card.dart';
import '../controllers/live_matching_controller.dart';
import '../providers/attendance_providers.dart';
import '../providers/employee_controller.dart';
import '../providers/face_recognition_provider.dart';
import 'admin_enrollment_screen.dart';

/// Primary full-screen Kiosk terminal interface.
///
/// Runs continuous real-time face detection, temporal stability filtering,
/// 1:N MobileFaceNet matching, smart Check-In/Check-Out punching, and animated UI overlays.
class AttendanceKioskScreen extends ConsumerStatefulWidget {
  const AttendanceKioskScreen({super.key});

  @override
  ConsumerState<AttendanceKioskScreen> createState() =>
      _AttendanceKioskScreenState();
}

class _AttendanceKioskScreenState extends ConsumerState<AttendanceKioskScreen> {
  final FaceStabilityTracker _stabilityTracker = FaceStabilityTracker(
    requiredStableFrames: 3,
    maxCenterDrift: 65.0,
    maxSizeDelta: 75.0,
  );

  bool _isProcessingInference = false;
  bool _isFacePresent = false;
  int _detectedFaceCount = 0;
  double _stabilityProgress = 0.0;
  DateTime? _lastInferenceTimestamp;

  // Manage camera hardware handoff during navigation to prevent camera collisions
  bool _isNavigatingToAdmin = false;
  Key _cameraKey = UniqueKey();

  @override
  void initState() {
    super.initState();
  }

  /// Continuous frame handler triggered from [LiveCameraView].
  void _onFaceDetected(
    Face dominantFace,
    CameraImage rawCameraImage,
    CameraDescription camera,
  ) async {
    final matchingState = ref.read(liveMatchingControllerProvider);

    // If currently displaying a match card or running inference, bypass frame
    if (matchingState.lastVerifiedResult != null || _isProcessingInference) {
      return;
    }

    // Rate-limit inference attempts (at least 600ms between attempts)
    final now = DateTime.now();
    if (_lastInferenceTimestamp != null &&
        now.difference(_lastInferenceTimestamp!).inMilliseconds < 600) {
      return;
    }

    final isStable = _stabilityTracker.update(dominantFace);

    if (mounted) {
      setState(() {
        _stabilityProgress = _stabilityTracker.stabilityProgress;
      });
    }

    // Trigger 1:N matching once the face is stationary and centered
    if (isStable && !_isProcessingInference) {
      _isProcessingInference = true;
      _lastInferenceTimestamp = now;
      _stabilityTracker.reset(); // Reset counter immediately to avoid multi-fire
      _executeLiveMatching(dominantFace, rawCameraImage, camera);
    }
  }

  /// Extracts biometric embedding and queries the 1:N in-memory matching engine.
  Future<void> _executeLiveMatching(
    Face face,
    CameraImage rawCameraImage,
    CameraDescription cameraDescription,
  ) async {
    _isProcessingInference = true;

    try {
      // 1. Isolate Preprocessing: YUV->RGB, crop & 112x112 normalization
      final preprocessResult = await FacePreprocessor.processFaceImage(
        cameraImage: rawCameraImage,
        boundingBox: face.boundingBox,
        cameraDescription: cameraDescription,
      );

      if (preprocessResult == null || !mounted) {
        _stabilityTracker.reset();
        _isProcessingInference = false;
        return;
      }

      // 2. MobileFaceNet Embedding Extraction
      final recognitionService = ref.read(faceRecognitionServiceProvider);
      final probeEmbedding =
          recognitionService.predict(preprocessResult.tensorInput);

      // 3. 1:N Cosine Similarity Matching & DB Punch
      final matchingController =
          ref.read(liveMatchingControllerProvider.notifier);

      final matchResult = await matchingController.processProbeEmbedding(
        probeEmbedding: probeEmbedding,
        facePreview: preprocessResult.previewJpgBytes,
      );

      if (matchResult != null) {
        // Trigger audio/haptic feedback on success
        HapticFeedback.mediumImpact();
        SystemSound.play(SystemSoundType.click);
      }

      // Reset stability tracker for next cycle
      _stabilityTracker.reset();
    } catch (e) {
      debugPrint('Live matching pipeline error: $e');
      _stabilityTracker.reset();
    } finally {
      _isProcessingInference = false;
    }
  }

  /// Safely releases kiosk camera before navigating to AdminEnrollmentScreen,
  /// and mounts a fresh camera session with a new Key when returning.
  Future<void> _openAdminEnrollment() async {
    setState(() {
      _isNavigatingToAdmin = true;
      _isFacePresent = false;
      _detectedFaceCount = 0;
      _stabilityProgress = 0.0;
      _stabilityTracker.reset();
    });

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AdminEnrollmentScreen(),
      ),
    );

    if (mounted) {
      setState(() {
        _isNavigatingToAdmin = false;
        _cameraKey = UniqueKey(); // Creates and mounts a clean camera stream
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbInitState = ref.watch(databaseInitializerProvider);
    final matchingState = ref.watch(liveMatchingControllerProvider);
    final employeeListAsync = ref.watch(employeeControllerProvider);
    final employeeCount = employeeListAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: dbInitState.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
            ),
          ),
          error: (err, stack) => Center(
            child: Text(
              'Database Init Error: $err',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
          data: (_) => Stack(
            children: [
              // 1. Fullscreen Live Camera View with Real-time Face Detection
              Positioned.fill(
                child: !_isNavigatingToAdmin
                    ? LiveCameraView(
                        key: _cameraKey,
                        initialDirection: CameraLensDirection.front,
                        performanceMode: FaceDetectorMode.fast,
                        onFacesDetected: (faces, cameraImage) {
                          if (mounted) {
                            setState(() {
                              _detectedFaceCount = faces.length;
                              _isFacePresent = faces.isNotEmpty;
                              if (faces.isEmpty) {
                                _stabilityTracker.reset();
                                _stabilityProgress = 0.0;
                              }
                            });
                          }
                        },
                        onFaceDetected: _onFaceDetected,
                      )
                    : const ColoredBox(color: Color(0xFF0F172A)),
              ),

              // 2. Kiosk Terminal Header
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: _buildKioskHeader(employeeCount),
              ),

              // 3. Stability Progress Pill Overlay
              if (_isFacePresent &&
                  matchingState.lastVerifiedResult == null)
                Positioned(
                  top: 90,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1120).withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isProcessingInference
                              ? const Color(0xFF00B0FF)
                              : const Color(0xFF00E676).withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isProcessingInference
                                    ? const Color(0xFF00B0FF)
                                    : const Color(0xFF00E676))
                                .withValues(alpha: 0.25),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              value: _isProcessingInference
                                  ? null
                                  : _stabilityProgress.clamp(0.15, 1.0),
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _isProcessingInference
                                    ? const Color(0xFF00B0FF)
                                    : const Color(0xFF00E676),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _isProcessingInference
                                ? 'Matching biometric profile...'
                                : (_stabilityProgress >= 0.6
                                    ? 'Hold still • Scanning (${(_stabilityProgress * 100).toInt()}%)'
                                    : 'Hold still • Aligning face...'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 4. Bottom Status & Daily Stats Card
              Positioned(
                bottom: 20,
                left: 16,
                right: 16,
                child: _buildBottomStatusBar(matchingState),
              ),

              // 5. Animated Verification Success Card Overlay
              if (matchingState.lastVerifiedResult != null)
                Positioned.fill(
                  child: VerificationOverlayCard(
                    result: matchingState.lastVerifiedResult!,
                    onDismiss: () {
                      ref
                          .read(liveMatchingControllerProvider.notifier)
                          .clearVerifiedResult();
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKioskHeader(int employeeCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1120).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // Left: Brand & Employee Count (Expanded to prevent overflow)
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fingerprint_rounded,
                    color: Color(0xFF00E676),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'FACIAL ATTENDANCE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Offline • $employeeCount Enrolled',
                        style: const TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right: Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isFacePresent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.face, size: 13, color: Color(0xFF00E676)),
                      const SizedBox(width: 3),
                      Text(
                        '$_detectedFaceCount',
                        style: const TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              // Home / Exit Kiosk button
              IconButton(
                iconSize: 22,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.home_rounded, color: Colors.white70),
                tooltip: 'Return to Home Portal',
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 4),
              // View Logs button
              IconButton(
                iconSize: 22,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.history_rounded, color: Colors.white70),
                tooltip: "Today's Attendance Logs",
                onPressed: _showDailyLogsModal,
              ),
              const SizedBox(width: 4),
              // Enroll button
              IconButton(
                iconSize: 22,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.person_add_alt_1_rounded,
                    color: Color(0xFF00E676)),
                tooltip: 'Admin Enrollment',
                onPressed: _openAdminEnrollment,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStatusBar(LiveMatchingState matchingState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1120).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isFacePresent
              ? const Color(0xFF00E676).withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isFacePresent
                  ? const Color(0xFF00E676)
                  : Colors.amberAccent,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              matchingState.statusMessage,
              style: TextStyle(
                color: _isFacePresent ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF00B0FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Punches: ${matchingState.totalPunchesToday}',
              style: const TextStyle(
                color: Color(0xFF00B0FF),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Displays a modal sheet showing all attendance punches recorded today.
  void _showDailyLogsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B1120),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        final screenHeight = MediaQuery.of(modalContext).size.height;
        return SizedBox(
          height: screenHeight * 0.75,
          child: Consumer(
            builder: (context, ref, _) {
              final dailyAsync = ref.watch(todayAttendanceProvider);
              final employeeList =
                  ref.watch(employeeControllerProvider).valueOrNull ?? [];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.history_rounded,
                              color: Color(0xFF00E676),
                              size: 22,
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Today's Attendance Logs",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white60),
                          onPressed: () => Navigator.of(modalContext).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: dailyAsync.when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
                          ),
                        ),
                        error: (err, _) => Center(
                          child: Text(
                            'Failed to load records: $err',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                        data: (records) {
                          if (records.isEmpty) {
                            return const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.event_busy_rounded,
                                    size: 48,
                                    color: Colors.white24,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'No attendance punches recorded today.',
                                    style: TextStyle(color: Colors.white60, fontSize: 14),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.separated(
                            itemCount: records.length,
                            separatorBuilder: (_, __) =>
                                const Divider(color: Colors.white10, height: 1),
                            itemBuilder: (context, index) {
                              final record = records[index];
                              final emp = employeeList
                                  .where((e) => e.id == record.employeeId)
                                  .firstOrNull;
                              final isCheckIn =
                                  record.type == AttendanceType.checkIn;
                              final timeStr = DateFormat('hh:mm:ss a')
                                  .format(record.timestamp);

                              return ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: isCheckIn
                                      ? const Color(0xFF00E676)
                                          .withValues(alpha: 0.15)
                                      : const Color(0xFF00B0FF)
                                          .withValues(alpha: 0.15),
                                  child: Icon(
                                    isCheckIn
                                        ? Icons.login_rounded
                                        : Icons.logout_rounded,
                                    color: isCheckIn
                                        ? const Color(0xFF00E676)
                                        : const Color(0xFF00B0FF),
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  emp?.name ?? 'Employee #${record.employeeId}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Text(
                                  '${record.type.displayName} • $timeStr',
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                  ),
                                ),
                                trailing: record.recognitionConfidence != null
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00E676)
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${(record.recognitionConfidence! * 100).toStringAsFixed(0)}% match',
                                          style: const TextStyle(
                                            color: Color(0xFF00E676),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      )
                                    : null,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
