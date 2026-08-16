import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/attendance_type.dart';
import '../../data/models/employee.dart';
import '../controllers/live_matching_controller.dart';
import '../providers/attendance_providers.dart';
import '../providers/employee_controller.dart';
import 'admin_enrollment_screen.dart';

/// Full Admin Management Dashboard featuring:
/// 1. Employee Directory (Search, Add, Edit, Delete)
/// 2. Attendance Logs & Analytics (Date Filter, Summary Counters, Live Record Stream)
/// 3. Terminal & Biometric System Diagnostics
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _employeeSearchController =
      TextEditingController();
  DateTime _selectedLogDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _employeeSearchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _employeeSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeeControllerProvider);
    final employeeCount = employeesAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Control Hub',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$employeeCount Enrolled Staff • Offline System',
              style: const TextStyle(
                color: Color(0xFF00E676),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00E676),
          indicatorWeight: 3,
          labelColor: const Color(0xFF00E676),
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.people_alt_rounded, size: 20), text: 'Employees'),
            Tab(icon: Icon(Icons.history_rounded, size: 20), text: 'Attendance Logs'),
            Tab(icon: Icon(Icons.tune_rounded, size: 20), text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEmployeesTab(employeesAsync),
          _buildAttendanceLogsTab(),
          _buildSettingsTab(employeeCount),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text(
                'Enroll Employee',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdminEnrollmentScreen(),
                  ),
                );
                ref.read(employeeControllerProvider.notifier).refreshEmployees();
              },
            )
          : null,
    );
  }

  // ==========================================
  // TAB 1: EMPLOYEES DIRECTORY & CRUD
  // ==========================================
  Widget _buildEmployeesTab(AsyncValue<List<Employee>> employeesAsync) {
    return employeesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
        ),
      ),
      error: (err, _) => Center(
        child: Text(
          'Failed to load employees: $err',
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
      data: (employees) {
        final query = _employeeSearchController.text.trim().toLowerCase();
        final filteredEmployees = employees.where((e) {
          final matchesName = e.name.toLowerCase().contains(query);
          final matchesCode =
              e.employeeCode?.toLowerCase().contains(query) ?? false;
          return matchesName || matchesCode;
        }).toList();

        return Column(
          children: [
            // Search Box
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _employeeSearchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search by employee name or code...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.white60),
                  suffixIcon: _employeeSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white60),
                          onPressed: () => _employeeSearchController.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),

            // Employee List
            Expanded(
              child: filteredEmployees.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            employees.isEmpty
                                ? Icons.group_off_rounded
                                : Icons.search_off_rounded,
                            size: 64,
                            color: Colors.white24,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            employees.isEmpty
                                ? 'No employees registered yet.\nTap "Enroll Employee" to add the first one.'
                                : 'No employees matching "$query"',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 80,
                      ),
                      itemCount: filteredEmployees.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final employee = filteredEmployees[index];
                        return _buildEmployeeCard(employee);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
    final initials = employee.name.trim().isNotEmpty
        ? employee.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : 'E';
    final dateStr = employee.createdAt != null
        ? DateFormat('MMM dd, yyyy').format(employee.createdAt!)
        : 'Enrolled';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          // Initials Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF00E676).withValues(alpha: 0.15),
            child: Text(
              initials.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF00E676),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (employee.employeeCode != null &&
                        employee.employeeCode!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B0FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          employee.employeeCode!,
                          style: const TextStyle(
                            color: Color(0xFF00B0FF),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Menu (Edit / Delete)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF00B0FF), size: 20),
                tooltip: 'Edit Employee',
                onPressed: () => _showEditEmployeeDialog(employee),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent, size: 20),
                tooltip: 'Delete Employee',
                onPressed: () => _confirmDeleteEmployee(employee),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: ATTENDANCE LOGS & REPORTS
  // ==========================================
  Widget _buildAttendanceLogsTab() {
    final dailyAsync = ref.watch(dailyAttendanceProvider(_selectedLogDate));
    final employees =
        ref.watch(employeeControllerProvider).valueOrNull ?? [];

    return Column(
      children: [
        // Date Selector & Summary Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF0B1120),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Date Filter',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('EEEE, MMM dd, yyyy').format(_selectedLogDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _pickLogDate,
                    icon: const Icon(Icons.calendar_month_rounded, size: 16),
                    label: const Text('Change Date'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: const Color(0xFF00E676),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Logs Stream
        Expanded(
          child: dailyAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
              ),
            ),
            error: (err, _) => Center(
              child: Text(
                'Failed to load records: $err',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
            data: (records) {
              final checkIns = records
                  .where((r) => r.type == AttendanceType.checkIn)
                  .length;
              final checkOuts = records
                  .where((r) => r.type == AttendanceType.checkOut)
                  .length;

              if (records.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.event_busy_rounded,
                          size: 64, color: Colors.white24),
                      const SizedBox(height: 12),
                      Text(
                        'No attendance punches on ${DateFormat('MMM dd, yyyy').format(_selectedLogDate)}',
                        style: const TextStyle(color: Colors.white60),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  // Quick Summary Badges
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        _buildStatChip('Total Punches', '${records.length}',
                            const Color(0xFF00B0FF)),
                        const SizedBox(width: 8),
                        _buildStatChip(
                            'Check-Ins', '$checkIns', const Color(0xFF00E676)),
                        const SizedBox(width: 8),
                        _buildStatChip(
                            'Check-Outs', '$checkOuts', Colors.amberAccent),
                      ],
                    ),
                  ),

                  // Record Items
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: records.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: Colors.white10, height: 1),
                      itemBuilder: (context, index) {
                        final record = records[index];
                        final emp = employees
                            .where((e) => e.id == record.employeeId)
                            .firstOrNull;
                        final isCheckIn = record.type == AttendanceType.checkIn;
                        final timeStr = DateFormat('hh:mm:ss a')
                            .format(record.timestamp);

                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 4),
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: isCheckIn
                                ? const Color(0xFF00E676).withValues(alpha: 0.15)
                                : const Color(0xFF00B0FF).withValues(alpha: 0.15),
                            child: Icon(
                              isCheckIn
                                  ? Icons.login_rounded
                                  : Icons.logout_rounded,
                              color: isCheckIn
                                  ? const Color(0xFF00E676)
                                  : const Color(0xFF00B0FF),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            emp?.name ?? 'Employee #${record.employeeId}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            '${record.type.displayName} • $timeStr',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                          trailing: record.recognitionConfidence != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00E676)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${(record.recognitionConfidence! * 100).toStringAsFixed(0)}% match',
                                    style: const TextStyle(
                                      color: Color(0xFF00E676),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 3: SYSTEM SETTINGS & DIAGNOSTICS
  // ==========================================
  Widget _buildSettingsTab(int employeeCount) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // System Health Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_rounded, color: Color(0xFF00E676), size: 22),
                  SizedBox(width: 10),
                  Text(
                    'System Diagnostics',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSettingItem('AI Engine', 'MobileFaceNet TFLite (192-dim)',
                  Icons.memory_rounded, const Color(0xFF00E676)),
              _buildSettingItem('Local Database', 'Isar Embedded ACID Storage',
                  Icons.storage_rounded, const Color(0xFF00B0FF)),
              _buildSettingItem('Enrolled Biometrics', '$employeeCount Active Profiles',
                  Icons.fingerprint_rounded, Colors.amberAccent),
              _buildSettingItem('Matching Mode', '1:N Cosine Similarity (0.78)',
                  Icons.psychology_rounded, const Color(0xFF00E676)),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Quick Maintenance Actions
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Maintenance & Actions',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.refresh_rounded, color: Color(0xFF00E676)),
                title: const Text('Refresh In-Memory Cache',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Reload all employee vectors from database',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                onTap: () async {
                  await ref.read(employeeControllerProvider.notifier).refreshEmployees();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Employee cache refreshed successfully!'),
                        backgroundColor: Color(0xFF00E676),
                      ),
                    );
                  }
                },
              ),
              const Divider(color: Colors.white10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.timer_off_outlined, color: Color(0xFF00B0FF)),
                title: const Text('Clear Punch Cooldowns',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Allow immediate re-punch for testing',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                onTap: () {
                  ref.read(liveMatchingControllerProvider.notifier).clearCooldowns();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All debounce cooldown timers cleared!'),
                      backgroundColor: Color(0xFF00B0FF),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
      String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 12)),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DIALOGS & ACTIONS
  // ==========================================
  Future<void> _pickLogDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedLogDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00E676),
              onPrimary: Colors.black,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedLogDate) {
      setState(() => _selectedLogDate = picked);
    }
  }

  Future<void> _showEditEmployeeDialog(Employee employee) async {
    final nameCtrl = TextEditingController(text: employee.name);
    final codeCtrl = TextEditingController(text: employee.employeeCode ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Edit Employee Details',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Employee Full Name',
                    labelStyle: TextStyle(color: Color(0xFF00E676)),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: codeCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Badge / Employee Code (Optional)',
                    labelStyle: TextStyle(color: Color(0xFF00B0FF)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final updated = employee.copyWith(
                    name: nameCtrl.text.trim(),
                    employeeCode: codeCtrl.text.trim().isEmpty
                        ? null
                        : codeCtrl.text.trim(),
                  );
                  Navigator.of(dialogCtx).pop();
                  await ref
                      .read(employeeControllerProvider.notifier)
                      .updateEmployee(updated);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Updated "${updated.name}" successfully!'),
                        backgroundColor: const Color(0xFF00E676),
                      ),
                    );
                  }
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteEmployee(Employee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              const SizedBox(width: 10),
              const Text('Delete Employee', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${employee.name}"?\nThis will remove their biometric face profile from the terminal.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text('Delete Permanently'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await ref.read(employeeControllerProvider.notifier).deleteEmployee(employee.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Employee "${employee.name}" deleted.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
