import 'package:attendanceapp/Models/attendance_model.dart';
import 'package:attendanceapp/services/attendance_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService();
});

final attendancesProvider = StreamProvider<List<AttendanceModel>>((ref) {
  return ref.read(attendanceServiceProvider).getAttendances();
});

// New provider for pending attendance for lecturer
final pendingAttendanceForLecturerProvider = FutureProvider.family<List<AttendanceModel>, String>((ref, lecturerId) {
  return ref.read(attendanceServiceProvider).getPendingAttendanceForLecturer(lecturerId);
});

// New provider for attendance by course
final attendanceForCourseProvider = FutureProvider.family<List<AttendanceModel>, String>((ref, courseId) {
  return ref.read(attendanceServiceProvider).getAttendanceForCourse(courseId);
});

final attendanceNotifierProvider = StateNotifierProvider<AttendanceNotifier, AsyncValue<List<AttendanceModel>>>((ref) {
  return AttendanceNotifier(ref.read(attendanceServiceProvider));
});

class AttendanceNotifier extends StateNotifier<AsyncValue<List<AttendanceModel>>> {
  final AttendanceService _attendanceService;

  AttendanceNotifier(this._attendanceService) : super(AsyncValue.loading());

  Future<void> submitAttendance(AttendanceModel attendance) async {
    state = AsyncValue.loading();
    try {
      await _attendanceService.submitAttendance(attendance);
      final attendances = await _attendanceService.getAttendances().first;
      state = AsyncValue.data(attendances);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> approveAttendance(String attendanceId) async {
    state = AsyncValue.loading();
    try {
      await _attendanceService.approveAttendance(attendanceId);
      final attendances = await _attendanceService.getAttendances().first;
      state = AsyncValue.data(attendances);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  // Add methods to fetch pending attendance for lecturer
  Future<void> fetchPendingAttendanceForLecturer(String lecturerId) async {
    state = AsyncValue.loading();
    try {
      final pendingAttendances = await _attendanceService.getPendingAttendanceForLecturer(lecturerId);
      state = AsyncValue.data(pendingAttendances);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  // Add methods to fetch attendance for a specific course
  Future<void> fetchAttendanceForCourse(String courseId) async {
    state = AsyncValue.loading();
    try {
      final courseAttendances = await _attendanceService.getAttendanceForCourse(courseId);
      state = AsyncValue.data(courseAttendances);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}