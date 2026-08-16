import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:face_attendance_kiosk/core/database/isar_service.dart';
import 'package:face_attendance_kiosk/core/ml/face_recognition_service.dart';
import 'package:face_attendance_kiosk/data/models/attendance_record.dart';
import 'package:face_attendance_kiosk/data/models/attendance_type.dart';
import 'package:face_attendance_kiosk/data/models/employee.dart';
import 'package:face_attendance_kiosk/data/repositories/local_attendance_repository_impl.dart';
import 'package:face_attendance_kiosk/presentation/controllers/live_matching_controller.dart';
import 'package:face_attendance_kiosk/presentation/providers/attendance_providers.dart';
import 'package:face_attendance_kiosk/presentation/providers/employee_controller.dart';

void main() {
  group('LiveMatchingController 1:N Matching & Debounce Tests', () {
    late Isar isar;
    late LocalAttendanceRepositoryImpl repository;
    late Directory tempDir;
    late FaceRecognitionService recognitionService;
    late ProviderContainer container;

    setUpAll(() async {
      await Isar.initializeIsarCore(download: true);
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('isar_match_test_');
      isar = await Isar.open(
        [EmployeeSchema, AttendanceRecordSchema],
        directory: tempDir.path,
        name: 'match_test_${DateTime.now().microsecondsSinceEpoch}',
      );

      final isarService = _MockIsarService(isar);
      repository = LocalAttendanceRepositoryImpl(isarService: isarService);
      recognitionService = FaceRecognitionService();

      container = ProviderContainer(
        overrides: [
          attendanceRepositoryProvider.overrideWithValue(repository),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await isar.close(deleteFromDisk: true);
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Identifies the correct employee from 1:N cached list via Cosine Similarity',
        () async {
      // 1. Create distinct 192-d unit vectors for Employee A and Employee B
      final vectorA = recognitionService.l2Normalize(
          List<double>.generate(192, (i) => i == 0 ? 1.0 : 0.0));
      final vectorB = recognitionService.l2Normalize(
          List<double>.generate(192, (i) => i == 1 ? 1.0 : 0.0));

      final empA = Employee(
        id: 1,
        name: 'Alice Smith',
        employeeCode: 'EMP-001',
        faceFeatures: vectorA,
      );

      final empB = Employee(
        id: 2,
        name: 'Bob Johnson',
        employeeCode: 'EMP-002',
        faceFeatures: vectorB,
      );

      await repository.saveEmployee(empA);
      await repository.saveEmployee(empB);

      // Warm up employee cache
      await container.read(employeeControllerProvider.future);

      final controller = container.read(liveMatchingControllerProvider.notifier);

      // Probe with vector matching Alice (dot product ~ 1.0)
      final matchAlice =
          await controller.processProbeEmbedding(probeEmbedding: vectorA);

      expect(matchAlice, isNotNull);
      expect(matchAlice!.employee.name, 'Alice Smith');
      expect(matchAlice.record.type, AttendanceType.checkIn);
      expect(matchAlice.confidence, closeTo(1.0, 0.001));
    });

    test('Ignores unknown face when highest similarity is below threshold (0.82)',
        () async {
      final knownVector = recognitionService.l2Normalize(
          List<double>.generate(192, (i) => i == 0 ? 1.0 : 0.0));

      final emp = Employee(
        id: 1,
        name: 'Known User',
        faceFeatures: knownVector,
      );
      await repository.saveEmployee(emp);
      await container.read(employeeControllerProvider.future);

      final controller = container.read(liveMatchingControllerProvider.notifier);

      // Orthogonal unknown probe vector (cosine similarity = 0.0 < 0.82)
      final unknownProbe = recognitionService.l2Normalize(
          List<double>.generate(192, (i) => i == 100 ? 1.0 : 0.0));

      final matchResult = await controller.processProbeEmbedding(
        probeEmbedding: unknownProbe,
      );

      expect(matchResult, isNull);
      final records = await repository.getAllEmployees();
      expect(records.length, 1);
      final punches = await repository.getDailyRecords(DateTime.now());
      expect(punches.isEmpty, isTrue); // No punch logged for unknown face
    });

    test('Debounce cooldown prevents duplicate database punch within 5s window',
        () async {
      final vector = recognitionService.l2Normalize(
          List<double>.generate(192, (i) => 1.0));

      final emp = Employee(
        id: 10,
        name: 'Charlie Brown',
        faceFeatures: vector,
      );
      await repository.saveEmployee(emp);
      await container.read(employeeControllerProvider.future);

      final controller = container.read(liveMatchingControllerProvider.notifier);

      // First Punch -> Should succeed
      final firstMatch =
          await controller.processProbeEmbedding(probeEmbedding: vector);
      expect(firstMatch, isNotNull);

      // Immediate Second Punch (same probe) -> Should be ignored by cooldown
      final secondMatch =
          await controller.processProbeEmbedding(probeEmbedding: vector);
      expect(secondMatch, isNull);

      final dailyPunches = await repository.getDailyRecords(DateTime.now());
      expect(dailyPunches.length, 1); // Only 1 record in DB
    });

    test('Smart punch toggles automatically between checkIn and checkOut',
        () async {
      final vector = recognitionService.l2Normalize(
          List<double>.generate(192, (i) => i.toDouble() + 1.0));

      final emp = Employee(
        id: 25,
        name: 'Diana Prince',
        faceFeatures: vector,
      );
      await repository.saveEmployee(emp);
      await container.read(employeeControllerProvider.future);

      final controller = container.read(liveMatchingControllerProvider.notifier);

      // 1. First punch of the day -> checkIn
      final punch1 =
          await controller.processProbeEmbedding(probeEmbedding: vector);
      expect(punch1?.record.type, AttendanceType.checkIn);

      // Clear cooldown manually to simulate time passage
      controller.clearCooldowns();

      // 2. Second punch -> toggles to checkOut
      final punch2 =
          await controller.processProbeEmbedding(probeEmbedding: vector);
      expect(punch2?.record.type, AttendanceType.checkOut);

      // Clear cooldown again
      controller.clearCooldowns();

      // 3. Third punch -> toggles back to checkIn
      final punch3 =
          await controller.processProbeEmbedding(probeEmbedding: vector);
      expect(punch3?.record.type, AttendanceType.checkIn);

      final allRecords = await repository.getDailyRecords(DateTime.now());
      expect(allRecords.length, 3);
    });
  });
}

class _MockIsarService extends IsarService {
  final Isar _mockDb;
  _MockIsarService(this._mockDb);

  @override
  Future<Isar> get db async => _mockDb;

  @override
  Future<Isar> openDB() async => _mockDb;

  @override
  Future<void> closeDB() async {}
}
