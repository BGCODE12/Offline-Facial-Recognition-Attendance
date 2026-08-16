import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/live_matching_controller.dart';
import '../providers/attendance_providers.dart';
import '../providers/employee_controller.dart';
import 'admin_dashboard_screen.dart';
import 'attendance_kiosk_screen.dart';

/// Main Landing / Portal Screen featuring two primary mode cards:
/// 1. Live Detection Kiosk (كشك الحضور والانصراف)
/// 2. Admin Control Hub (لوحة تحكم الإدارة لإدارة الموظفين والسجلات)
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeListAsync = ref.watch(employeeControllerProvider);
    final employeeCount = employeeListAsync.valueOrNull?.length ?? 0;
    final matchingState = ref.watch(liveMatchingControllerProvider);
    final todayPunches = matchingState.totalPunchesToday;
    final dbInit = ref.watch(databaseInitializerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: dbInit.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
            ),
          ),
          error: (err, _) => Center(
            child: Text(
              'Database Init Error: $err',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
          data: (_) => Column(
            children: [
              // 1. Kiosk Terminal Top Header
              _buildTopHeader(employeeCount, todayPunches),

              // 2. Main Two-Card Mode Selector
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  children: [
                    const Text(
                      'Select Operation Mode',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // CARD 1: Live Facial Attendance Kiosk
                    _buildPortalCard(
                      context: context,
                      title: 'Live Attendance Kiosk',
                      arabicTitle: 'كشك الحضور المباشر',
                      subtitle:
                          'Real-time camera feed, continuous face detection, instant 1:N recognition & automatic punch logging.',
                      icon: Icons.camera_front_rounded,
                      accentColor: const Color(0xFF00E676),
                      badgeText: 'Active Kiosk Mode',
                      buttonLabel: 'Launch Kiosk Stream',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AttendanceKioskScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // CARD 2: Admin Control Hub
                    _buildPortalCard(
                      context: context,
                      title: 'Admin Management Hub',
                      arabicTitle: 'لوحة تحكم الإدارة',
                      subtitle:
                          'Manage employee directory, enroll new staff with biometrics, review attendance history & logs.',
                      icon: Icons.admin_panel_settings_rounded,
                      accentColor: const Color(0xFF00B0FF),
                      badgeText: '$employeeCount Enrolled Staff',
                      buttonLabel: 'Open Admin Dashboard',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AdminDashboardScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // 3. Footer Branding
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(int employeeCount, int todayPunches) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1120),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fingerprint_rounded,
                      color: Color(0xFF00E676),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FACIAL ATTENDANCE AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Edge AI • 100% Offline Terminal',
                        style: TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00E676).withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: Color(0xFF00E676), size: 13),
                    SizedBox(width: 4),
                    Text(
                      'Ready',
                      style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Live Statistics Chips
          Row(
            children: [
              _buildMetricChip(
                label: 'Enrolled Staff',
                value: '$employeeCount',
                icon: Icons.people_alt_rounded,
                color: const Color(0xFF00B0FF),
              ),
              const SizedBox(width: 12),
              _buildMetricChip(
                label: "Today's Punches",
                value: '$todayPunches',
                icon: Icons.history_rounded,
                color: const Color(0xFF00E676),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortalCard({
    required BuildContext context,
    required String title,
    required String arabicTitle,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required String badgeText,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.08),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Icon + Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: accentColor, size: 28),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Titles
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                arabicTitle,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),

              // Description
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),

              // Action Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    buttonLabel,
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: accentColor,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      alignment: Alignment.center,
      child: const Text(
        'MobileFaceNet • On-Device Biometric Verification • Privacy First',
        style: TextStyle(
          color: Colors.white24,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
