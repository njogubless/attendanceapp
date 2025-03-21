import 'package:attendanceapp/Models/attendance_model.dart';
import 'package:attendanceapp/Models/unit_model.dart';
import 'package:attendanceapp/services/attendance_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Unit provider (usually in unit_providers.dart but referenced here)
final unitProvider = StreamProvider.family<UnitModel, String>((ref, unitId) {
  return FirebaseFirestore.instance
      .collection('units')
      .doc(unitId)
      .snapshots()
      .map((snapshot) => UnitModel.fromFirestore(snapshot));
});

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

// Provider for attendance by unit/course
final attendanceForCourseProvider = FutureProvider.family<List<AttendanceModel>, String>((ref, unitId) {
  return ref.read(attendanceServiceProvider).getAttendanceForCourse(unitId);
});

// Provider for student attendances
final studentAttendancesProvider = StreamProvider.family<List<AttendanceModel>, String>((ref, studentId) {
  return ref.read(attendanceServiceProvider).getAttendanceByStudent(studentId);
});

// Provider for active attendance sessions (useful for students)
final activeAttendanceProvider = StreamProvider<List<AttendanceModel>>((ref) {
  return ref.read(attendanceServiceProvider).getActiveAttendance();
});

final isUnitAttendanceActiveProvider = Provider.family<bool, String>((ref, unitId) {
  final activeAttendanceAsync = ref.watch(activeAttendanceProvider);
  
  return activeAttendanceAsync.when(
    data: (activeAttendanceSessions) {
      // Check if there's any active attendance session for this specific unit
      return activeAttendanceSessions.any((attendance) => attendance.courseName == unitId);
    },
    loading: () => false, // Default to false while loading
    error: (_, __) => false, // Default to false on error
  );
});



 // Provider to track active attendance units
final activeAttendanceUnitsProvider = StreamProvider<List<String>>((ref) {
  final attendanceService = ref.read(attendanceServiceProvider);
  return attendanceService.getActiveAttendanceUnits();
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

  Future<void> updateAttendanceStatus(String attendanceId, String newStatus) async {
  try {
    await _attendanceService.updateAttendanceStatus(attendanceId, newStatus);
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
  
  Future<void> fetchAttendanceForCourse(String unitId) async {
    state = const AsyncValue.loading();
    try {
      final unitAttendances = await _attendanceService.getAttendanceForCourse(unitId);
      state = AsyncValue.data(unitAttendances);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // New methods for attendance activation
  Future<void> activateAttendanceForUnit(String unitId) async {
    try {
      await _attendanceService.activateAttendanceForUnit(unitId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deactivateAttendanceForUnit(String unitId) async {
    try {
      await _attendanceService.deactivateAttendanceForUnit(unitId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

 

// Provider to check if a specific unit has active attendance
final isUnitAttendanceActiveProvider = Provider.family<bool, String>((ref, unitId) {
  final activeUnitsAsyncValue = ref.watch(activeAttendanceUnitsProvider);
  
  return activeUnitsAsyncValue.when(
    data: (activeUnits) => activeUnits.contains(unitId),
    loading: () => false,
    error: (_, __) => false,
  );
});
}