import 'package:attendanceapp/Models/attendance_model.dart';
import 'package:attendanceapp/services/attendance_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService();
});

final attendancesProvider = StreamProvider<List<AttendanceModel>>((ref) {
  return ref.read(attendanceServiceProvider).getAttendances();
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
}