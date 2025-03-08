import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus {
  pending,
  approved,
  rejected
}

class AttendanceModel {
  final String id;
  final String studentId;
  final String studentName; // Added field
  final String unitId;
  final String courseName; // Added field
  final String lecturerId;
  final String venue;
  final Timestamp attendanceDate;
  final AttendanceStatus status;
  final String? lecturerComments;

  AttendanceModel({
    required this.id,
    required this.studentId,
    required this.studentName, // Added to constructor
    required this.unitId,
    required this.courseName, // Added to constructor
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
      studentName: data['studentName'] ?? '', // Added field extraction
      unitId: data['unitId'] ?? '',
      courseName: data['courseName'] ?? '', // Added field extraction
      lecturerId: data['lecturerId'] ?? '',
      venue: data['venue'] ?? '',
      attendanceDate: data['attendanceDate'] ?? Timestamp.now(),
      status: AttendanceStatus.values.firstWhere(
        (e) => e.toString() == 'AttendanceStatus.${data['status'] ?? 'pending'}',
        orElse: () => AttendanceStatus.pending,
      ),
      lecturerComments: data['lecturerComments'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'studentName': studentName, // Added to map
      'unitId': unitId,
      'courseName': courseName, // Added to map
      'lecturerId': lecturerId,
      'venue': venue,
      'attendanceDate': attendanceDate,
      'status': status.toString().split('.').last,
      'lecturerComments': lecturerComments,
    };
  }

  // Fix the date getter issue - add this getter
  DateTime get date {
    return attendanceDate.toDate();
  }

  bool get approved {
    return status == AttendanceStatus.approved;
  }

  DateTime get timestamp {
    return attendanceDate.toDate();
  }
}