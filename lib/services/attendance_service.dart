// lib/services/attendance_service.dart
import 'package:attendanceapp/Models/attendance_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<AttendanceModel>> getAttendances() {
    return _firestore.collection('attendances').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => AttendanceModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> submitAttendance(AttendanceModel attendance) async {
    try {
      await _firestore.collection('attendances').add(attendance.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> approveAttendance(String attendanceId) async {
    try {
      await _firestore.collection('attendances').doc(attendanceId).update({
        'status': AttendanceStatus.approved.toString().split('.').last,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rejectAttendance(String attendanceId, String comments) async {
    try {
      await _firestore.collection('attendances').doc(attendanceId).update({
        'status': AttendanceStatus.rejected.toString().split('.').last,
        'lecturerComments': comments,
      });
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<AttendanceModel>> getAttendanceByStudent(String studentId) {
    return _firestore
        .collection('attendances')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AttendanceModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<AttendanceModel>> getAttendanceByLecturer(String lecturerId) {
    return _firestore
        .collection('attendances')
        .where('lecturerId', isEqualTo: lecturerId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AttendanceModel.fromFirestore(doc))
              .toList(),
        );
  }
}