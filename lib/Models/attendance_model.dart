import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus {
  pending,
  approved,
  rejected
}

class AttendanceModel {
  final String id;
  final String studentId;
  final String unitId;
  final String lecturerId;
  final String venue;
  final Timestamp attendanceDate;
  final AttendanceStatus status;
  final String? lecturerComments;

  AttendanceModel({
    required this.id,
    required this.studentId,
    required this.unitId,
    required this.lecturerId,
    required this.venue,
    required this.attendanceDate,
    this.status = AttendanceStatus.pending,
    this.lecturerComments,
  });

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AttendanceModel(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      unitId: data['unitId'] ?? '',
      lecturerId: data['lecturerId'] ?? '',
      venue: data['venue'] ?? '',
      attendanceDate: data['attendanceDate'] ?? Timestamp.now(),
      status: AttendanceStatus.values.firstWhere(
        (e) => e.toString() == 'AttendanceStatus.${data['status'] ?? 'pending'}',
      ),
      lecturerComments: data['lecturerComments'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'unitId': unitId,
      'lecturerId': lecturerId,
      'venue': venue,
      'attendanceDate': attendanceDate,
      'status': status.toString().split('.').last,
      'lecturerComments': lecturerComments,
    };
  }
}