import '../../data/models/employee.dart';
import '../../data/models/attendance_record.dart';

/// Abstract contract for local attendance and employee data operations.
///
/// Ensures Clean Architecture boundary separation between data persistence
/// mechanisms (Isar/Hive/SQLite) and business logic/presentation layers.
abstract class AttendanceRepository {
  /// Initializes the local database storage, schemas, and directory configurations.
  Future<void> initDB();

  /// Persists or updates an [Employee] record, including face feature embeddings.
  Future<void> saveEmployee(Employee employee);

  /// Updates an existing [Employee] record in the local database.
  Future<void> updateEmployee(Employee employee);

  /// Deletes an enrolled [Employee] from the local database by ID.
  Future<bool> deleteEmployee(int employeeId);

  /// Retrieves all enrolled employees along with their facial embedding vectors.
  Future<List<Employee>> getAllEmployees();

  /// Persists a new attendance punch record ([record]) when a face match is verified.
  Future<void> addAttendanceRecord(AttendanceRecord record);

  /// Retrieves all attendance records recorded within the 24-hour window of [date].
  Future<List<AttendanceRecord>> getDailyRecords(DateTime date);

  /// Closes the database connection safely during app shutdown.
  Future<void> closeDB();
}
