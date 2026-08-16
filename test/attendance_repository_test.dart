import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:face_attendance_kiosk/core/database/isar_service.dart';
import 'package:face_attendance_kiosk/data/models/attendance_record.dart';
import 'package:face_attendance_kiosk/data/models/attendance_type.dart';
import 'package:face_attendance_kiosk/data/models/employee.dart';
import 'package:face_attendance_kiosk/data/repositories/local_attendance_repository_impl.dart';

void main() {
  group('LocalAttendanceRepository & Isar Models Test', () {
    late Isar isar;
    late LocalAttendanceRepositoryImpl repository;
    late Directory tempDir;

    setUpAll(() async {
      await Isar.initializeIsarCore(download: true);
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('isar_test_');
      isar = await Isar.open(
        [EmployeeSchema, AttendanceRecordSchema],
        directory: tempDir.path,
        name: 'test_db_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Create repository with mock/custom Isar instance
      final testService = TestIsarService(isar);
      repository = LocalAttendanceRepositoryImpl(isarService: testService);
    });

    tearDown(() async {
      await isar.close(deleteFromDisk: true);
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Should save and retrieve employee with 192-dim face embedding vector',
        () async {
      // Generate synthetic 192-dimensional MobileFaceNet embedding vector
      final mockVector = List<double>.generate(192, (i) => (i * 0.005) - 0.48);

      final employee = Employee(
        name: 'Jane Doe',
        employeeCode: 'EMP-001',
        faceFeatures: mockVector,
      );

      await repository.saveEmployee(employee);

      final employees = await repository.getAllEmployees();
      expect(employees.length, 1);
      expect(employees.first.name, 'Jane Doe');
      expect(employees.first.employeeCode, 'EMP-001');
      expect(employees.first.faceFeatures.length, 192);
      expect(employees.first.faceFeatures[0], closeTo(-0.48, 0.0001));
      expect(employees.first.faceFeatures[100], closeTo(0.02, 0.0001));
    });

    test(
        'Should save multiple employees with null employeeCode without overwriting',
        () async {
      final mockVector1 = List<double>.generate(192, (i) => 0.1);
      final mockVector2 = List<double>.generate(192, (i) => 0.2);

      final emp1 = Employee(
        name: 'Employee One',
        employeeCode: null,
        faceFeatures: mockVector1,
      );

      final emp2 = Employee(
        name: 'Employee Two',
        employeeCode: null,
        faceFeatures: mockVector2,
      );

      await repository.saveEmployee(emp1);
      await repository.saveEmployee(emp2);

      final employees = await repository.getAllEmployees();
      expect(employees.length, 2);
      expect(employees.map((e) => e.name).toList(),
          containsAll(['Employee One', 'Employee Two']));
    });

    test(
        'Should add attendance records and retrieve only records for specified date',
        () async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      final recordToday1 = AttendanceRecord(
        employeeId: 1,
        timestamp: DateTime(today.year, today.month, today.day, 8, 30),
        type: AttendanceType.checkIn,
        recognitionConfidence: 0.94,
      );

      final recordToday2 = AttendanceRecord(
        employeeId: 1,
        timestamp: DateTime(today.year, today.month, today.day, 17, 15),
        type: AttendanceType.checkOut,
        recognitionConfidence: 0.91,
      );

      final recordYesterday = AttendanceRecord(
        employeeId: 1,
        timestamp:
            DateTime(yesterday.year, yesterday.month, yesterday.day, 9, 0),
        type: AttendanceType.checkIn,
        recognitionConfidence: 0.89,
      );

      await repository.addAttendanceRecord(recordToday1);
      await repository.addAttendanceRecord(recordToday2);
      await repository.addAttendanceRecord(recordYesterday);

      final todayRecords = await repository.getDailyRecords(today);
      expect(todayRecords.length, 2);
      expect(todayRecords.first.type, AttendanceType.checkOut); // Sorted desc
      expect(todayRecords.last.type, AttendanceType.checkIn);

      final yesterdayRecords = await repository.getDailyRecords(yesterday);
      expect(yesterdayRecords.length, 1);
      expect(yesterdayRecords.first.type, AttendanceType.checkIn);
    });
  });
}

class TestIsarService extends IsarService {
  final Isar _testIsar;
  TestIsarService(this._testIsar);

  @override
  Future<Isar> get db async => _testIsar;

  @override
  Future<Isar> openDB() async => _testIsar;

  @override
  Future<void> closeDB() async {
    // handled in test teardown
  }
}
