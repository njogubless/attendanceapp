import 'package:cloud_firestore/cloud_firestore.dart';

class UnitModel {
  final String id;
  final String name;
  final String courseId;
  final String lecturerId;
  final List<String> enrolledStudents;
  final Timestamp? createdAt;

  UnitModel({
    required this.id,
    required this.name,
    required this.courseId,
    required this.lecturerId,
    this.enrolledStudents = const [],
    this.createdAt,
  });

  factory UnitModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UnitModel(
      id: doc.id,
      name: data['name'] ?? '',
      courseId: data['courseId'] ?? '',
      lecturerId: data['lecturerId'] ?? '',
      enrolledStudents: List<String>.from(data['enrolledStudents'] ?? []),
      createdAt: data['createdAt'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'courseId': courseId,
      'lecturerId': lecturerId,
      'enrolledStudents': enrolledStudents,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}