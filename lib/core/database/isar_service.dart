import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/employee.dart';
import '../../data/models/attendance_record.dart';

/// Database service responsible for managing the local [Isar] database lifecycle,
/// file directory storage path, and collection schema registration.
class IsarService {
  Isar? _isar;

  /// Returns the active [Isar] instance, automatically initializing if needed.
  Future<Isar> get db async {
    if (_isar != null && _isar!.isOpen) {
      return _isar!;
    }
    _isar = await openDB();
    return _isar!;
  }

  /// Initializes and opens the Isar database with [EmployeeSchema] and [AttendanceRecordSchema].
  Future<Isar> openDB() async {
    // Check if an instance is already open with the default or custom name
    if (Isar.instanceNames.isNotEmpty) {
      final existingInstance = Isar.getInstance('face_attendance_db') ??
          Isar.getInstance();
      if (existingInstance != null && existingInstance.isOpen) {
        _isar = existingInstance;
        return _isar!;
      }
    }

    // High performance offline storage directory on Android Kiosk
    final dir = await getApplicationDocumentsDirectory();

    _isar = await Isar.open(
      [
        EmployeeSchema,
        AttendanceRecordSchema,
      ],
      directory: dir.path,
      name: 'face_attendance_db',
      inspector: true, // Useful for debugging in development
    );

    return _isar!;
  }

  /// Closes the active Isar instance.
  Future<void> closeDB() async {
    if (_isar != null && _isar!.isOpen) {
      await _isar!.close();
      _isar = null;
    }
  }
}
