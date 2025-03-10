import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus {
  pending,
  approved,
  rejected
}

class AttendanceModel {
  final String id;
  final String unitId;
  final String unitName;
  final String studentId;
  final String studentName;
  final String courseName;
  final String lecturerId;
  final String venue;
  final Timestamp attendanceDate;
  final AttendanceStatus status;
  final String lecturerComments;
  final String studentComments;

  AttendanceModel({
    required this.id,
    required this.unitId,
    this.unitName = '',
    required this.studentId,
    required this.studentName,
    required this.courseName,
    required this.lecturerId,
    required this.venue,
    required this.attendanceDate,
    this.status = AttendanceStatus.pending,
    this.lecturerComments = '',
    this.studentComments = '',
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'courseName': courseName,
      'attendanceDate': attendanceDate,
      'status': status.toString(),
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


  AttendanceModel copyWith({
    String? id,
    String? unitId,
    String? unitName,
    String? studentId,
    String? studentName,
    String? courseName,
    String? lecturerId,
    String? venue,
    Timestamp? attendanceDate,
    AttendanceStatus? status,
    String? lecturerComments,
    String? studentComments,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      unitId: unitId ?? this.unitId,
      unitName: unitName ?? this.unitName,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      courseName: courseName ?? this.courseName,
      lecturerId: lecturerId ?? this.lecturerId,
      venue: venue ?? this.venue,
      attendanceDate: attendanceDate ?? this.attendanceDate,
      status: status ?? this.status,
      lecturerComments: lecturerComments ?? this.lecturerComments,
      studentComments: studentComments ?? this.studentComments,
    );
  }

  // Create AttendanceModel from a Map (used when fetching from Firestore)
  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    AttendanceStatus getStatus(String status) {
      switch (status) {
        case 'approved':
          return AttendanceStatus.approved;
        case 'rejected':
          return AttendanceStatus.rejected;
        case 'pending':
        default:
          return AttendanceStatus.pending;
      }
    }

    return AttendanceModel(
      id: map['id'] ?? '',
      unitId: map['unitId'] ?? '',
      unitName: map['unitName'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      courseName: map['courseName'] ?? '',
      lecturerId: map['lecturerId'] ?? '',
      venue: map['venue'] ?? '',
      attendanceDate: map['attendanceDate'] as Timestamp? ?? Timestamp.now(),
      status: getStatus(map['status'] ?? ''),
      lecturerComments: map['lecturerComments'] ?? '',
      studentComments: map['studentComments'] ?? '',
    );
  }


}