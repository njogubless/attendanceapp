// lib/Core/Config/providers.dart

// Repository provider
import 'package:attendanceapp/Features/Auth/Model/course_model.dart';
import 'package:attendanceapp/Features/Auth/Model/user_model.dart';
import 'package:attendanceapp/Features/Auth/repository/firebase_repositroy.dart';
import 'package:attendanceapp/Features/Unit/Model/attendance_model.dart';
import 'package:attendanceapp/Features/Unit/Model/course_registration_model.dart';
import 'package:attendanceapp/Features/Unit/Model/unit_model.dart';
import 'package:riverpod/riverpod.dart';

final firebaseRepositoryProvider = Provider<FirebaseRepository>((ref) {
  return FirebaseRepository();
});

// Auth providers
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final repository = ref.watch(firebaseRepositoryProvider);
  return await repository.getCurrentUser();
});

// Course providers
final lecturerCoursesProvider = FutureProvider.family<List<CourseModel>, String>((ref, lecturerId) async {
  final repository = ref.watch(firebaseRepositoryProvider);
  return await repository.getCoursesByLecturerId(lecturerId);
});

final courseProvider = FutureProvider.family<CourseModel?, String>((ref, courseId) async {
  final repository = ref.watch(firebaseRepositoryProvider);
  return await repository.getCourseById(courseId);
});

// Unit providers
final courseUnitsProvider = FutureProvider.family<List<UnitModel>, String>((ref, courseId) async {
  final repository = ref.watch(firebaseRepositoryProvider);
  return await repository.getUnitsByCourseId(courseId);
});

final unitProvider = FutureProvider.family<UnitModel?, String>((ref, unitId) async {
  final repository = ref.watch(firebaseRepositoryProvider);
  return await repository.getUnitById(unitId);
});

// Registration providers
final studentRegistrationsProvider = FutureProvider.family<List<CourseRegistrationModel>, String>((ref, studentId) async {
  final repository = ref.watch(firebaseRepositoryProvider);
  return await repository.getRegistrationsByStudentId(studentId);
});

final pendingRegistrationsProvider = FutureProvider.family<List<CourseRegistrationModel>, String>((ref, lecturerId) async {
  final repository = ref.watch(firebaseRepositoryProvider);
  return await repository.getPendingRegistrationsByLecturerId(lecturerId);
});

// Attendance providers
final unitAttendanceProvider = FutureProvider.family<List<AttendanceModel>, UnitAttendanceParams>((ref, params) async {
  final repository = ref.watch(firebaseRepositoryProvider);
  return await repository.getAttendanceByUnitId(params.unitId, date: params.date);
});

final studentAttendanceProvider = FutureProvider.family<List<AttendanceModel>, StudentAttendanceParams>((ref, params) async {
  final repository = ref.watch(firebaseRepositoryProvider);
  return await repository.getAttendanceByStudentId(params.studentId, courseId: params.courseId);
});

final attendanceReportProvider = FutureProvider.family<List<AttendanceModel>, AttendanceReportParams>((ref, params) async {
  final repository = ref.watch(firebaseRepositoryProvider);
  return await repository.getAttendanceReport(
    courseId: params.courseId,
    unitId: params.unitId,
    date: params.date,
  );
});

// Parameter classes for providers
class UnitAttendanceParams {
  final String unitId;
  final DateTime? date;

  UnitAttendanceParams({required this.unitId, this.date});
}

class StudentAttendanceParams {
  final String studentId;
  final String? courseId;

  StudentAttendanceParams({required this.studentId, this.courseId});
}

class AttendanceReportParams {
  final String? courseId;
  final String? unitId;
  final DateTime? date;

  AttendanceReportParams({this.courseId, this.unitId, this.date});
}