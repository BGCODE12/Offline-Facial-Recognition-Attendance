/// Enum representing the types of attendance punches in the kiosk terminal.
enum AttendanceType {
  checkIn,
  checkOut;

  /// Human-readable label for UI/debugging.
  String get displayName {
    switch (this) {
      case AttendanceType.checkIn:
        return 'Check In';
      case AttendanceType.checkOut:
        return 'Check Out';
    }
  }
}
