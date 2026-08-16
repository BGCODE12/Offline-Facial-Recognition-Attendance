import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:face_attendance_kiosk/main.dart';

void main() {
  test('FacialAttendanceApp instantiates properly', () {
    const app = FacialAttendanceApp();
    expect(app, isA<StatelessWidget>());
  });
}
