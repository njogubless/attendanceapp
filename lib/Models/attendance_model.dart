import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus { pending, approved, rejected }

class AttendanceModel {
  final String id;
  final String unitId;
  final String unitName;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String courseName;
  final String lecturerId;
  final String venue;
  final Timestamp attendanceDate;
  final AttendanceStatus status;
  final String lecturerComments;
  final String studentComments;
  final bool isSubmitted; // Track if student has submitted attendance
  final String registrationNumber; // Added to store registration number

  AttendanceModel({
    required this.id,
    required this.unitId,
    this.unitName = '',
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.courseName,
    required this.lecturerId,
    required this.venue,
    required this.attendanceDate,
    this.status = AttendanceStatus.pending,
    this.lecturerComments = '',
    this.studentComments = '',
    this.isSubmitted = false,
    this.registrationNumber = '', // Default empty
  });

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AttendanceModel(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      studentEmail: data['studentEmail'] ?? '',
      unitId: data['unitId'] ?? '',
      unitName: data['unitName'] ?? '',
      courseName: data['courseName'] ?? '',
      lecturerId: data['lecturerId'] ?? '',
      venue: data['venue'] ?? '',
      attendanceDate: data['attendanceDate'] ?? Timestamp.now(),
      status: AttendanceStatus.values.firstWhere(
        (e) =>
            e.toString() == 'AttendanceStatus.${data['status'] ?? 'pending'}',
        orElse: () => AttendanceStatus.pending,
      ),
      lecturerComments: data['lecturerComments'] ?? '',
      studentComments: data['studentComments'] ?? '',
      isSubmitted: data['isSubmitted'] ?? false,
      registrationNumber: data['registrationNumber'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'unitId': unitId,
      'unitName': unitName,
      'courseName': courseName,
      'lecturerId': lecturerId,
      'venue': venue,
      'attendanceDate': attendanceDate,
      'status': status.toString().split('.').last,
      'lecturerComments': lecturerComments,
      'studentComments': studentComments,
      'isSubmitted': isSubmitted,
      'registrationNumber': registrationNumber,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'courseName': courseName,
      'attendanceDate': attendanceDate,
      'status': status.toString(),
      'lecturerComments': lecturerComments,
      'registrationNumber': registrationNumber,
    };
  }

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
    String? studentEmail,
    String? courseName,
    String? lecturerId,
    String? venue,
    Timestamp? attendanceDate,
    AttendanceStatus? status,
    String? lecturerComments,
    String? studentComments,
    bool? isSubmitted,
    String? registrationNumber,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      unitId: unitId ?? this.unitId,
      unitName: unitName ?? this.unitName,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail, 
      courseName: courseName ?? this.courseName,
      lecturerId: lecturerId ?? this.lecturerId,
      venue: venue ?? this.venue,
      attendanceDate: attendanceDate ?? this.attendanceDate,
      status: status ?? this.status,
      lecturerComments: lecturerComments ?? this.lecturerComments,
      studentComments: studentComments ?? this.studentComments,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      registrationNumber: registrationNumber ?? this.registrationNumber,
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
      studentEmail: map['studentEmail'] ?? '',
      courseName: map['courseName'] ?? '',
      lecturerId: map['lecturerId'] ?? '',
      venue: map['venue'] ?? '',
      attendanceDate: map['attendanceDate'] as Timestamp? ?? Timestamp.now(),
      status: getStatus(map['status'] ?? ''),
      lecturerComments: map['lecturerComments'] ?? '',
      studentComments: map['studentComments'] ?? '',
      isSubmitted: map['isSubmitted'] ?? false,
      registrationNumber: map['registrationNumber'] ?? '',
    );
  }
}