import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/isar_service.dart';
import '../../data/models/attendance_record.dart';
import '../../data/repositories/local_attendance_repository_impl.dart';
import '../../domain/repositories/attendance_repository.dart';

/// Provider for the singleton [IsarService].
final isarServiceProvider = Provider<IsarService>((ref) {
  final service = IsarService();
  ref.onDispose(() {
    service.closeDB();
  });
  return service;
});

/// Provider exposing the abstract [AttendanceRepository] contract.
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return LocalAttendanceRepositoryImpl(isarService: isarService);
});

/// Provider for asynchronous database initialization at app startup.
final databaseInitializerProvider = FutureProvider<void>((ref) async {
  final repository = ref.watch(attendanceRepositoryProvider);
  await repository.initDB();
});

/// Provider for querying today's attendance records.
final todayAttendanceProvider =
    FutureProvider.autoDispose<List<AttendanceRecord>>((ref) async {
  final repository = ref.watch(attendanceRepositoryProvider);
  return await repository.getDailyRecords(DateTime.now());
});

/// Auto-disposing FutureProvider family for querying daily attendance records for any [DateTime].
final dailyAttendanceProvider = FutureProvider.autoDispose
    .family<List<AttendanceRecord>, DateTime>((ref, date) async {
  final repository = ref.watch(attendanceRepositoryProvider);
  return await repository.getDailyRecords(date);
});
