import 'package:isar/isar.dart';
import 'attendance_type.dart';

part 'attendance_record.g.dart';

/// Database Entity representing an attendance punch record.
///
/// Records every facial recognition verification punch event offline on the kiosk.
@collection
class AttendanceRecord {
  /// Auto-incrementing primary key identifier.
  Id id = Isar.autoIncrement;

  /// Reference ID to the corresponding [Employee.id].
  @Index()
  late int employeeId;

  /// Timestamp indicating when the check-in / check-out occurred.
  /// Indexed for fast daily, weekly, or date-range lookups.
  @Index()
  late DateTime timestamp;

  /// Type of attendance event (checkIn or checkOut).
  @Enumerated(EnumType.name)
  late AttendanceType type;

  /// Optional similarity/confidence score (e.g. 0.0 - 1.0) of the face match.
  double? recognitionConfidence;

  AttendanceRecord({
    this.id = Isar.autoIncrement,
    required this.employeeId,
    required this.timestamp,
    required this.type,
    this.recognitionConfidence,
  });

  /// Create a copy of AttendanceRecord with updated fields.
  AttendanceRecord copyWith({
    Id? id,
    int? employeeId,
    DateTime? timestamp,
    AttendanceType? type,
    double? recognitionConfidence,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      recognitionConfidence:
          recognitionConfidence ?? this.recognitionConfidence,
    );
  }

  @override
  String toString() =>
      'AttendanceRecord(id: $id, employeeId: $employeeId, timestamp: $timestamp, type: ${type.name}, confidence: $recognitionConfidence)';
}
