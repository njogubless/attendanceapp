import 'package:cloud_firestore/cloud_firestore.dart';

class CourseModel {
  final String id;
  final String name;
  final String lecturerId;
  final List<String> units;
  final List<String> enrolledStudents;
  final Timestamp? createdAt;

  CourseModel({
    required this.id,
    required this.name,
    required this.lecturerId,
    this.units = const [],
    this.enrolledStudents = const [],
    this.createdAt,
  });

  factory CourseModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CourseModel(
      id: doc.id,
      name: data['name'] ?? '',
      lecturerId: data['lecturerId'] ?? '',
      units: List<String>.from(data['units'] ?? []),
      enrolledStudents: List<String>.from(data['enrolledStudents'] ?? []),
      createdAt: data['createdAt'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'lecturerId': lecturerId,
      'units': units,
      'enrolledStudents': enrolledStudents,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}