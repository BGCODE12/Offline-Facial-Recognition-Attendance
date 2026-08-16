import 'package:isar/isar.dart';
import '../../core/database/isar_service.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../models/attendance_record.dart';
import '../models/employee.dart';

/// Concrete local implementation of [AttendanceRepository] backed by [Isar].
///
/// Provides ACID transactional writes, fast binary indexing, and vector
/// storage retrieval for real-time facial recognition matching on Kiosk terminals.
class LocalAttendanceRepositoryImpl implements AttendanceRepository {
  final IsarService _isarService;
  Isar? _db;

  LocalAttendanceRepositoryImpl({IsarService? isarService})
      : _isarService = isarService ?? IsarService();

  /// Helper to get the ready Isar database instance.
  Future<Isar> _getDB() async {
    _db ??= await _isarService.db;
    return _db!;
  }

  @override
  Future<void> initDB() async {
    _db = await _isarService.openDB();
  }

  @override
  Future<void> saveEmployee(Employee employee) async {
    final isar = await _getDB();
    await isar.writeTxn(() async {
      await isar.employees.put(employee);
    });
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    final isar = await _getDB();
    await isar.writeTxn(() async {
      await isar.employees.put(employee);
    });
  }

  @override
  Future<bool> deleteEmployee(int employeeId) async {
    final isar = await _getDB();
    return await isar.writeTxn(() async {
      return await isar.employees.delete(employeeId);
    });
  }

  @override
  Future<List<Employee>> getAllEmployees() async {
    final isar = await _getDB();
    return await isar.employees.where().findAll();
  }

  @override
  Future<void> addAttendanceRecord(AttendanceRecord record) async {
    final isar = await _getDB();
    await isar.writeTxn(() async {
      await isar.attendanceRecords.put(record);
    });
  }

  @override
  Future<List<AttendanceRecord>> getDailyRecords(DateTime date) async {
    final isar = await _getDB();

    // Compute boundary timestamps for the specified calendar day
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0, 0);
    final endOfDay =
        DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    // Query indexed timestamp range sorted in descending order (most recent first)
    return await isar.attendanceRecords
        .filter()
        .timestampBetween(startOfDay, endOfDay)
        .sortByTimestampDesc()
        .findAll();
  }

  @override
  Future<void> closeDB() async {
    await _isarService.closeDB();
    _db = null;
  }
}
