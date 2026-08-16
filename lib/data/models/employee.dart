import 'package:isar/isar.dart';

part 'employee.g.dart';

/// Database Entity representing an Employee in the Kiosk system.
///
/// Stores employee profile information along with their facial recognition
/// embeddings ([faceFeatures]), which represent high-dimensional vectors
/// (e.g., 192 or 512 dimensions from MobileFaceNet) used for offline matching.
@collection
class Employee {
  /// Auto-incrementing primary key identifier.
  Id id = Isar.autoIncrement;

  /// Optional badge / employee identification string.
  @Index()
  String? employeeCode;

  /// Full name of the employee.
  @Index()
  late String name;

  /// MobileFaceNet TFLite embedding vector (List of double precision values).
  /// This vector is compared via Euclidean or Cosine distance during facial verification.
  late List<double> faceFeatures;

  /// Registration / enrollment timestamp.
  DateTime? createdAt;

  Employee({
    this.id = Isar.autoIncrement,
    this.employeeCode,
    required this.name,
    required this.faceFeatures,
    this.createdAt,
  });

  /// Create a copy of Employee with updated fields.
  Employee copyWith({
    Id? id,
    String? employeeCode,
    String? name,
    List<double>? faceFeatures,
    DateTime? createdAt,
  }) {
    return Employee(
      id: id ?? this.id,
      employeeCode: employeeCode ?? this.employeeCode,
      name: name ?? this.name,
      faceFeatures: faceFeatures ?? this.faceFeatures,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'Employee(id: $id, name: $name, employeeCode: $employeeCode, featuresCount: ${faceFeatures.length})';
}
