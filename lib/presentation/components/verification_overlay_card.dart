import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/attendance_type.dart';
import '../controllers/live_matching_controller.dart';

/// Futuristic animated verification overlay displayed upon successful facial attendance punch.
class VerificationOverlayCard extends StatefulWidget {
  final MatchResult result;
  final VoidCallback onDismiss;
  final Duration displayDuration;

  const VerificationOverlayCard({
    super.key,
    required this.result,
    required this.onDismiss,
    this.displayDuration = const Duration(milliseconds: 2600),
  });

  @override
  State<VerificationOverlayCard> createState() =>
      _VerificationOverlayCardState();
}

class _VerificationOverlayCardState extends State<VerificationOverlayCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _animController.forward();

    // Auto dismiss after display duration
    Future.delayed(widget.displayDuration, () {
      if (mounted) {
        _animController.reverse().then((_) {
          if (mounted) widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final employee = result.employee;
    final isCheckIn = result.record.type == AttendanceType.checkIn;
    final accentColor =
        isCheckIn ? const Color(0xFF00E676) : const Color(0xFF00B0FF);
    final timeFormatted =
        DateFormat('hh:mm:ss a').format(result.timestamp);
    final confidencePct = (result.confidence * 100).toStringAsFixed(1);

    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1120).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.8),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.35),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Success Icon / Punch Type Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: accentColor,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCheckIn
                                ? Icons.login_rounded
                                : Icons.logout_rounded,
                            size: 16,
                            color: accentColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            result.record.type.displayName.toUpperCase(),
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          size: 18,
                          color: Color(0xFF00E676),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$confidencePct% Match',
                          style: const TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 2. Employee Face Thumbnail & Profile Info
                Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accentColor,
                          width: 2.5,
                        ),
                        color: const Color(0xFF1E293B),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: result.facePreview != null
                          ? Image.memory(
                              result.facePreview!,
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: Text(
                                employee.name.isNotEmpty
                                    ? employee.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            employee.employeeCode ?? 'Badge: #${employee.id}',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: Colors.white54,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                timeFormatted,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 3. Status confirmation line
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Attendance Recorded Offline in Terminal DB',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
