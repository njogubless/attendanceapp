import 'package:cloud_firestore/cloud_firestore.dart';

enum UnitStatus { pending, approved, rejected }

class UnitModel {
  final String id;
  final String name;
  final String code;
  final String lecturerId;
  final String lecturerName;
  final String description;
  final UnitStatus status;
  final bool isAttendanceActive;
  final String adminComments;
  final Timestamp createdAt;
  final String courseId;

  UnitModel({
    required this.id,
    required this.name,
    required this.code,
    required this.lecturerId,
    required this.lecturerName,
    required this.courseId,
    this.description = '',
    this.status = UnitStatus.pending,
    this.isAttendanceActive = false,
    this.adminComments = '',
    Timestamp? createdAt,
  }) : createdAt = createdAt ?? Timestamp.now();

  factory UnitModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UnitModel(
      id: doc.id,
      name: data['name'] ?? '',
      code: data['code'] ?? '',
      lecturerId: data['lecturerId'] ?? '',
      lecturerName: data['lecturerName'] ?? '',
      courseId: data['courseId'] ?? '',
     
      description: data['description'] ?? '',
      status: UnitStatus.values.firstWhere(
        (e) => e.toString() == 'UnitStatus.${data['status'] ?? 'pending'}',
        orElse: () => UnitStatus.pending,
      ),
      isAttendanceActive: data['isAttendanceActive'] ?? false,
      adminComments: data['adminComments'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'code': code,
      'lecturerId': lecturerId,
      'lecturerName': lecturerName,
      'description': description,
      'status': status.toString().split('.').last,
      'isAttendanceActive': isAttendanceActive,
      'adminComments': adminComments,
      'createdAt': createdAt,
      'courseId': courseId,
    };
  }

  UnitModel copyWith({
    String? id,
    String? name,
    String? code,
    String? lecturerId,
    String? lecturerName,
    String? description,
    UnitStatus? status,
    bool? isAttendanceActive,
    String? adminComments,
    Timestamp? createdAt,
    String? courseId,
  }) {
    return UnitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      lecturerId: lecturerId ?? this.lecturerId,
      lecturerName: lecturerName ?? this.lecturerName,
      description: description ?? this.description,
      status: status ?? this.status,
      isAttendanceActive: isAttendanceActive ?? this.isAttendanceActive,
      adminComments: adminComments ?? this.adminComments,
      createdAt: createdAt ?? this.createdAt,
      courseId: courseId ?? this.courseId,
    );
  }

  // In your UnitModel class
factory UnitModel.fromMap(String id, Map<String, dynamic> map) {
  return UnitModel(
    id: id,
    name: map['name'] ?? '',
    code: map['code'] ?? '',
    lecturerId: map['lecturerId'] ?? '',
    lecturerName: map['lecturerName'] ?? '',
    courseId: map['courseId'] ?? '',
    description: map['description'] ?? '',
    status: UnitStatus.values.firstWhere(
      (e) => e.toString() == 'UnitStatus.${map['status'] ?? 'pending'}',
      orElse: () => UnitStatus.pending,
    ),
    isAttendanceActive: map['isAttendanceActive'] ?? false,
    adminComments: map['adminComments'] ?? '',
    createdAt: map['createdAt'] ?? Timestamp.now(),
  );
}
}
