import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/employee.dart';
import '../../domain/repositories/attendance_repository.dart';
import 'attendance_providers.dart';

/// State Controller managing the list of enrolled [Employee]s and face vector operations.
///
/// Implements [AsyncNotifier] for clean async loading, error handling, and state mutation.
class EmployeeController extends AsyncNotifier<List<Employee>> {
  late final AttendanceRepository _repository;

  @override
  Future<List<Employee>> build() async {
    _repository = ref.watch(attendanceRepositoryProvider);
    return _fetchEmployees();
  }

  /// Internal helper to load all employees from local Isar database.
  Future<List<Employee>> _fetchEmployees() async {
    return await _repository.getAllEmployees();
  }

  /// Persists a new or updated [Employee] with their facial recognition embeddings.
  /// Updates the local state immediately upon successful transaction.
  Future<void> saveEmployee(Employee employee) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.saveEmployee(employee);
      return await _fetchEmployees();
    });
  }

  /// Updates an existing [Employee] details.
  Future<void> updateEmployee(Employee employee) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateEmployee(employee);
      return await _fetchEmployees();
    });
  }

  /// Deletes an employee by ID and refreshes the state.
  Future<bool> deleteEmployee(int id) async {
    state = const AsyncValue.loading();
    bool success = false;
    state = await AsyncValue.guard(() async {
      success = await _repository.deleteEmployee(id);
      return await _fetchEmployees();
    });
    return success;
  }

  /// Forces a reload of all employees from the local database.
  Future<void> refreshEmployees() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => await _fetchEmployees());
  }

  /// Helper to lookup an employee by ID from currently cached state.
  Employee? findById(int id) {
    return state.valueOrNull?.where((e) => e.id == id).firstOrNull;
  }
}

/// Provider for accessing the [EmployeeController] state and methods.
final employeeControllerProvider =
    AsyncNotifierProvider<EmployeeController, List<Employee>>(() {
  return EmployeeController();
});
