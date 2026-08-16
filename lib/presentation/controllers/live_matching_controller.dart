import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ml/face_recognition_service.dart';
import '../../data/models/attendance_record.dart';
import '../../data/models/attendance_type.dart';
import '../../data/models/employee.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../providers/attendance_providers.dart';
import '../providers/employee_controller.dart';
import '../providers/face_recognition_provider.dart';

/// Data class representing a successful biometric match event.
class MatchResult {
  final Employee employee;
  final AttendanceRecord record;
  final double confidence;
  final DateTime timestamp;
  final Uint8List? facePreview;

  MatchResult({
    required this.employee,
    required this.record,
    required this.confidence,
    required this.timestamp,
    this.facePreview,
  });
}

/// State of the live facial matching pipeline.
class LiveMatchingState {
  final bool isMatching;
  final MatchResult? lastVerifiedResult;
  final String statusMessage;
  final int totalPunchesToday;

  const LiveMatchingState({
    this.isMatching = false,
    this.lastVerifiedResult,
    this.statusMessage = 'Align face with camera to scan attendance',
    this.totalPunchesToday = 0,
  });

  LiveMatchingState copyWith({
    bool? isMatching,
    MatchResult? lastVerifiedResult,
    bool clearVerifiedResult = false,
    String? statusMessage,
    int? totalPunchesToday,
  }) {
    return LiveMatchingState(
      isMatching: isMatching ?? this.isMatching,
      lastVerifiedResult:
          clearVerifiedResult ? null : (lastVerifiedResult ?? this.lastVerifiedResult),
      statusMessage: statusMessage ?? this.statusMessage,
      totalPunchesToday: totalPunchesToday ?? this.totalPunchesToday,
    );
  }
}

/// StateNotifier managing continuous 1:N facial matching, debounce cooldowns,
/// and automatic AttendanceRecord persistence.
class LiveMatchingController extends StateNotifier<LiveMatchingState> {
  final AttendanceRepository _repository;
  final FaceRecognitionService _recognitionService;
  final Ref _ref;

  /// Cosine similarity threshold for a verified positive face match.
  final double similarityThreshold;

  /// Cooldown duration per employee to prevent duplicate database writes.
  final Duration cooldownDuration;

  /// In-memory timestamp map tracking the last punch time for each employee ID.
  final Map<int, DateTime> _cooldownMap = {};

  LiveMatchingController({
    required AttendanceRepository repository,
    required FaceRecognitionService recognitionService,
    required Ref ref,
    this.similarityThreshold = 0.78,
    this.cooldownDuration = const Duration(seconds: 5),
  })  : _repository = repository,
        _recognitionService = recognitionService,
        _ref = ref,
        super(const LiveMatchingState()) {
    _initDailyPunchCount();
  }

  /// Initial load of today's total punch count.
  Future<void> _initDailyPunchCount() async {
    try {
      final records = await _repository.getDailyRecords(DateTime.now());
      state = state.copyWith(totalPunchesToday: records.length);
    } catch (_) {}
  }

  /// Performs 1:N cosine similarity matching against in-memory cached employees.
  Future<MatchResult?> processProbeEmbedding({
    required List<double> probeEmbedding,
    Uint8List? facePreview,
  }) async {
    if (state.isMatching) return null;

    // 1. Retrieve in-memory cached employees from Riverpod EmployeeController
    final cachedEmployees =
        _ref.read(employeeControllerProvider).valueOrNull ?? [];

    if (cachedEmployees.isEmpty) {
      state = state.copyWith(
        statusMessage: 'No employees registered. Tap + to enroll.',
      );
      return null;
    }

    state = state.copyWith(isMatching: true);

    try {
      Employee? bestMatch;
      double highestScore = -1.0;

      // 2. 1:N Cosine Similarity search
      for (final employee in cachedEmployees) {
        if (employee.faceFeatures.isEmpty) continue;

        final score = _recognitionService.cosineSimilarity(
          probeEmbedding,
          employee.faceFeatures,
        );

        if (score > highestScore) {
          highestScore = score;
          bestMatch = employee;
        }
      }

      // 3. Evaluate Match Threshold
      if (bestMatch != null && highestScore >= similarityThreshold) {
        final employeeId = bestMatch.id;
        final now = DateTime.now();

        // 4. Check Debounce / Cooldown window
        final lastPunch = _cooldownMap[employeeId];
        if (lastPunch != null &&
            now.difference(lastPunch) < cooldownDuration) {
          final remainingSecs =
              cooldownDuration.inSeconds - now.difference(lastPunch).inSeconds;
          state = state.copyWith(
            isMatching: false,
            statusMessage:
                '${bestMatch.name} already recorded. Wait ${remainingSecs}s.',
          );
          return null;
        }

        // Update cooldown timestamp
        _cooldownMap[employeeId] = now;

        // 5. Determine Smart Punch Type (checkIn vs checkOut)
        final todayRecords = await _repository.getDailyRecords(now);
        final employeeTodayRecords =
            todayRecords.where((r) => r.employeeId == employeeId).toList();

        // If no punch today or last was checkOut -> checkIn; otherwise -> checkOut
        final AttendanceType punchType;
        if (employeeTodayRecords.isEmpty ||
            employeeTodayRecords.first.type == AttendanceType.checkOut) {
          punchType = AttendanceType.checkIn;
        } else {
          punchType = AttendanceType.checkOut;
        }

        final record = AttendanceRecord(
          employeeId: employeeId,
          timestamp: now,
          type: punchType,
          recognitionConfidence: highestScore,
        );

        // 6. Persist AttendanceRecord in Isar DB
        await _repository.addAttendanceRecord(record);

        final result = MatchResult(
          employee: bestMatch,
          record: record,
          confidence: highestScore,
          timestamp: now,
          facePreview: facePreview,
        );

        final confidencePct = (highestScore * 100).toStringAsFixed(0);
        state = state.copyWith(
          isMatching: false,
          lastVerifiedResult: result,
          statusMessage:
              'Verified: ${bestMatch.name} ($confidencePct% • ${punchType.displayName})',
          totalPunchesToday: state.totalPunchesToday + 1,
        );

        // Refresh today's records provider
        _ref.invalidate(todayAttendanceProvider);

        return result;
      } else {
        state = state.copyWith(
          isMatching: false,
          statusMessage: 'Face not recognized. Please retry or contact Admin.',
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isMatching: false,
        statusMessage: 'Matching error: $e',
      );
      return null;
    }
  }

  /// Clears the verified overlay result once the display timeout elapses.
  void clearVerifiedResult() {
    state = state.copyWith(
      clearVerifiedResult: true,
      statusMessage: 'Align face with camera to scan attendance',
    );
  }

  /// Resets cooldown for a specific employee or all employees (useful for testing).
  void clearCooldowns() {
    _cooldownMap.clear();
  }
}

/// Provider for [LiveMatchingController].
final liveMatchingControllerProvider =
    StateNotifierProvider<LiveMatchingController, LiveMatchingState>((ref) {
  final repository = ref.watch(attendanceRepositoryProvider);
  final recognitionService = ref.watch(faceRecognitionServiceProvider);

  return LiveMatchingController(
    repository: repository,
    recognitionService: recognitionService,
    ref: ref,
  );
});
