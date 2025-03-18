// lib/Providers/attendance_providers.dart
import 'package:attendanceapp/Models/attendance_model.dart';
import 'package:attendanceapp/services/attendance_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Main service provider
final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService();
});

// Provider for all attendances
final attendancesProvider = StreamProvider<List<AttendanceModel>>((ref) {
  return ref.read(attendanceServiceProvider).getAttendances();
});

// Provider for pending attendance for lecturer
final pendingAttendanceForLecturerProvider = FutureProvider.family<List<AttendanceModel>, String>((ref, lecturerId) {
  return ref.read(attendanceServiceProvider).getPendingAttendanceForLecturer(lecturerId);
});

// Provider for attendance by course
final attendanceForCourseProvider = FutureProvider.family<List<AttendanceModel>, String>((ref, courseId) {
  return ref.read(attendanceServiceProvider).getAttendanceForCourse(courseId);
});

// Provider for student attendances
final studentAttendancesProvider = StreamProvider.family<List<AttendanceModel>, String>((ref, studentId) {
  return ref.read(attendanceServiceProvider).getAttendanceByStudent(studentId);
});

// State notifier provider for managing attendance
final attendanceManagerProvider = StateNotifierProvider<AttendanceNotifier, AsyncValue<List<AttendanceModel>>>((ref) {
  return AttendanceNotifier(ref.read(attendanceServiceProvider));
});

class AttendanceNotifier extends StateNotifier<AsyncValue<List<AttendanceModel>>> {
  final AttendanceService _attendanceService;

  AttendanceNotifier(this._attendanceService) : super(const AsyncValue.loading());

  Future<void> submitAttendance(AttendanceModel attendance) async {
    try {
      await _attendanceService.submitAttendance(attendance);
      // We could optionally update the state here, but for a StreamProvider
      // the UI will automatically update when the Firestore data changes
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> approveAttendance(String attendanceId) async {
    try {
      await _attendanceService.approveAttendance(attendanceId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  Future<void> rejectAttendance(String attendanceId, String comments) async {
    try {
      await _attendanceService.rejectAttendance(attendanceId, comments);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  Future<void> fetchPendingAttendanceForLecturer(String lecturerId) async {
    state = const AsyncValue.loading();
    try {
      final pendingAttendances = await _attendanceService.getPendingAttendanceForLecturer(lecturerId);
      state = AsyncValue.data(pendingAttendances);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  Future<void> fetchAttendanceForCourse(String courseId) async {
    state = const AsyncValue.loading();
    try {
      final courseAttendances = await _attendanceService.getAttendanceForCourse(courseId);
      state = AsyncValue.data(courseAttendances);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}