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

//   Future<void> updateAttendanceStatus(String attendanceId, String newStatus) async {
//   try {
//     await FirebaseFirestore.instance
//         .collection('attendances')
//         .doc(attendanceId)
//         .update({'status': newStatus});
//   } catch (e) {
//     throw Exception('Failed to update attendance status: $e');
//   }
// }
  
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
  
  Future<List<AttendanceModel>> getPendingAttendanceForLecturer(String lecturerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('attendances')
          .where('lecturerId', isEqualTo: lecturerId)
          .where('status', isEqualTo: AttendanceStatus.pending.toString().split('.').last)
          .get();
      
      return querySnapshot.docs
          .map((doc) => AttendanceModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  
  Future<List<AttendanceModel>> getAttendanceForCourse(String courseId) async {
    try {
      final querySnapshot = await _firestore
          .collection('attendances')
          .where('unitId', isEqualTo: courseId)
          .get();
      
      return querySnapshot.docs
          .map((doc) => AttendanceModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> updateAttendanceStatus(String attendanceId, String status) async {
    try {
      await _firestore.collection('attendances').doc(attendanceId).update({
        'status': status,
      });
    } catch (e) {
      rethrow;
    }
  }

  // New methods for attendance activation
  Future<void> activateAttendanceForUnit(String unitId) async {
    try {
      // First, update the unit record
      await _firestore.collection('units').doc(unitId).update({
        'isAttendanceActive': true,
      });
      
      // Then update any related attendance records if needed
      // This could be omitted if you're just checking the unit status
      QuerySnapshot attendances = await _firestore
          .collection('attendances')
          .where('unitId', isEqualTo: unitId)
          .get();
      
      WriteBatch batch = _firestore.batch();
      for (var doc in attendances.docs) {
        batch.update(doc.reference, {'isActive': true});
      }
      
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deactivateAttendanceForUnit(String unitId) async {
    try {
      // First, update the unit record
      await _firestore.collection('units').doc(unitId).update({
        'isAttendanceActive': false,
      });
      
      // Then update any related attendance records if needed
      QuerySnapshot attendances = await _firestore
          .collection('attendances')
          .where('unitId', isEqualTo: unitId)
          .get();
      
      WriteBatch batch = _firestore.batch();
      for (var doc in attendances.docs) {
        batch.update(doc.reference, {'isActive': false});
      }
      
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  // Method to get active attendance sessions
  Stream<List<AttendanceModel>> getActiveAttendance() {
    return _firestore
        .collection('attendances')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AttendanceModel.fromFirestore(doc))
              .toList(),
        );
  }
}